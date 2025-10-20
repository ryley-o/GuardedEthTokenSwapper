#!/bin/bash

# Quick Test Script - Run basic tests without fork
# Use this for fast development testing

set -e

echo "⚡ GuardedEthTokenSwapper Quick Tests"
echo "===================================="
echo ""
echo "Running basic tests (no fork required)..."
echo ""

forge test -vv

echo ""
echo "✅ Quick tests completed!"
echo ""
echo "💡 For comprehensive fork testing, run: ./test_fork.sh"
echo "   Or set ETH_RPC_URL and run: ETH_RPC_URL=your_rpc ./test_fork.sh"
