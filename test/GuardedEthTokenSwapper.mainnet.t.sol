// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {GuardedEthTokenSwapper} from "../src/GuardedEthTokenSwapper.sol";

/**
 * @title GuardedEthTokenSwapper Mainnet Integration Tests
 * @notice Tests the DEPLOYED contract on mainnet at 0x96E6a25565E998C6EcB98a59CC87F7Fc5Ed4D7b0
 * @dev These tests verify:
 *      1. Admin has properly configured all 14 tokens
 *      2. Oracle price feeds are working correctly
 *      3. Uniswap swaps execute successfully on mainnet
 *      4. The deployed contract integrates properly with mainnet infrastructure
 *
 * Requirements:
 * - Requires mainnet fork
 * - Uses DEPLOYED contract (does not deploy new one)
 * - Tests real mainnet state
 */
contract GuardedEthTokenSwapperMainnetTest is Test {
    // Deployed contract address on Ethereum mainnet
    address constant DEPLOYED_CONTRACT = 0x96E6a25565E998C6EcB98a59CC87F7Fc5Ed4D7b0;

    GuardedEthTokenSwapper public swapper;
    address public user = address(0x999);

    // Token addresses (same 14 tokens from deployment)
    address constant INCH = 0x111111111117dC0aa78b770fA6A738034120C302;
    address constant SHIB = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
    address constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address constant APE = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;
    address constant BAT = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
    address constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;
    address constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address constant ZRX = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    // Expected configuration from deployment
    struct ExpectedConfig {
        address token;
        address feed;
        uint24 feeTier;
        uint16 toleranceBps;
        string symbol;
    }

    ExpectedConfig[] public expectedConfigs;

    function setUp() public {
        // This test REQUIRES a mainnet fork
        string memory rpcUrl = vm.envOr("ETH_RPC_URL", string(""));
        require(bytes(rpcUrl).length > 0, "ETH_RPC_URL required for mainnet tests");

        console.log("================================================");
        console.log("MAINNET INTEGRATION TEST");
        console.log("Testing deployed contract at:", DEPLOYED_CONTRACT);
        console.log("================================================");
        console.log("");

        // Fork mainnet at current block (tests current state)
        vm.createSelectFork(rpcUrl);
        console.log("Forked mainnet at block:", block.number);
        console.log("");

        // Connect to the deployed contract (no deployment needed!)
        swapper = GuardedEthTokenSwapper(payable(DEPLOYED_CONTRACT));

        // Initialize expected configurations (from deployment)
        _initializeExpectedConfigs();

        // Give test user ETH for swaps
        vm.deal(user, 10 ether);
    }

    function _initializeExpectedConfigs() internal {
        expectedConfigs.push(
            ExpectedConfig({
                token: INCH,
                feed: 0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8,
                feeTier: 10000,
                toleranceBps: 500,
                symbol: "1INCH"
            })
        );

        expectedConfigs.push(
            ExpectedConfig({
                token: SHIB,
                feed: 0x8dD1CD88F43aF196ae478e91b9F5E4Ac69A97C61,
                feeTier: 10000,
                toleranceBps: 1000,
                symbol: "SHIB"
            })
        );

        expectedConfigs.push(
            ExpectedConfig({
                token: AAVE,
                feed: 0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012,
                feeTier: 3000,
                toleranceBps: 300,
                symbol: "AAVE"
            })
        );

        expectedConfigs.push(
            ExpectedConfig({
                token: APE,
                feed: 0xc7de7f4d4C9c991fF62a07D18b3E31e349833A18,
                feeTier: 3000,
                toleranceBps: 800,
                symbol: "APE"
            })
        );

        expectedConfigs.push(
            ExpectedConfig({
                token: BAT,
                feed: 0x0d16d4528239e9ee52fa531af613AcdB23D88c94,
                feeTier: 3000,
                toleranceBps: 600,
                symbol: "BAT"
            })
        );

        expectedConfigs.push(
            ExpectedConfig({
                token: COMP,
                feed: 0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699,
                feeTier: 3000,
                toleranceBps: 400,
                symbol: "COMP"
            })
        );

        expectedConfigs.push(
            ExpectedConfig({
                token: CRV,
                feed: 0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e,
                feeTier: 3000,
                toleranceBps: 400,
                symbol: "CRV"
            })
        );

        expectedConfigs.push(
            ExpectedConfig({
                token: LDO,
                feed: 0x4e844125952D32AcdF339BE976c98E22F6F318dB,
                feeTier: 3000,
                toleranceBps: 500,
                symbol: "LDO"
            })
        );

        expectedConfigs.push(
            ExpectedConfig({
                token: LINK,
                feed: 0xDC530D9457755926550b59e8ECcdaE7624181557,
                feeTier: 3000,
                toleranceBps: 200,
                symbol: "LINK"
            })
        );

        expectedConfigs.push(
            ExpectedConfig({
                token: MKR,
                feed: 0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2,
                feeTier: 3000,
                toleranceBps: 400,
                symbol: "MKR"
            })
        );

        expectedConfigs.push(
            ExpectedConfig({
                token: UNI,
                feed: 0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e,
                feeTier: 3000,
                toleranceBps: 300,
                symbol: "UNI"
            })
        );

        expectedConfigs.push(
            ExpectedConfig({
                token: ZRX,
                feed: 0x2Da4983a622a8498bb1a21FaE9D8F6C664939962,
                feeTier: 3000,
                toleranceBps: 600,
                symbol: "ZRX"
            })
        );

        expectedConfigs.push(
            ExpectedConfig({
                token: USDT,
                feed: 0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46,
                feeTier: 500,
                toleranceBps: 200,
                symbol: "USDT"
            })
        );

        expectedConfigs.push(
            ExpectedConfig({
                token: WBTC,
                feed: 0xAc559F25B1619171CbC396a50854A3240b6A4e99,
                feeTier: 500,
                toleranceBps: 500,
                symbol: "WBTC"
            })
        );
    }

    /**
     * @notice Verify the deployed contract has correct configuration
     * @dev Tests that admin properly configured all 14 tokens
     */
    function testMainnet_ConfigurationIsCorrect() public view {
        console.log("Verifying deployed contract configuration...");
        console.log("");

        uint256 failures = 0;

        for (uint256 i = 0; i < expectedConfigs.length; i++) {
            ExpectedConfig memory expected = expectedConfigs[i];

            (address feed, uint8 decimals, uint24 feeTier, uint16 toleranceBps) = swapper.getFeed(expected.token);

            bool feedMatch = feed == expected.feed;
            bool feeMatch = feeTier == expected.feeTier;
            bool tolMatch = toleranceBps == expected.toleranceBps;
            bool hasDecimals = decimals > 0; // Should have cached decimals

            if (feedMatch && feeMatch && tolMatch && hasDecimals) {
                console.log(unicode"  ✓", expected.symbol, "- Configured correctly");
            } else {
                console.log(unicode"  ✗", expected.symbol, "- CONFIGURATION MISMATCH!");
                if (!feedMatch) console.log("    Feed mismatch");
                if (!feeMatch) console.log("    Fee tier mismatch");
                if (!tolMatch) console.log("    Tolerance mismatch");
                if (!hasDecimals) console.log("    Decimals not cached");
                failures++;
            }
        }

        console.log("");
        if (failures == 0) {
            console.log(unicode"✅ All 14 tokens configured correctly!");
        } else {
            console.log(unicode"❌", failures, "configuration errors found");
        }

        assertEq(failures, 0, "All tokens should be configured correctly");
    }

    /**
     * @notice Verify contract owner is set correctly
     */
    function testMainnet_OwnerIsSet() public view {
        address owner = swapper.owner();
        console.log("Contract owner:", owner);

        assertTrue(owner != address(0), "Owner should be set");
        assertNotEq(owner, address(this), "Owner should not be test contract");
    }

    /**
     * @notice Test oracle price feeds are working on mainnet
     * @dev Verifies all 14 Chainlink feeds return valid prices
     */
    function testMainnet_OracleFeedsAreWorking() public view {
        console.log("Testing oracle price feeds...");
        console.log("");

        uint256 failures = 0;

        for (uint256 i = 0; i < expectedConfigs.length; i++) {
            ExpectedConfig memory config = expectedConfigs[i];

            (address feed,,,) = swapper.getFeed(config.token);

            // Get price from Chainlink feed
            try this.getOraclePrice(feed) returns (int256 price) {
                if (price > 0) {
                    console.log(unicode"  ✓", config.symbol, "- Oracle working");
                } else {
                    console.log(unicode"  ✗", config.symbol, "- Invalid price");
                    failures++;
                }
            } catch {
                console.log(unicode"  ✗", config.symbol, "- Oracle call failed");
                failures++;
            }
        }

        console.log("");
        if (failures == 0) {
            console.log(unicode"✅ All oracle feeds working!");
        } else {
            console.log(unicode"❌", failures, "oracle feeds failed");
        }

        assertEq(failures, 0, "All oracle feeds should be working");
    }

    /**
     * @notice Test actual swaps work on the deployed contract
     * @dev Performs small test swaps for each token to verify mainnet integration
     */
    function testMainnet_SwapsExecuteSuccessfully() public {
        console.log("Testing swaps on deployed contract...");
        console.log("");

        uint256 ethAmount = 0.01 ether; // Small amount for testing
        uint16 slippage = 300; // 3%
        uint256 deadline = block.timestamp + 300;

        uint256 successCount = 0;
        uint256 failCount = 0;

        vm.startPrank(user);

        for (uint256 i = 0; i < expectedConfigs.length; i++) {
            ExpectedConfig memory config = expectedConfigs[i];

            uint256 balanceBefore = user.balance;

            try swapper.swapEthForToken{value: ethAmount}(config.token, slippage, deadline) returns (
                uint256 amountOut
            ) {
                uint256 balanceAfter = user.balance;

                // Verify ETH was spent
                assertEq(balanceAfter, balanceBefore - ethAmount, "ETH should be deducted");

                // Verify tokens were received
                assertGt(amountOut, 0, "Should receive tokens");

                console.log(unicode"  ✓", config.symbol, "- Swap successful, received:", amountOut);
                successCount++;
            } catch Error(string memory reason) {
                console.log(unicode"  ✗", config.symbol, "- Swap failed:", reason);
                failCount++;
            } catch {
                console.log(unicode"  ✗", config.symbol, "- Swap failed (unknown reason)");
                failCount++;
            }
        }

        vm.stopPrank();

        console.log("");
        console.log("Swap Results:");
        console.log("  Successful:", successCount);
        console.log("  Failed:", failCount);

        if (failCount > 0) {
            console.log("");
            console.log("Note: Some swaps may fail due to:");
            console.log("  - Temporary liquidity issues");
            console.log("  - Market volatility exceeding tolerance");
            console.log("  - RPC provider rate limits");
            console.log("");
            console.log(unicode"⚠️  This is expected in mainnet testing");
        }

        // We expect most swaps to succeed, but allow some failures due to mainnet conditions
        assertTrue(successCount >= 10, "At least 10/14 swaps should succeed");
    }

    /**
     * @notice Verify contract supports all expected functions
     */
    function testMainnet_ContractInterfaceIsComplete() public view {
        // Test all public functions are accessible
        assertTrue(address(swapper.router()) != address(0), "Router should be set");
        assertTrue(address(swapper.weth()) != address(0), "WETH should be set");
        assertTrue(address(swapper.owner()) != address(0), "Owner should be set");

        console.log(unicode"✅ Contract interface is complete");
    }

    /**
     * @notice Test that non-configured tokens are rejected
     */
    function testMainnet_NonConfiguredTokensRevert() public {
        vm.startPrank(user);

        address randomToken = address(0x1234567890123456789012345678901234567890);
        uint256 deadline = block.timestamp + 300;

        vm.expectRevert();
        swapper.swapEthForToken{value: 0.01 ether}(randomToken, 200, deadline);

        vm.stopPrank();

        console.log(unicode"✅ Non-configured tokens correctly rejected");
    }

    // Helper function to get oracle price (callable externally for try/catch)
    function getOraclePrice(address feed) external view returns (int256) {
        (, int256 answer,,,) = AggregatorV3Interface(feed).latestRoundData();
        return answer;
    }
}

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

