#!/bin/bash

# GuardedEthTokenSwapper Deployment Script
# This script handles deployment to Ethereum mainnet with Etherscan verification

set -e

echo "🚀 GuardedEthTokenSwapper Deployment"
echo "======================================"
echo ""

# Load .env file if it exists
if [ -f .env ]; then
    echo "📄 Loading environment variables from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
    echo ""
fi

# Check required environment variables
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY environment variable is not set"
    echo "   Please either:"
    echo "   1. Copy .env.example to .env and fill in your values"
    echo "   2. Or export PRIVATE_KEY=0x..."
    exit 1
fi

if [ -z "$ETH_RPC_URL" ]; then
    echo "❌ Error: ETH_RPC_URL environment variable is not set"
    echo "   Please either:"
    echo "   1. Add ETH_RPC_URL to your .env file (see .env.example)"
    echo "   2. Or export ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY"
    exit 1
fi

# Etherscan API key is optional but recommended
if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "⚠️  Warning: ETHERSCAN_API_KEY not set"
    echo "   Automatic Etherscan verification will be skipped"
    echo "   You can verify manually later"
    echo ""
    VERIFY_FLAG=""
else
    echo "✅ Etherscan API key found"
    VERIFY_FLAG="--verify --etherscan-api-key $ETHERSCAN_API_KEY"
fi

echo ""
echo "📋 Deployment Configuration:"
echo "   RPC URL: $ETH_RPC_URL"
echo "   Verify on Etherscan: $([ -n "$VERIFY_FLAG" ] && echo "Yes" || echo "No")"
echo ""

# Ask for confirmation
read -p "Deploy to mainnet? This will use real ETH. (yes/no): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo "🔨 Building contracts..."
forge build

echo ""
echo "📡 Deploying to Ethereum mainnet..."
echo ""

# Deploy with or without verification
forge script script/Deploy.s.sol:Deploy \
    --rpc-url "$ETH_RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    $VERIFY_FLAG \
    --broadcast \
    -vvv

echo ""
echo "✅ Deployment script completed!"
echo ""
echo "📝 Next steps:"
echo "   1. Save the contract address from the output above"
echo "   2. If not auto-verified, verify on Etherscan manually"
echo "   3. Test the contract with a small amount first"
echo "   4. Update your frontend/integration with the new address"
echo ""

