// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Chainlink Aggregator ---
interface AggregatorV3Interface {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
    function decimals() external view returns (uint8);
}

// --- ERC20 / WETH / Uniswap v3 ---
interface IERC20 {
    function decimals() external view returns (uint8);
    function transfer(address, uint256) external returns (bool);
}

interface IWETH9 {
    function deposit() external payable;
    function approve(address, uint256) external returns (bool);
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
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
 * @title GuardedEthTokenSwapper
 *     @author ryley-o
 *     @notice Simplified ETH-only token swapper that uses TOKEN/ETH Chainlink price feeds.
 *     This version is optimized for ETH pairs only, removing USD complexity and reducing gas costs.
 *
 *     ⚠️ USE AT YOUR OWN RISK. DO NOT USE THIS CONTRACT IF YOU DO NOT UNDERSTAND THE RISKS.
 *     ⚠️ THIS CONTRACT HAS NOT BEEN PROFESSIONALLY AUDITED.
 *     ⚠️ ONLY USE FUNDS YOU CAN AFFORD TO LOSE.
 *
 *     @dev It guards against severe sandwich attacks by checking TOKEN/ETH prices from Chainlink oracles.
 *     The contract validates swap outcomes against oracle prices with configurable tolerance per token.
 *     All supported tokens must be configured by the owner before swapping is enabled.
 */
contract GuardedEthTokenSwapper is Ownable, ReentrancyGuard {
    using SafeTransfer for address;

    // Mainnet constants
    address public constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant WETH9_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Oracle staleness threshold (24 hours)
    uint256 public constant MAX_ORACLE_STALENESS = 24 hours;

    ISwapRouter public immutable router = ISwapRouter(UNISWAP_V3_ROUTER);
    IWETH9 public immutable weth = IWETH9(WETH9_ADDR);

    /**
     * Simplified per-token registry entry (fits in 1 storage slot):
     * - aggregator      : 20 bytes (TOKEN/ETH Chainlink feed)
     * - decimalsCache   : 1 byte  (aggregator.decimals())
     * - feeTier         : 3 bytes (Uniswap v3 fee: 500, 3000, 10000)
     * - toleranceBps    : 2 bytes (oracle ±accuracy in basis points, e.g. 200 = 2%)
     * Total: 26 bytes (fits in 1 slot with 6 bytes padding)
     */
    struct FeedInfo {
        address aggregator; // 20 bytes - TOKEN/ETH price feed
        uint8 decimalsCache; // 1 byte  - cached decimals from aggregator
        uint24 feeTier; // 3 bytes - Uniswap V3 fee tier
        uint16 toleranceBps; // 2 bytes - price tolerance in basis points
            // 6 bytes padding
    }

    mapping(address => FeedInfo) public feeds; // token => config

    // Errors / events
    error NoEthSent();
    error FeedNotSet();
    error FeeNotSet();
    error OracleBad();
    error OracleStale();
    error InvalidSlippage();
    error ApproveFailed();
    error TransferFailed();

    event FeedSet(
        address indexed token, address indexed aggregator, uint8 decimals, uint24 feeTier, uint16 toleranceBps
    );
    event FeedRemoved(address indexed token);
    event Swapped(
        address indexed user,
        address indexed token,
        uint256 ethIn,
        uint256 tokensOut,
        uint24 fee,
        uint256 minOut,
        uint256 tokenEthPrice
    );

    /**
     * @notice Initializes the contract and sets the deployer as owner
     * @dev No ETH/USD feed needed - we only use TOKEN/ETH feeds
     */
    constructor() Ownable(msg.sender) {
        // Deployer becomes the owner via Ownable constructor
    }

    // --- Admin: set/update entries (token, aggregator, feeTier, toleranceBps) ---
    /**
     * @notice Configures price feeds and swap parameters for multiple tokens (owner only)
     * @dev All arrays must be the same length. Each token gets a dedicated Chainlink feed and Uniswap config.
     * @param tokens Array of ERC20 token addresses to configure
     * @param aggregators Array of Chainlink TOKEN/ETH price feed addresses
     * @param feeTiers Array of Uniswap V3 fee tiers (500=0.05%, 3000=0.30%, 10000=1.00%)
     * @param toleranceBpsArr Array of price tolerance values in basis points (e.g., 200=2%)
     * Requirements:
     * - All arrays must have matching length
     * - Token and aggregator addresses must be non-zero
     * - Fee tiers must be 500, 3000, or 10000
     * - Tolerance must be ≤ 2000 bps (20%)
     */
    function setFeeds(
        address[] calldata tokens,
        address[] calldata aggregators,
        uint24[] calldata feeTiers,
        uint16[] calldata toleranceBpsArr
    ) external onlyOwner {
        uint256 n = tokens.length;
        require(n == aggregators.length && n == feeTiers.length && n == toleranceBpsArr.length, "len mismatch");
        for (uint256 i; i < n; ++i) {
            _setFeed(tokens[i], aggregators[i], feeTiers[i], toleranceBpsArr[i]);
        }
    }

    function _setFeed(address token, address aggregator, uint24 feeTier, uint16 toleranceBps) internal {
        require(token != address(0) && aggregator != address(0), "zero addr");
        require(feeTier == 500 || feeTier == 3000 || feeTier == 10000, "bad fee");
        require(toleranceBps <= 2000, "tolerance too high"); // <=20%

        uint8 dec = AggregatorV3Interface(aggregator).decimals();
        feeds[token] =
            FeedInfo({aggregator: aggregator, decimalsCache: dec, feeTier: feeTier, toleranceBps: toleranceBps});
        emit FeedSet(token, aggregator, dec, feeTier, toleranceBps);
    }

    // --- Admin: remove feed ---
    /**
     * @notice Removes price feed configuration for a token (owner only)
     * @dev After removal, swaps for this token will revert with FeedNotSet error.
     * Use this to disable support for a token without redeploying the contract.
     * @param token The ERC20 token address to remove from supported tokens
     */
    function removeFeed(address token) external onlyOwner {
        require(feeds[token].aggregator != address(0), "feed not set");
        delete feeds[token];
        emit FeedRemoved(token);
    }

    // --- Simplified ETH-only swap ---
    /**
     * @param token          ERC20 to buy (must have TOKEN/ETH feed configured).
     * @param slippageBps    Runtime slippage buffer (e.g., 200 = 2%).
     * @param deadline       Unix timestamp after which the transaction will revert.
     * @return amountOut     Tokens transferred to msg.sender.
     */
    function swapEthForToken(address token, uint16 slippageBps, uint256 deadline)
        external
        payable
        nonReentrant
        returns (uint256 amountOut)
    {
        if (msg.value == 0) revert NoEthSent();
        if (slippageBps > 10000) revert InvalidSlippage(); // Max 100%
        if (deadline < block.timestamp) revert("deadline expired");

        FeedInfo memory f = feeds[token];
        if (f.aggregator == address(0)) revert FeedNotSet();
        if (f.feeTier == 0) revert FeeNotSet();

        // 1) Read TOKEN/ETH price with staleness check
        (, int256 tokEthAns,, uint256 tokUpdatedAt,) = AggregatorV3Interface(f.aggregator).latestRoundData();
        if (tokEthAns <= 0) revert OracleBad();
        if (block.timestamp - tokUpdatedAt > MAX_ORACLE_STALENESS) revert OracleStale();
        uint256 tokEthPrice = uint256(tokEthAns);

        // 2) Compute expected tokens - standard TOKEN/ETH calculation
        uint256 expectedTokens;
        {
            uint8 tokenDec = IERC20(token).decimals();
            // TOKEN/ETH price means: tokEthPrice * 10^decimalsCache = tokens per 1 ETH
            // For msg.value ETH: expectedTokens = msg.value * tokEthPrice * 10^tokenDec / (1e18 * 10^decimalsCache)

            // Use precision scaling to avoid early division
            uint256 scaledNumerator = msg.value * tokEthPrice * (10 ** tokenDec);
            expectedTokens = scaledNumerator / (1e18 * (10 ** f.decimalsCache));
        }

        // 3) Conservative minOut using both user slippage and feed tolerance
        uint256 totalBps = uint256(slippageBps) + uint256(f.toleranceBps);
        if (totalBps > 10_000) totalBps = 10_000; // clamp
        uint256 minOut = expectedTokens * (10_000 - totalBps) / 10_000;

        // 4) Wrap ETH, approve, swap
        weth.deposit{value: msg.value}();
        if (!weth.approve(UNISWAP_V3_ROUTER, msg.value)) revert ApproveFailed();

        ISwapRouter.ExactInputSingleParams memory p = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH9_ADDR,
            tokenOut: token,
            fee: f.feeTier,
            recipient: address(this),
            deadline: deadline,
            amountIn: msg.value,
            amountOutMinimum: minOut,
            sqrtPriceLimitX96: 0
        });
        amountOut = router.exactInputSingle(p);

        // 5) Send tokens to caller
        if (!SafeTransfer.transfer(token, msg.sender, amountOut)) revert TransferFailed();

        emit Swapped(msg.sender, token, msg.value, amountOut, f.feeTier, minOut, tokEthPrice);
    }

    // --- View functions ---
    /**
     * @notice Returns the configuration for a given token
     * @param token The ERC20 token address to query
     * @return aggregator The Chainlink price feed address (zero if not configured)
     * @return decimals The cached decimal count from the price feed
     * @return feeTier The Uniswap V3 fee tier to use for swaps
     * @return toleranceBps The price tolerance in basis points
     */
    function getFeed(address token)
        external
        view
        returns (address aggregator, uint8 decimals, uint24 feeTier, uint16 toleranceBps)
    {
        FeedInfo memory x = feeds[token];
        return (x.aggregator, x.decimalsCache, x.feeTier, x.toleranceBps);
    }

    receive() external payable {
        revert();
    }
}
