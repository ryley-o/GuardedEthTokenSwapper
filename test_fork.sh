#!/bin/bash

# GuardedEthTokenSwapper Fork Testing Script
# CRITICAL: This script uses block 23620206 which is optimized for all 14 tokens

set -e

echo "🚀 GuardedEthTokenSwapper Fork Testing"
echo "======================================="
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

# Fork block - CRITICAL for test success
FORK_BLOCK=23620206

echo "🔗 Fork Block: $FORK_BLOCK (optimized for 14 tokens)"
echo ""

# Run the comprehensive test
echo "🧪 Running comprehensive test for all 14 tokens..."
echo "   This test validates 5% oracle tolerance for each token"
echo ""

forge test \
    --match-test testSwapMultipleEthPairs \
    --fork-url "$RPC_URL" \
    --fork-block-number $FORK_BLOCK \
    -vv

echo ""
echo "✅ Fork testing completed!"
echo ""
echo "📊 Test Summary:"
echo "   • 14 production-ready tokens tested"
echo "   • 5% oracle validation tolerance"
echo "   • 100% success rate required"
echo "   • Block $FORK_BLOCK (optimized liquidity)"
