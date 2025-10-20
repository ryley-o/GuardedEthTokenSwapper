#!/bin/bash

# GuardedEthTokenSwapper Latest Fork Testing Script
# Tests against the LATEST mainnet block to ensure current compatibility

set -e

echo "🚀 GuardedEthTokenSwapper Latest Block Fork Testing"
echo "===================================================="
echo ""

# Check if RPC URL is provided
if [ -z "$ETH_RPC_URL" ]; then
    echo "⚠️  No ETH_RPC_URL environment variable set."
    echo "   Using public RPC (may be slower): https://ethereum-rpc.publicnode.com"
    echo ""
    RPC_URL="https://ethereum-rpc.publicnode.com"
else
    echo "✅ Using RPC: $ETH_RPC_URL"
    RPC_URL="$ETH_RPC_URL"
fi

# Load .env file if it exists and ETH_RPC_URL not already set
if [ -f .env ] && [ -z "$ETH_RPC_URL" ]; then
    echo "📄 Loading RPC URL from .env file..."
    export $(grep "^ETH_RPC_URL=" .env | xargs)
    if [ -n "$ETH_RPC_URL" ]; then
        RPC_URL="$ETH_RPC_URL"
        echo "✅ Using RPC from .env: $ETH_RPC_URL"
    fi
    echo ""
fi

# Get latest block number
echo "🔍 Fetching latest block number..."
LATEST_BLOCK=$(cast block-number --rpc-url "$RPC_URL" 2>/dev/null || echo "")

if [ -z "$LATEST_BLOCK" ]; then
    echo "❌ Error: Could not fetch latest block number"
    echo "   Please check your RPC URL and internet connection"
    exit 1
fi

echo "✅ Latest block: $LATEST_BLOCK"
echo ""

# Warning about potential differences from validated block
echo "⚠️  Testing Note:"
echo "   • Validated block: 23620206 (known working state)"
echo "   • Latest block: $LATEST_BLOCK"
echo "   • Liquidity and prices may differ from validated configuration"
echo "   • Some tokens may have moved to different fee tiers"
echo "   • Oracle feeds and pool states may have changed"
echo ""

# Ask for confirmation
read -p "Continue with latest block testing? (yes/no): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "Testing cancelled."
    exit 0
fi

echo ""
echo "🧪 Running comprehensive test for all 14 tokens at latest block..."
echo "   This validates current mainnet compatibility"
echo ""

# Run the comprehensive test at latest block
forge test \
    --match-test testSwapMultipleEthPairs \
    --fork-url "$RPC_URL" \
    --fork-block-number "$LATEST_BLOCK" \
    -vv

echo ""
echo "✅ Latest block fork testing completed!"
echo ""
echo "📊 Test Summary:"
echo "   • Tested at block: $LATEST_BLOCK"
echo "   • All 14 production tokens validated"
echo "   • Oracle validation tolerance: 5%"
echo "   • Tests current mainnet state"
echo ""
echo "💡 Note:"
echo "   • If tests fail, liquidity or oracle feeds may have changed"
echo "   • Use ./test_fork.sh for validated block testing"
echo "   • Consider updating token configurations if needed"

