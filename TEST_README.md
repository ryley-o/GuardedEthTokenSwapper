# GuardedEthTokenSwapper Testing Guide

## Overview

This guide explains how to run comprehensive tests for the GuardedEthTokenSwapper contract (ETH-only version), including fork testing against mainnet Ethereum.

## Test Setup

### Prerequisites

1. **Foundry** - Make sure you have Foundry installed
2. **RPC Access** - For fork testing, you'll need access to an Ethereum mainnet RPC endpoint

### Environment Setup

For full fork testing capabilities, set up your RPC URL:

```bash
# Option 1: Use Alchemy (recommended)
export ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY"

# Option 2: Use Infura
export ETH_RPC_URL="https://mainnet.infura.io/v3/YOUR_PROJECT_ID"

# Option 3: Use any other mainnet RPC
export ETH_RPC_URL="your_rpc_endpoint_here"
```

## Running Tests

### Basic Tests (No Fork Required)

Run tests that don't require mainnet forking:

```bash
forge test -vv
```

These tests will verify:
- Contract deployment
- Admin functions (setFeeds, removeFeed)
- Input validation (slippage, deadline, zero ETH)
- Access control
- Event emissions

### Fork Tests (Full Integration)

Run comprehensive tests against mainnet fork:

```bash
# Set your RPC URL first
export ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY"

# Run all tests with fork
forge test -vv --fork-url $ETH_RPC_URL --fork-block-number 20935000
```

Or run specific fork tests:

```bash
# Test single token swap
forge test --match-test testSwapEthForToken --fork-url $ETH_RPC_URL --fork-block-number 20935000 -vv

# Test all 18 tokens (most comprehensive)
forge test --match-test testSwapMultipleEthPairs --fork-url $ETH_RPC_URL --fork-block-number 20935000 -vv

# Test specific contract only
forge test --match-contract GuardedEthTokenSwapperTest --fork-url $ETH_RPC_URL --fork-block-number 20935000 -v
```

## Test Coverage

### Configured Tokens

The test suite includes **18 high-quality ETH pairs** with verified Chainlink TOKEN/ETH feeds:

**Stablecoin (0.05% fee tier):**
- USDT - Tether USD (using direct USDT/ETH feed: `0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46`)

**Major DeFi Tokens (0.30% fee tier):**
- 1INCH - 1inch Network (`0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8`)
- AAVE - Aave Protocol (`0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012`)
- BAL - Balancer (`0xC1438AA3823A6Ba0C159CfA8D98dF5A994bA120b`)
- BAT - Basic Attention Token (`0x0d16d4528239e9ee52fa531af613AcdB23D88c94`)
- COMP - Compound (`0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699`)
- CRV - Curve DAO (`0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e`)
- LDO - Lido DAO (`0x4e844125952D32AcdF339BE976c98E22F6F318dB`)
- LINK - Chainlink (`0xDC530D9457755926550b59e8ECcdaE7624181557`)
- LRC - Loopring (`0x160AC928A16C93eD4895C2De6f81ECcE9a7eB7b4`)
- MKR - Maker (`0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2`)
- SUSHI - SushiSwap (`0xe572CeF69f43c2E488b33924AF04BDacE19079cf`)
- UNI - Uniswap (`0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e`)
- ZRX - 0x Protocol (`0x2Da4983a622a8498bb1a21FaE9D8F6C664939962`)

**Major Assets (0.30% fee tier):**
- WBTC - Wrapped Bitcoin (using ETH/BTC feed: `0xAc559F25B1619171CbC396a50854A3240b6A4e99`)

**Volatile Tokens (1.00% fee tier):**
- APE - ApeCoin (`0xc7de7f4d4C9c991fF62a07D18b3E31e349833A18`)
- FIL - Filecoin (`0x0606Be69451B1C9861Ac6b3626b99093b713E801`)
- SHIB - Shiba Inu (`0x8dD1CD88F43aF196ae478e91b9F5E4Ac69A97C61`)

### Test Cases

The test suite includes **9 comprehensive test cases**:

1. **`testSwapEthForToken()`**
   - Tests single token swap (LINK by default)
   - Verifies successful ETH → Token conversion
   - Checks balance changes and event emission

2. **`testSwapMultipleEthPairs()`**
   - Tests all 18 configured tokens in sequence
   - Uses 0.5 ETH per swap with 8% slippage tolerance
   - Verifies each token can be successfully swapped
   - Most comprehensive integration test

3. **`testSlippageValidation()`**
   - Tests slippage bounds (0-10,000 bps = 0-100%)
   - Verifies rejection of invalid slippage (>100%)
   - Uses `InvalidSlippage` custom error

4. **`testDeadlineValidation()`**
   - Tests deadline enforcement
   - Verifies rejection of expired deadlines
   - Uses standard "deadline expired" revert message

