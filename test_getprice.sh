#!/bin/bash
#
# getPrice Integration Test Script
# Tests the getTokenPrice() view function with all 14 configured tokens
#

set -e

echo "🔍 GuardedEthTokenSwapper getTokenPrice() Integration Tests"
echo "=============================================================="
echo ""

# Check for RPC URL
if [ -z "$ETH_RPC_URL" ]; then
    echo "❌ ERROR: ETH_RPC_URL environment variable is required for fork testing."
    echo ""
    echo "   This test requires access to mainnet state at block 23620206."
    echo "   Public RPCs often don't support historical/archive data."
    echo ""
    echo "   Please set your RPC URL:"
    echo "   export ETH_RPC_URL=\"your-alchemy-or-infura-url\""
    echo ""
    echo "   Example providers with archive access:"
    echo "   • Alchemy: https://eth-mainnet.g.alchemy.com/v2/YOUR-API-KEY"
    echo "   • Infura: https://mainnet.infura.io/v3/YOUR-API-KEY"
    echo "   • QuickNode: your-quicknode-url"
    echo ""
    exit 1
fi

echo "🔗 Validated Fork Block: 23620206"
echo "   Using RPC: ${ETH_RPC_URL:0:40}..."
echo ""
echo "🧪 Running getTokenPrice tests for all 14 tokens..."
echo ""

# Run the tests
forge test \
    --match-contract "GuardedEthTokenSwapperGetPriceTest" \
    --fork-url "$ETH_RPC_URL" \
    --fork-block-number 23620206 \
    -vv

echo ""
echo "✅ getTokenPrice tests completed!"
echo ""
echo "📊 This test validated:"
echo "   • Price feeds return valid prices (> 0)"
echo "   • All 14 tokens have working oracle feeds"
echo "   • Prices are returned with correct decimals (18)"
echo "   • Unconfigured tokens properly revert"
echo "   • Oracle data freshness is validated"
echo ""

