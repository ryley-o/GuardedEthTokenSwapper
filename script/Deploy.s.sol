// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {GuardedEthTokenSwapper} from "../src/GuardedEthTokenSwapper.sol";

/**
 * @title Deploy Script for GuardedEthTokenSwapper
 * @notice Deploys the contract and configures all 14 production-ready token pairs
 *
 * Usage:
 *   forge script script/Deploy.s.sol:Deploy --rpc-url $ETH_RPC_URL --broadcast --verify
 *
 * Or with explicit parameters:
 *   forge script script/Deploy.s.sol:Deploy \
 *     --rpc-url $ETH_RPC_URL \
 *     --private-key $PRIVATE_KEY \
 *     --etherscan-api-key $ETHERSCAN_API_KEY \
 *     --broadcast \
 *     --verify
 *
 * Dry run (no broadcast):
 *   forge script script/Deploy.s.sol:Deploy --rpc-url $ETH_RPC_URL
 */
contract Deploy is Script {
    // Production token addresses (Ethereum Mainnet)
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

    // Configuration structure
    struct TokenConfig {
        address token;
        address chainlinkFeed;
        uint24 feeTier;
        uint16 toleranceBps;
        string symbol;
    }

    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("===========================================");
        console.log("GuardedEthTokenSwapper Deployment");
        console.log("===========================================");
        console.log("Deployer address:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Block number:", block.number);
        console.log("");

        // Require mainnet deployment
        require(block.chainid == 1, "This script is for mainnet deployment only");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the contract
        console.log("Step 1: Deploying GuardedEthTokenSwapper...");
        GuardedEthTokenSwapper swapper = new GuardedEthTokenSwapper();
        console.log("Contract deployed at:", address(swapper));
        console.log("");

        // 2. Prepare all token configurations
        console.log("Step 2: Preparing token configurations...");
        TokenConfig[] memory configs = _getTokenConfigs();

        address[] memory tokens = new address[](14);
        address[] memory aggregators = new address[](14);
        uint24[] memory feeTiers = new uint24[](14);
        uint16[] memory toleranceBpsArr = new uint16[](14);

        for (uint256 i = 0; i < configs.length; i++) {
            tokens[i] = configs[i].token;
            aggregators[i] = configs[i].chainlinkFeed;
            feeTiers[i] = configs[i].feeTier;
            toleranceBpsArr[i] = configs[i].toleranceBps;

            console.log("  [%s] %s", i + 1, configs[i].symbol);
            console.log("    Token:", configs[i].token);
            console.log("    Feed:", configs[i].chainlinkFeed);
            console.log("    Fee Tier: %s bps", configs[i].feeTier);
            console.log("    Tolerance: %s bps", configs[i].toleranceBps);
            console.log("");
        }

        // 3. Configure all feeds in a single transaction
        console.log("Step 3: Configuring all token feeds...");
        swapper.setFeeds(tokens, aggregators, feeTiers, toleranceBpsArr);
        console.log("All 14 token feeds configured successfully!");
        console.log("");

        // 4. Verify configuration
        console.log("Step 4: Verifying configuration...");
        for (uint256 i = 0; i < configs.length; i++) {
            (address agg,, uint24 fee, uint16 tol) = swapper.getFeed(configs[i].token);
            require(agg == configs[i].chainlinkFeed, "Feed mismatch");
            require(fee == configs[i].feeTier, "Fee tier mismatch");
            require(tol == configs[i].toleranceBps, "Tolerance mismatch");
            console.log("  \u2713 %s verified", configs[i].symbol);
        }
        console.log("");

        vm.stopBroadcast();

        // 5. Print deployment summary
        console.log("===========================================");
        console.log("DEPLOYMENT SUCCESSFUL");
        console.log("===========================================");
        console.log("Contract address:", address(swapper));
        console.log("Owner:", deployer);
        console.log("Tokens configured: 14");
        console.log("");
        console.log("Next steps:");
        console.log("1. Verify contract on Etherscan:");
        console.log("   forge verify-contract %s", address(swapper));
        console.log("   GuardedEthTokenSwapper --chain-id 1 --watch");
        console.log("");
        console.log("2. Or if using --verify flag, verification will happen automatically");
        console.log("");
        console.log("3. Test a swap (be careful with mainnet!):");
        console.log("   cast send %s \"swapEthForToken(address,uint16,uint256)\"", address(swapper));
        console.log("   <TOKEN_ADDRESS> 200 <DEADLINE> --value 0.1ether --private-key $PRIVATE_KEY");
        console.log("");
        console.log("Contract is ready for use!");
        console.log("===========================================");
    }

    /**
     * @notice Returns all 14 production-ready token configurations
     * @dev These configurations are optimized for block 23620206 but should work on current mainnet
     */
    function _getTokenConfigs() internal pure returns (TokenConfig[] memory) {
        TokenConfig[] memory configs = new TokenConfig[](14);

        // Optimized Fee Tiers (1.00%)
        configs[0] = TokenConfig({
            token: INCH,
            chainlinkFeed: 0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8,
            feeTier: 10000,
            toleranceBps: 500,
            symbol: "1INCH"
        });

        configs[1] = TokenConfig({
            token: SHIB,
            chainlinkFeed: 0x8dD1CD88F43aF196ae478e91b9F5E4Ac69A97C61,
            feeTier: 10000,
            toleranceBps: 1000,
            symbol: "SHIB"
        });

        // Major DeFi Tokens (0.30%)
        configs[2] = TokenConfig({
            token: AAVE,
            chainlinkFeed: 0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012,
            feeTier: 3000,
            toleranceBps: 300,
            symbol: "AAVE"
        });

        configs[3] = TokenConfig({
            token: APE,
            chainlinkFeed: 0xc7de7f4d4C9c991fF62a07D18b3E31e349833A18,
            feeTier: 3000,
            toleranceBps: 800,
            symbol: "APE"
        });

        configs[4] = TokenConfig({
            token: BAT,
            chainlinkFeed: 0x0d16d4528239e9ee52fa531af613AcdB23D88c94,
            feeTier: 3000,
            toleranceBps: 600,
            symbol: "BAT"
        });

        configs[5] = TokenConfig({
            token: COMP,
            chainlinkFeed: 0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699,
            feeTier: 3000,
            toleranceBps: 400,
            symbol: "COMP"
        });

        configs[6] = TokenConfig({
            token: CRV,
            chainlinkFeed: 0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e,
            feeTier: 3000,
            toleranceBps: 400,
            symbol: "CRV"
        });

        configs[7] = TokenConfig({
            token: LDO,
            chainlinkFeed: 0x4e844125952D32AcdF339BE976c98E22F6F318dB,
            feeTier: 3000,
            toleranceBps: 500,
            symbol: "LDO"
        });

        configs[8] = TokenConfig({
            token: LINK,
            chainlinkFeed: 0xDC530D9457755926550b59e8ECcdaE7624181557,
            feeTier: 3000,
            toleranceBps: 200,
            symbol: "LINK"
        });

        configs[9] = TokenConfig({
            token: MKR,
            chainlinkFeed: 0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2,
            feeTier: 3000,
            toleranceBps: 400,
            symbol: "MKR"
        });

        configs[10] = TokenConfig({
            token: UNI,
            chainlinkFeed: 0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e,
            feeTier: 3000,
            toleranceBps: 300,
            symbol: "UNI"
        });

        configs[11] = TokenConfig({
            token: ZRX,
            chainlinkFeed: 0x2Da4983a622a8498bb1a21FaE9D8F6C664939962,
            feeTier: 3000,
            toleranceBps: 600,
            symbol: "ZRX"
        });

        // Major Assets (0.05%)
        configs[12] = TokenConfig({
            token: USDT,
            chainlinkFeed: 0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46,
            feeTier: 500,
            toleranceBps: 200,
            symbol: "USDT"
        });

        configs[13] = TokenConfig({
            token: WBTC,
            chainlinkFeed: 0xAc559F25B1619171CbC396a50854A3240b6A4e99,
            feeTier: 500,
            toleranceBps: 500,
            symbol: "WBTC"
        });

        return configs;
    }
}
