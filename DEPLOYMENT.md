# GuardedEthTokenSwapper Deployment Guide

This guide walks you through deploying the GuardedEthTokenSwapper contract to Ethereum mainnet.

## ⚠️ Important Security Notice

**THIS CONTRACT HAS NOT BEEN PROFESSIONALLY AUDITED.**

- Only deploy if you understand the risks
- Use a dedicated deployer wallet
- Test thoroughly on a testnet first
- Start with small amounts
- Never deploy using a wallet with large ETH holdings directly

## Prerequisites

### 1. Development Environment

Ensure you have Foundry installed:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Required Accounts and Keys

You will need:
- **Deployer wallet** with ETH for gas (estimate: 0.05-0.1 ETH for deployment + configuration)
- **Ethereum RPC endpoint** (Alchemy, Infura, or self-hosted)
- **Etherscan API key** (optional, for automatic verification)

### 3. Set Environment Variables

Copy the example file and configure your credentials:

```bash
# Copy the example file
cp .env.example .env

# Edit .env with your actual values
# Never commit your .env file to git!
```

Or export these variables directly:

```bash
# Required
export PRIVATE_KEY=0x...                                           # Your deployer private key
export ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY  # Mainnet RPC URL

# Optional but recommended
export ETHERSCAN_API_KEY=YOUR_KEY                                  # For automatic verification
```

**See `.env.example` for a complete template with all available options and detailed comments.**

**NEVER commit your `.env` file or private keys to git!**

## Pre-Deployment Checklist

- [ ] Foundry is installed and up to date
- [ ] Private key is set and secured
- [ ] RPC URL is configured and working
- [ ] Deployer wallet has sufficient ETH (0.1+ ETH recommended)
- [ ] You have reviewed the contract code
- [ ] You have run all tests successfully
- [ ] You understand the risks (NO AUDIT)

## Deployment Methods

### Option 1: Automated Deployment (Recommended)

The easiest way to deploy:

```bash
./deploy.sh
```

This script will:
1. Check all required environment variables
2. Build the contracts
3. Deploy GuardedEthTokenSwapper
4. Configure all 14 production token pairs
5. Verify the configuration
6. Automatically verify on Etherscan (if API key provided)

**Expected output:**
```
🚀 GuardedEthTokenSwapper Deployment
===========================================
Deployer address: 0x...
Chain ID: 1
Block number: ...

Step 1: Deploying GuardedEthTokenSwapper...
Contract deployed at: 0x...

Step 2: Preparing token configurations...
  [1] 1INCH
    Token: 0x111111111117dC0aa78b770fA6A738034120C302
    ...

Step 3: Configuring all token feeds...
All 14 token feeds configured successfully!

Step 4: Verifying configuration...
  ✓ 1INCH verified
  ✓ AAVE verified
  ...

===========================================
DEPLOYMENT SUCCESSFUL
===========================================
Contract address: 0x...
Owner: 0x...
Tokens configured: 14
```

### Option 2: Manual Deployment with Forge

For more control:

```bash
# Dry run (simulate without broadcasting)
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $ETH_RPC_URL

# Actual deployment with verification
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $ETH_RPC_URL \
  --private-key $PRIVATE_KEY \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --broadcast \
  --verify \
  -vvv
```

### Option 3: Step-by-Step Manual Deployment

If you prefer maximum control:

#### Step 1: Deploy Contract
```bash
forge create \
  --rpc-url $ETH_RPC_URL \
  --private-key $PRIVATE_KEY \
  src/GuardedEthTokenSwapper.sol:GuardedEthTokenSwapper
```

Save the contract address from the output.

#### Step 2: Configure Tokens

Use cast to call `setFeeds()`. You'll need to prepare the arrays with all 14 tokens. See `script/Deploy.s.sol` for the complete configuration.

Example for configuring a single token:
```bash
cast send $CONTRACT_ADDRESS \
  "setFeeds(address[],address[],uint24[],uint16[])" \
  "[0x514910771AF9Ca656af840dff83E8264EcF986CA]" \
  "[0xDC530D9457755926550b59e8ECcdaE7624181557]" \
  "[3000]" \
  "[200]" \
  --rpc-url $ETH_RPC_URL \
  --private-key $PRIVATE_KEY
```

#### Step 3: Verify on Etherscan
```bash
forge verify-contract $CONTRACT_ADDRESS \
  GuardedEthTokenSwapper \
  --chain-id 1 \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch
```

## Post-Deployment

### 1. Verify Contract on Etherscan

Visit `https://etherscan.io/address/<CONTRACT_ADDRESS>` and ensure:
- Contract is verified (green checkmark)
- All 14 tokens are configured (check via `getFeed()` for each token)
- Owner is set correctly
- No unexpected transactions or errors

