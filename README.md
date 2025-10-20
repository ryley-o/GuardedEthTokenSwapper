# GuardedEthTokenSwapper

[![CI](https://github.com/ryley-o/GuardedEthTokenSwapper/actions/workflows/test.yml/badge.svg)](https://github.com/ryley-o/GuardedEthTokenSwapper/actions/workflows/test.yml)

A secure, gas-optimized smart contract for swapping ETH to ERC20 tokens using Chainlink price feeds and Uniswap V3.

## Overview

GuardedEthTokenSwapper is an ETH-only token swapper that protects against sandwich attacks by using Chainlink oracles to verify fair pricing. It's optimized for ETH pairs only, removing USD complexity and reducing gas costs.

**⚠️ USE AT YOUR OWN RISK. DO NOT USE THIS CONTRACT IF YOU DO NOT UNDERSTAND THE RISKS.**

## 🌐 Mainnet Deployment

**The contract is deployed and production-ready on Ethereum mainnet:**

- **Contract Address:** [`0x96E6a25565E998C6EcB98a59CC87F7Fc5Ed4D7b0`](https://etherscan.io/address/0x96E6a25565E998C6EcB98a59CC87F7Fc5Ed4D7b0)
- **Network:** Ethereum Mainnet (Chain ID: 1)
- **Status:** ✅ Verified source code on Etherscan
- **Tokens:** 14 pre-configured with optimal fee tiers
- **Testing:** Continuous mainnet integration testing via CI

**View on Etherscan:** [Contract Source & Interactions](https://etherscan.io/address/0x96E6a25565E998C6EcB98a59CC87F7Fc5Ed4D7b0#code)

## Features

- **ETH-Only Focus**: Simplified design using only TOKEN/ETH Chainlink price feeds
- **Sandwich Attack Protection**: Uses Chainlink oracles to verify fair pricing
- **Gas Optimized**: Streamlined for ETH pairs, reducing complexity and gas costs
- **Configurable Slippage**: Admin-configurable slippage tolerance per token
- **Multiple Fee Tiers**: Supports Uniswap V3 fee tiers (0.05%, 0.30%, 1.00%)
- **Security Features**: 
  - OpenZeppelin's `ReentrancyGuard` and `Ownable`
  - Oracle staleness checks (24-hour maximum)
  - SafeTransfer for ERC20 compatibility

## Supported Tokens

The contract supports 14 production-ready ETH pairs with 5% oracle validation tolerance:

- **DeFi Tokens**: 1INCH, AAVE, COMP, CRV, LDO, LINK, MKR, UNI
- **Major Assets**: WBTC (Bitcoin), SHIB (Meme)
- **Stablecoin**: USDT
- **Other**: APE, BAT, ZRX

All tokens use verified Chainlink TOKEN/ETH price feeds and optimal Uniswap V3 fee tiers, tested at block 23620206. WBTC uses the ETH/BTC feed for optimal precision.

## Architecture

```
ETH Input → Chainlink Price Check → Uniswap V3 Swap → Token Output
```

1. **Price Verification**: Fetches TOKEN/ETH price from Chainlink
2. **Expected Calculation**: Calculates expected tokens based on oracle price
3. **Slippage Check**: Ensures minimum output meets slippage tolerance
4. **Uniswap Swap**: Executes swap via Uniswap V3 with appropriate fee tier
5. **Transfer**: Safely transfers tokens to user

## Usage

### Setup

**1. Install Foundry:**

This project uses Foundry v1.4.2 for consistency. Install it with:

```shell
foundryup --version v1.4.2
```

Or use the helper script:
```shell
./setup-foundry.sh
```

**2. Install the pre-commit hook:**

```shell
./install-hooks.sh
```

This will automatically format Solidity files before each commit.

### Build
```shell
forge build
```

### Test
```shell
# Quick tests (no fork required)
./test_quick.sh

# Validated fork testing - Uses block 23620206 (KNOWN to work)
./test_fork.sh

# Latest fork testing - Uses current mainnet block
./test_fork_latest.sh

# Mainnet integration testing - Tests the DEPLOYED contract
./test_mainnet.sh
```

**Four testing modes:**
1. `./test_quick.sh` - Fast development testing (no fork, no RPC needed)
2. `./test_fork.sh` - Validation against known-good state (block 23620206)
3. `./test_fork_latest.sh` - Test current mainnet compatibility
4. `./test_mainnet.sh` ⭐ - **Test the deployed contract at `0x96E6a25565E998C6EcB98a59CC87F7Fc5Ed4D7b0`**

**Mainnet Integration Tests:**
The mainnet integration tests validate the actual deployed contract:
- ✅ Verifies all 14 tokens are properly configured
- ✅ Tests Chainlink oracle feeds on live mainnet
- ✅ Executes real swaps against the deployed contract
- ✅ Runs automatically in CI on the `main` branch

### Deploy

**✅ The contract is already deployed to mainnet at [`0x96E6a25565E998C6EcB98a59CC87F7Fc5Ed4D7b0`](https://etherscan.io/address/0x96E6a25565E998C6EcB98a59CC87F7Fc5Ed4D7b0).**

For deploying your own instance, see [DEPLOYMENT.md](DEPLOYMENT.md) for the comprehensive guide.

Quick start for custom deployment:

```bash
# 1. Configure environment variables
cp .env.example .env
# Edit .env with your values

# 2. Deploy
./deploy.sh

# 3. Verify (if not auto-verified)
./verify.sh <CONTRACT_ADDRESS>
```

The deployment script will:
- Deploy the GuardedEthTokenSwapper contract
- Configure all 14 production-ready token pairs
- Automatically verify on Etherscan (if API key provided)

**Note:** The main deployment is production-ready with all 14 tokens configured.

## Configuration

The contract requires admin configuration of supported tokens:

```solidity
function setFeeds(
    address[] calldata tokens,
    address[] calldata aggregators, 
    uint24[] calldata feeTiers,
    uint256[] calldata toleranceBps
) external onlyOwner
```

See `test/GuardedEthTokenSwapper.t.sol` for complete configuration examples.

## Security Considerations

- **Oracle Dependency**: Relies on Chainlink price feeds for security
- **Slippage Protection**: Configurable per-token slippage tolerance
- **Staleness Checks**: Rejects oracle data older than 24 hours
- **Admin Controls**: Owner can add/remove token configurations
- **Reentrancy Protection**: Uses OpenZeppelin's ReentrancyGuard

## Testing

Comprehensive test suite includes:
- Fork testing against mainnet at block 23620206 (optimized for all 14 tokens)
- Oracle price validation with 5% tolerance for all 14 tokens
- Real-world liquidity validation with 3% slippage tolerance
- Slippage validation, deadline checks, admin functions
- Gas efficiency and security tests

See `TEST_README.md` for detailed testing instructions.

## License

MIT License - see LICENSE file for details.

## Disclaimer

**⚠️ THIS CONTRACT HAS NOT BEEN PROFESSIONALLY AUDITED.**

This contract is provided as-is and has been tested via the comprehensive test suite documented in this repository. However, it has NOT undergone a professional security audit. 

**Use at your own risk and only with funds you can afford to lose.**

See `TEST_README.md` for details on the testing methodology and coverage.