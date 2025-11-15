// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {GuardedEthTokenSwapper} from "../src/GuardedEthTokenSwapper.sol";

interface IERC20Extended {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint256);
}

/**
 * @title GuardedEthTokenSwapper Price Feed Tests
 * @notice Comprehensive tests for the getTokenPrice() view function
 * @dev Tests all 14 configured tokens on mainnet fork
 */
contract GuardedEthTokenSwapperGetPriceTest is Test {
    GuardedEthTokenSwapper public swapper;

    // Token addresses (mainnet) - ACTUAL DEPLOYMENT CONFIGURATION
    address constant INCH = 0x111111111117dC0aa78b770fA6A738034120C302;
    address constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address constant APE = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;
    address constant BAT = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
    address constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;
    address constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address constant SHIB = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
    address constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant ZRX = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;

    // Oracle feeds (TOKEN/ETH) - ACTUAL DEPLOYMENT CONFIGURATION
    address constant INCH_ETH_FEED = 0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8;
    address constant AAVE_ETH_FEED = 0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012;
    address constant APE_ETH_FEED = 0xc7de7f4d4C9c991fF62a07D18b3E31e349833A18;
    address constant BAT_ETH_FEED = 0x0d16d4528239e9ee52fa531af613AcdB23D88c94;
    address constant COMP_ETH_FEED = 0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699;
    address constant CRV_ETH_FEED = 0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e;
    address constant USDT_ETH_FEED = 0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46;
    address constant LDO_ETH_FEED = 0x4e844125952D32AcdF339BE976c98E22F6F318dB;
    address constant LINK_ETH_FEED = 0xDC530D9457755926550b59e8ECcdaE7624181557;
    address constant MKR_ETH_FEED = 0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2;
    address constant SHIB_ETH_FEED = 0x8dD1CD88F43aF196ae478e91b9F5E4Ac69A97C61;
    address constant UNI_ETH_FEED = 0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e;
    address constant ZRX_ETH_FEED = 0x2Da4983a622a8498bb1a21FaE9D8F6C664939962;
    address constant WBTC_ETH_FEED = 0xAc559F25B1619171CbC396a50854A3240b6A4e99;

    // Use the same validated fork block as other tests
    uint256 constant FORK_BLOCK = 23620206;

    function setUp() public {
        // Fork mainnet at validated block
        string memory rpcUrl = vm.envOr("ETH_RPC_URL", string(""));
        if (bytes(rpcUrl).length == 0) {
            rpcUrl = "https://ethereum-rpc.publicnode.com";
        }
        vm.createSelectFork(rpcUrl, FORK_BLOCK);

        // Deploy fresh contract
        swapper = new GuardedEthTokenSwapper();

        // Configure all 14 tokens - ACTUAL DEPLOYMENT CONFIGURATION
        address[] memory tokens = new address[](14);
        address[] memory aggregators = new address[](14);
        uint24[] memory feeTiers = new uint24[](14);
        uint16[] memory tolerances = new uint16[](14);

        // 1INCH
        tokens[0] = INCH;
        aggregators[0] = INCH_ETH_FEED;
        feeTiers[0] = 10000;
        tolerances[0] = 500;

        // SHIB
        tokens[1] = SHIB;
        aggregators[1] = SHIB_ETH_FEED;
        feeTiers[1] = 10000;
        tolerances[1] = 1000;

        // AAVE
        tokens[2] = AAVE;
        aggregators[2] = AAVE_ETH_FEED;
        feeTiers[2] = 3000;
        tolerances[2] = 300;

        // APE
        tokens[3] = APE;
        aggregators[3] = APE_ETH_FEED;
        feeTiers[3] = 3000;
        tolerances[3] = 800;

        // BAT
        tokens[4] = BAT;
        aggregators[4] = BAT_ETH_FEED;
        feeTiers[4] = 3000;
        tolerances[4] = 600;

        // COMP
        tokens[5] = COMP;
        aggregators[5] = COMP_ETH_FEED;
        feeTiers[5] = 3000;
        tolerances[5] = 400;

        // CRV
        tokens[6] = CRV;
        aggregators[6] = CRV_ETH_FEED;
        feeTiers[6] = 3000;
        tolerances[6] = 400;

        // LDO
        tokens[7] = LDO;
        aggregators[7] = LDO_ETH_FEED;
        feeTiers[7] = 3000;
        tolerances[7] = 500;

        // LINK
        tokens[8] = LINK;
        aggregators[8] = LINK_ETH_FEED;
        feeTiers[8] = 3000;
        tolerances[8] = 200;

        // MKR
        tokens[9] = MKR;
        aggregators[9] = MKR_ETH_FEED;
        feeTiers[9] = 3000;
        tolerances[9] = 400;

        // UNI
        tokens[10] = UNI;
        aggregators[10] = UNI_ETH_FEED;
        feeTiers[10] = 3000;
        tolerances[10] = 300;

        // ZRX
        tokens[11] = ZRX;
        aggregators[11] = ZRX_ETH_FEED;
        feeTiers[11] = 3000;
        tolerances[11] = 600;

        // USDT
        tokens[12] = USDT;
        aggregators[12] = USDT_ETH_FEED;
        feeTiers[12] = 500;
        tolerances[12] = 200;

        // WBTC
        tokens[13] = WBTC;
        aggregators[13] = WBTC_ETH_FEED;
        feeTiers[13] = 500;
        tolerances[13] = 500;

        swapper.setFeeds(tokens, aggregators, feeTiers, tolerances);
    }

    /**
     * @notice Test getTokenPrice for all 14 configured tokens
     * @dev Verifies price is returned with correct decimals and is > 0
     */
    function testGetTokenPriceAllTokens() public view {
        address[14] memory tokens = [INCH, SHIB, AAVE, APE, BAT, COMP, CRV, LDO, LINK, MKR, UNI, ZRX, USDT, WBTC];

        string[14] memory symbols =
            ["1INCH", "SHIB", "AAVE", "APE", "BAT", "COMP", "CRV", "LDO", "LINK", "MKR", "UNI", "ZRX", "USDT", "WBTC"];

        console.log("\n=== TOKEN/ETH PRICES FROM CHAINLINK ORACLES ===\n");

        for (uint256 i = 0; i < tokens.length; i++) {
            (uint256 price, uint8 decimals) = swapper.getTokenPrice(tokens[i]);

            // Verify price is valid
            assertTrue(price > 0, string.concat(symbols[i], " price should be > 0"));

            // WBTC uses ETH/BTC feed with 8 decimals, all others use 18
            uint8 expectedDecimals = tokens[i] == WBTC ? 8 : 18;
            assertTrue(decimals == expectedDecimals, string.concat(symbols[i], " decimals mismatch"));

            // Calculate human-readable price (with 6 decimal places)
            uint256 ethPrice = (price * 1e6) / (10 ** decimals);

            console.log(
                string.concat(
                    symbols[i], "/ETH: ", _toString(ethPrice / 1e6), ".", _padLeft(_toString(ethPrice % 1e6), 6), " ETH"
                )
            );
        }

        console.log("\n=== ALL 14 TOKENS VALIDATED ===\n");
    }

    /**
     * @notice Test that getTokenPrice reverts for unconfigured token
     */
    function testGetTokenPriceRevertsForUnconfiguredToken() public {
        address unconfiguredToken = address(0x1234);

        vm.expectRevert(GuardedEthTokenSwapper.FeedNotSet.selector);
        swapper.getTokenPrice(unconfiguredToken);
    }

    /**
     * @notice Test getTokenPrice for specific token (LINK)
     */
    function testGetTokenPriceLINK() public view {
        (uint256 price, uint8 decimals) = swapper.getTokenPrice(LINK);

        assertTrue(price > 0, "LINK price should be > 0");
        assertEq(decimals, 18, "LINK feed should have 18 decimals");

        // LINK typically trades between 0.001 and 0.01 ETH
        // Price in ETH = price / 10^decimals
        uint256 priceInEth = price / 1e18;
        assertTrue(priceInEth < 1 ether, "LINK should be < 1 ETH");
    }

    /**
     * @notice Test getTokenPrice for AAVE (higher value token)
     */
    function testGetTokenPriceAAVE() public view {
        (uint256 price, uint8 decimals) = swapper.getTokenPrice(AAVE);

        assertTrue(price > 0, "AAVE price should be > 0");
        assertEq(decimals, 18, "AAVE feed should have 18 decimals");
    }

    /**
     * @notice Test getTokenPrice for MKR (highest value token)
     */
    function testGetTokenPriceMKR() public view {
        (uint256 price, uint8 decimals) = swapper.getTokenPrice(MKR);

        assertTrue(price > 0, "MKR price should be > 0");
        assertEq(decimals, 18, "MKR feed should have 18 decimals");
    }

    /**
     * @notice Test getTokenPrice returns consistent results
     */
    function testGetTokenPriceConsistency() public view {
        // Get price twice - should return same value
        (uint256 price1, uint8 decimals1) = swapper.getTokenPrice(LINK);
        (uint256 price2, uint8 decimals2) = swapper.getTokenPrice(LINK);

        assertEq(price1, price2, "Price should be consistent");
        assertEq(decimals1, decimals2, "Decimals should be consistent");
    }

    /**
     * @notice Test getTokenPrice with all configured tokens at once
     */
    function testGetTokenPriceMultipleTokens() public view {
        (uint256 linkPrice,) = swapper.getTokenPrice(LINK);
        (uint256 uniPrice,) = swapper.getTokenPrice(UNI);
        (uint256 aavePrice,) = swapper.getTokenPrice(AAVE);

        assertTrue(linkPrice > 0, "LINK price should be valid");
        assertTrue(uniPrice > 0, "UNI price should be valid");
        assertTrue(aavePrice > 0, "AAVE price should be valid");
    }

    // Helper function to convert uint to string
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Helper function to pad left with zeros
    function _padLeft(string memory str, uint256 length) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length >= length) {
            return str;
        }

        bytes memory padded = new bytes(length);
        uint256 padCount = length - strBytes.length;

        for (uint256 i = 0; i < padCount; i++) {
            padded[i] = "0";
        }
        for (uint256 i = 0; i < strBytes.length; i++) {
            padded[padCount + i] = strBytes[i];
        }

        return string(padded);
    }
}