### 2. Test With Small Amount

**CRITICAL:** Test before using significant amounts!

```bash
# Example: Swap 0.01 ETH for LINK
cast send $CONTRACT_ADDRESS \
  "swapEthForToken(address,uint16,uint256)" \
  0x514910771AF9Ca656af840dff83E8264EcF986CA \
  200 \
  $(date +%s -d '+5 minutes') \
  --value 0.01ether \
  --rpc-url $ETH_RPC_URL \
  --private-key $PRIVATE_KEY
```

### 3. Monitor First Transactions

- Watch the first few swaps closely
- Check that received amounts match expectations
- Verify gas costs are reasonable
- Monitor for any reverts or issues

### 4. Document Deployment

Save these details:
- Contract address
- Deployment block number
- Deployment transaction hash
- Owner address
- Etherscan link

## Supported Tokens

The deployment script automatically configures these 14 tokens:

| Symbol | Name | Fee Tier | Tolerance |
|--------|------|----------|-----------|
| 1INCH | 1inch Network | 1.00% | 5% |
| AAVE | Aave | 0.30% | 3% |
| APE | ApeCoin | 0.30% | 8% |
| BAT | Basic Attention Token | 0.30% | 6% |
| COMP | Compound | 0.30% | 4% |
| CRV | Curve DAO | 0.30% | 4% |
| LDO | Lido DAO | 0.30% | 5% |
| LINK | Chainlink | 0.30% | 2% |
| MKR | Maker | 0.30% | 4% |
| SHIB | Shiba Inu | 1.00% | 10% |
| UNI | Uniswap | 0.30% | 3% |
| USDT | Tether USD | 0.05% | 2% |
| WBTC | Wrapped Bitcoin | 0.05% | 5% |
| ZRX | 0x Protocol | 0.30% | 6% |

## Troubleshooting

### "Insufficient funds for gas"
- Ensure deployer wallet has at least 0.1 ETH
- Check current gas prices

### "Nonce too high"
- Transaction may have already been sent
- Check Etherscan for pending transactions

### "Contract verification failed"
- Ensure compiler version matches (0.8.30)
- Try manual verification with constructor arguments
- Check if contract is already verified

### "RPC rate limit exceeded"
- Use a paid RPC service (Alchemy, Infura)
- Add delays between transactions
- Use a different RPC endpoint

### "Feed mismatch" during configuration
- Check that Chainlink feeds are still active
- Verify feed addresses are correct for mainnet
- Ensure you're deploying to mainnet (chain ID 1)

## Gas Costs

Approximate gas costs (at 30 gwei):

| Operation | Gas Used | Cost (ETH) |
|-----------|----------|------------|
| Contract Deployment | ~1,500,000 | ~0.045 |
| Configure 14 Tokens | ~800,000 | ~0.024 |
| Single Swap | ~180,000 | ~0.0054 |
| **Total Deployment** | **~2,300,000** | **~0.069** |

*Actual costs vary with gas prices*

## Security Best Practices

1. **Use a hardware wallet** for the owner account
2. **Test on testnet** first (Sepolia or Goerli)
3. **Start small** - test with 0.01-0.1 ETH first
4. **Monitor actively** - watch first transactions closely
5. **Keep owner key secure** - it controls all token configurations
6. **Plan for emergencies** - have a process to respond to issues
7. **Consider multisig** - use a multisig wallet as the owner

## Updating Configuration

After deployment, you can update token configurations:

```bash
# Add or update a token feed
cast send $CONTRACT_ADDRESS \
  "setFeeds(address[],address[],uint24[],uint16[])" \
  "[$TOKEN_ADDRESS]" \
  "[$CHAINLINK_FEED]" \
  "[$FEE_TIER]" \
  "[$TOLERANCE_BPS]" \
  --rpc-url $ETH_RPC_URL \
  --private-key $PRIVATE_KEY

# Remove a token
cast send $CONTRACT_ADDRESS \
  "removeFeed(address)" \
  $TOKEN_ADDRESS \
  --rpc-url $ETH_RPC_URL \
  --private-key $PRIVATE_KEY
```

## Need Help?

- Review the code: `src/GuardedEthTokenSwapper.sol`
- Check tests: `test/GuardedEthTokenSwapper.t.sol`
- Read test documentation: `TEST_README.md`
- Check GitHub issues
- Review Foundry documentation: https://book.getfoundry.sh/

## Final Reminder

⚠️ **THIS CONTRACT IS NOT AUDITED**

While thoroughly tested, this contract has not undergone a professional security audit. Use at your own risk and only with funds you can afford to lose.

