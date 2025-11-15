#!/bin/bash

# GuardedEthTokenSwapper - Mainnet Integration Testing Script
# Tests the DEPLOYED contract on mainnet (not a fresh deployment)

set -e

echo "🌐 GuardedEthTokenSwapper - Mainnet Integration Tests"
echo "======================================================="
echo ""
echo "This script tests the DEPLOYED contract at:"
echo "  0x7FFc0E3F2aC6ba73ada2063D3Ad8c5aF554ED05f"
echo ""
echo "Requirements:"
echo "  ✓ ETH_RPC_URL environment variable"
echo "  ✓ Mainnet fork capability"
echo ""

# Check for RPC URL
if [ -z "$ETH_RPC_URL" ]; then
    # Try loading from .env
    if [ -f .env ]; then
        echo "📄 Loading ETH_RPC_URL from .env file..."
        export $(cat .env | grep "^ETH_RPC_URL=" | xargs)
    fi
    
    if [ -z "$ETH_RPC_URL" ]; then
        echo "❌ Error: ETH_RPC_URL not set"
        echo ""
        echo "Please set ETH_RPC_URL in your .env file or export it:"
        echo "  export ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY"
        echo ""
        exit 1
    fi
fi

echo "✅ RPC URL configured"
echo ""

echo "🔨 Running mainnet integration tests..."
echo ""

# Run the mainnet integration tests
forge test \
    --match-contract "GuardedEthTokenSwapperMainnetTest" \
    -vv

RESULT=$?

echo ""
echo "======================================================="

if [ $RESULT -eq 0 ]; then
    echo "✅ MAINNET INTEGRATION TESTS PASSED!"
    echo ""
    echo "The deployed contract is:"
    echo "  ✓ Properly configured by admin"
    echo "  ✓ Oracle feeds working"
    echo "  ✓ Swaps executing on mainnet"
    echo "  ✓ Ready for production use!"
else
    echo "❌ Some mainnet tests failed"
    echo ""
    echo "This may be due to:"
    echo "  • Temporary mainnet conditions"
    echo "  • RPC provider rate limits"
    echo "  • Liquidity fluctuations"
    echo ""
    echo "Review the test output above for details."
fi

echo "======================================================="

exit $RESULT

