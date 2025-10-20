#!/bin/bash

# GuardedEthTokenSwapper Validated Fork Testing Script
# CRITICAL: This script uses block 23620206 which is VALIDATED for all 14 tokens
# For latest block testing, use: ./test_fork_latest.sh

set -e

echo "🚀 GuardedEthTokenSwapper Validated Fork Testing"
echo "=================================================="
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

echo "🔗 Validated Fork Block: $FORK_BLOCK"
echo "   This block is KNOWN to work with all 14 configured tokens"
echo "   Liquidity, prices, and oracle feeds are validated at this block"
echo ""
echo "💡 To test with latest mainnet state, use: ./test_fork_latest.sh"
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
echo "✅ Validated fork testing completed!"
echo ""
echo "📊 Test Summary:"
echo "   • 14 production-ready tokens tested"
echo "   • 5% oracle validation tolerance"
echo "   • 100% success rate required"
echo "   • Block $FORK_BLOCK (validated configuration)"
echo ""
echo "💡 Next Steps:"
echo "   • All tests passed at validated block"
echo "   • For current mainnet testing: ./test_fork_latest.sh"
echo "   • For quick tests without fork: ./test_quick.sh"
