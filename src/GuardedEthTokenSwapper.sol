// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Chainlink Aggregator ---
interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80);
    function decimals() external view returns (uint8);
}

// --- ERC20 / WETH / Uniswap v3 ---
interface IERC20 { function decimals() external view returns (uint8); function transfer(address,uint256) external returns (bool); }
interface IWETH9 { function deposit() external payable; function approve(address,uint256) external returns (bool); }
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn; address tokenOut; uint24 fee; address recipient;
        uint256 deadline; uint256 amountIn; uint256 amountOutMinimum; uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata) external payable returns (uint256 amountOut);
}

library SafeTransfer {
    function transfer(address token, address to, uint256 amount) internal returns (bool) {
        (bool ok, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        return ok && (data.length == 0 || abi.decode(data, (bool)));
    }
}

/**
    @title GuardedEthTokenSwapper
    @author ryley-o
    @notice This contract is a guarded eth token swapper that allows users to swap eth for tokens in
    uniswap v3 pools.
    USE AT YOUR OWN RISK. DO NOT USE THIS CONTRACT IF YOU DO NOT UNDERSTAND THE RISKS.
    It is guarded by checking the price of the token against a Chainlink oracle and ensuring the swap
    is within a certain tolerance. If the token price is not within the tolerance, the swap will revert.
    This is useful for users who want to swap eth for tokens but have no knowledge of the token price,
    and want to help guard against sever sandwich attacks or other forms of price manipulation.
    A curated list of tokens and their Chainlink oracles may be configured by the contract owner.
    THE OWNER OF THIS CONTRACT IS NOT LIABLE FOR ANY LOSS OF FUNDS OR DAMAGES ARISING FROM THE USE OF THIS CONTRACT.
 */
contract GuardedEthTokenSwapper is Ownable, ReentrancyGuard {
    using SafeTransfer for address;

    // Mainnet constants
    address public constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant WETH9_ADDR        = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    // Oracle staleness threshold (24 hours)
    uint256 public constant MAX_ORACLE_STALENESS = 24 hours;

    AggregatorV3Interface public immutable ethUsdFeed; // e.g. mainnet ETH/USD
    ISwapRouter public immutable router = ISwapRouter(UNISWAP_V3_ROUTER);
    IWETH9 public immutable weth   = IWETH9(WETH9_ADDR);

    enum QuoteType { USD, ETH } // TOKEN/USD or TOKEN/ETH

    /**
     * Packed per-token registry entry (single storage slot):
     * - aggregator      : 20 bytes
     * - quoteType       : 1 byte  (QuoteType)
     * - decimalsCache   : 1 byte  (aggregator.decimals())
     * - feeTier         : 3 bytes (Uniswap v3 fee: 500, 3000, 10000)
     * - toleranceBps    : 2 bytes (oracle ±accuracy in basis points, e.g. 200 = 2%)
     * Total: 27 bytes (fits in 1 slot)
     */
    struct FeedInfo {
        address aggregator;   // 20
        uint8   quoteType;    // 1
        uint8   decimalsCache;// 1
        uint24  feeTier;      // 3
        uint16  toleranceBps; // 2
        // 5 bytes padding
    }
    mapping(address => FeedInfo) public feeds; // token => config

    // Errors / events
    error NoEthSent();
    error FeedNotSet();
    error FeeNotSet();
    error OracleBad();
    error OracleStale();
    error ApproveFailed();
    error TransferFailed();

    event FeedSet(address indexed token, address indexed aggregator, QuoteType quote, uint8 decimals, uint24 feeTier, uint16 toleranceBps);
    event Swapped(address indexed user, address indexed token, uint256 ethIn, uint256 tokensOut, uint24 fee, uint256 minOut);

    constructor(address _ethUsdFeed) Ownable(msg.sender) {
        ethUsdFeed = AggregatorV3Interface(_ethUsdFeed);

        // Optional: a few defaults with toleranceBps (tune as you like)
        // _setFeed( // LINK/USD @ 0.30% fee, tolerance 50 bps
        //     0x514910771AF9Ca656af840dff83E8264EcF986CA,
        //     0x2c1d072e956aFfC0D435Cb7AC38EF18d24d9127c,
        //     QuoteType.USD, 3000, 50
        // );
    }

    // --- Admin: set/update entries (token, aggregator, quoteType, feeTier, toleranceBps) ---
    function setFeeds(
        address[] calldata tokens,
        address[] calldata aggregators,
        QuoteType[] calldata quotes,
        uint24[]  calldata feeTiers,
        uint16[]  calldata toleranceBpsArr
    ) external onlyOwner {
        uint256 n = tokens.length;
        require(n == aggregators.length && n == quotes.length && n == feeTiers.length && n == toleranceBpsArr.length, "len mismatch");
        for (uint256 i; i < n; ++i) {
            _setFeed(tokens[i], aggregators[i], quotes[i], feeTiers[i], toleranceBpsArr[i]);
        }
    }

    function _setFeed(address token, address aggregator, QuoteType quote, uint24 feeTier, uint16 toleranceBps) internal {
        require(token != address(0) && aggregator != address(0), "zero addr");
        require(feeTier == 500 || feeTier == 3000 || feeTier == 10000, "bad fee");
        // Simple sanity cap; keep combined buffers reasonable
        require(toleranceBps <= 2000, "tolerance too high"); // <=20%
        uint8 dec = AggregatorV3Interface(aggregator).decimals();
        feeds[token] = FeedInfo({
            aggregator: aggregator,
            quoteType:  uint8(quote),
            decimalsCache: dec,
            feeTier:    feeTier,
            toleranceBps: toleranceBps
        });
        emit FeedSet(token, aggregator, quote, dec, feeTier, toleranceBps);
    }

    // --- Atomic swap during mint ---
    /**
     * @param token          ERC20 to buy (must be in registry).
     * @param slippageBps    Runtime slippage buffer (e.g., 200 = 2%).
     * @return amountOut     Tokens transferred to msg.sender.
     */
    function swapEthForTokenWithRegistry(
        address token,
        uint16  slippageBps
    ) external payable nonReentrant returns (uint256 amountOut) {
        if (msg.value == 0) revert NoEthSent();

        FeedInfo memory f = feeds[token];
        if (f.aggregator == address(0)) revert FeedNotSet();
        if (f.feeTier == 0) revert FeeNotSet();

        // 1) Read prices with staleness check
        (, int256 tokAns,, uint256 tokUpdatedAt,) = AggregatorV3Interface(f.aggregator).latestRoundData();
        if (tokAns <= 0) revert OracleBad();
        if (block.timestamp - tokUpdatedAt > MAX_ORACLE_STALENESS) revert OracleStale();
        uint256 tokPrice = uint256(tokAns);

        uint256 ethUsd = 0;
        if (QuoteType(f.quoteType) == QuoteType.USD) {
            (, int256 eAns,, uint256 ethUpdatedAt,) = ethUsdFeed.latestRoundData();
            if (eAns <= 0) revert OracleBad();
            if (block.timestamp - ethUpdatedAt > MAX_ORACLE_STALENESS) revert OracleStale();
            ethUsd = uint256(eAns);
        }

        // 2) Compute expected tokens in token decimals
        uint8 tokenDec = IERC20(token).decimals();
        uint256 expectedTokens;

        if (QuoteType(f.quoteType) == QuoteType.USD) {
            uint8 ethDec = ethUsdFeed.decimals();
            uint256 ethUsd1e18 = ethUsd * 1e18 / (10 ** ethDec);
            uint256 tokUsd1e18 = tokPrice * 1e18 / (10 ** f.decimalsCache);
            uint256 tokensPerEth_tokenDec = (ethUsd1e18 * (10 ** tokenDec)) / tokUsd1e18;
            expectedTokens = (msg.value * tokensPerEth_tokenDec) / 1e18;
        } else {
            // TOKEN/ETH: tokenEth = tokPrice * 10^d (d = f.decimalsCache)
            // expected = msg.value * 10^(tokenDec + d) / (1e18 * tokenEth)
            uint256 num = msg.value * (10 ** (tokenDec + f.decimalsCache));
            expectedTokens = num / (1e18 * tokPrice);
        }

        // 3) Conservative minOut using both user slippage and feed tolerance
        uint256 totalBps = uint256(slippageBps) + uint256(f.toleranceBps);
        if (totalBps > 10_000) totalBps = 10_000; // clamp (won't underflow in next line)
        uint256 minOut = expectedTokens * (10_000 - totalBps) / 10_000;

        // 4) Wrap ETH, approve, swap (reverts if < minOut)
        weth.deposit{value: msg.value}();
        if (!weth.approve(UNISWAP_V3_ROUTER, msg.value)) revert ApproveFailed();

        ISwapRouter.ExactInputSingleParams memory p = ISwapRouter.ExactInputSingleParams({
            tokenIn:  WETH9_ADDR,
            tokenOut: token,
            fee:      f.feeTier,
            recipient: address(this),
            deadline: block.timestamp + 900,
            amountIn: msg.value,
            amountOutMinimum: minOut,
            sqrtPriceLimitX96: 0
        });
        amountOut = router.exactInputSingle(p);

        // 5) Send tokens to caller
        if (!SafeTransfer.transfer(token, msg.sender, amountOut)) revert TransferFailed();

        emit Swapped(msg.sender, token, msg.value, amountOut, f.feeTier, minOut);
    }

    // Views
    function getFeed(address token) external view returns (address aggregator, QuoteType quote, uint8 decimals, uint24 feeTier, uint16 toleranceBps) {
        FeedInfo memory x = feeds[token];
        return (x.aggregator, QuoteType(x.quoteType), x.decimalsCache, x.feeTier, x.toleranceBps);
    }

    receive() external payable { revert(); }
}