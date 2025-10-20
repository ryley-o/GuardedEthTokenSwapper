# GuardedEthTokenSwapper

A secure, gas-optimized smart contract for swapping ETH to ERC20 tokens using Chainlink price feeds and Uniswap V3.

## Overview

GuardedEthTokenSwapper is an ETH-only token swapper that protects against sandwich attacks by using Chainlink oracles to verify fair pricing. It's optimized for ETH pairs only, removing USD complexity and reducing gas costs.

**⚠️ USE AT YOUR OWN RISK. DO NOT USE THIS CONTRACT IF YOU DO NOT UNDERSTAND THE RISKS.**

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

### Build
```shell
forge build
```

### Test
```shell
# Quick tests (no fork required)
./test_quick.sh

# Comprehensive fork testing - CRITICAL: Uses block 23620206
./test_fork.sh

# Or set your own RPC URL
ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY" ./test_fork.sh

# Manual testing
forge test --fork-url https://ethereum-rpc.publicnode.com --fork-block-number 23620206
```

### Deploy
```shell
forge script script/Deploy.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
```

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
- All 14 supported tokens with 5% oracle validation tolerance
- Slippage validation, deadline checks, admin functions
- Gas efficiency and security tests

See `TEST_README.md` for detailed testing instructions.

## License

MIT License - see LICENSE file for details.

## Disclaimer

This contract is provided as-is for educational and experimental purposes. It has not been audited. Use at your own risk and only with funds you can afford to lose.