5. **`testZeroEthRevert()`**
   - Tests zero ETH input validation
   - Verifies `NoEthSent` custom error is thrown
   - Ensures contract rejects empty transactions

6. **`testFeedNotSet()`**
   - Tests behavior with unconfigured tokens
   - Verifies `FeedNotSet` custom error for unknown tokens
   - Ensures only admin-configured tokens can be swapped

7. **`testSimplifiedAdminFunctions()`**
   - Tests admin-only feed configuration
   - Verifies `setFeeds()` and `removeFeed()` functions
   - Tests access control (only owner can configure)

8. **`testSimplifiedEvents()`**
   - Tests event emission for successful swaps
   - Verifies `Swapped` event with correct parameters
   - Includes: user, token, ethIn, tokensOut, fee, minOut, tokenEthPrice

9. **`testGasEfficiency()`**
   - Measures gas usage for typical swaps
   - Helps identify gas optimization opportunities
   - Provides baseline for performance monitoring

## Addresses Used

### Mainnet Constants
- **Uniswap V3 Router**: `0xE592427A0AEce92De3Edee1F18E0157C05861564`
- **Uniswap V3 Factory**: `0x1F98431c8aD98523631AE4a59f267346ea31F984`
- **WETH**: `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`

### Key Features
- **ETH-Only Design**: Uses only TOKEN/ETH Chainlink feeds (no USD conversion needed)
- **18 Verified Feeds**: All tokens use official Chainlink TOKEN/ETH price feeds
- **Optimal Fee Tiers**: 0.05% for stablecoins, 0.30% for major tokens, 1.00% for volatile tokens
- **Oracle Staleness**: 24-hour maximum age for price data

### Fork Block
- **Block Number**: 20935000 (October 10, 2024 11:46 UTC)

## Troubleshooting

### Common Issues

1. **RPC Rate Limiting**
   ```
   Error: Max retries exceeded HTTP error 429
   ```
   - Solution: Use a paid RPC service or wait and retry

2. **Fork Block Too Recent**
   ```
   Error: block number is in the future
   ```
   - Solution: Use an older block number or update to current

3. **Missing Pools**
   ```
   Warning: No pool found for [TOKEN]
   ```
   - This is expected for some tokens - the test will skip them

### Debug Mode

Run tests with maximum verbosity:

```bash
forge test -vvvv --fork-url $ETH_RPC_URL
```

### Gas Reports

Generate gas usage reports:

```bash
forge test --gas-report
```

## Extending Tests

### Adding New Tokens

To add more tokens from the pairs.csv file:

1. Find the token contract address
2. Find the Chainlink feed address
3. Determine the optimal Uniswap V3 fee tier
4. Add to `_initializeTokenConfigs()` function

### Adding New Test Cases

Follow the existing pattern:
- Check `isForkMode` for tests requiring mainnet data
- Use descriptive test names
- Include proper assertions and error messages
- Add console.log statements for debugging

## Performance

- **Basic tests**: ~1-2 seconds
- **Fork tests**: ~10-30 seconds (depending on RPC speed)
- **Full suite**: ~1-2 minutes with good RPC

## Security Notes

- Tests use mainnet fork at a specific block for deterministic results
- No real ETH is spent during testing
- All tests run in isolated VM environment
- Private keys are generated for testing only

## Next Steps

1. **Additional Tokens**: Consider adding more high-quality ETH pairs with reliable Chainlink feeds
2. **Advanced Scenarios**: Test oracle manipulation and MEV protection scenarios  
3. **Stress Testing**: Test with extreme market conditions and high volatility
4. **Gas Optimization**: Profile and optimize gas usage for different token types
5. **Integration Tests**: Test with actual frontend integration and user workflows
6. **Security Audit**: Professional security review before mainnet deployment

## Test Results Summary

When all tests pass, you should see:
```
Ran 9 tests for test/GuardedEthTokenSwapper.t.sol:GuardedEthTokenSwapperTest
[PASS] testDeadlineValidation() (gas: ~26,000)
[PASS] testFeedNotSet() (gas: ~30,000)  
[PASS] testGasEfficiency() (gas: ~185,000)
[PASS] testSimplifiedAdminFunctions() (gas: ~22,000)
[PASS] testSimplifiedEvents() (gas: ~193,000)
[PASS] testSlippageValidation() (gas: ~25,000)
[PASS] testSwapEthForToken() (gas: ~192,000)
[PASS] testSwapMultipleEthPairs() (gas: ~4,000,000)
[PASS] testZeroEthRevert() (gas: ~19,000)

Suite result: ok. 9 passed; 0 failed; 0 skipped
```

The `testSwapMultipleEthPairs()` test is the most comprehensive, testing all 18 tokens with real mainnet data!
