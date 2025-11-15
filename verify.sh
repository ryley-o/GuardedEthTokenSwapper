#!/bin/bash

# GuardedEthTokenSwapper - Contract Verification Script
# Verifies the contract on Etherscan

set -e

echo "🔍 GuardedEthTokenSwapper - Contract Verification"
echo "=================================================="
echo ""

# Load environment variables from .env if it exists
if [ -f .env ]; then
    echo "📄 Loading environment variables from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
    echo ""
fi

# Contract details
CONTRACT_ADDRESS="${1:-0x7FFc0E3F2aC6ba73ada2063D3Ad8c5aF554ED05f}"
CONTRACT_NAME="GuardedEthTokenSwapper"
CONTRACT_PATH="src/GuardedEthTokenSwapper.sol:GuardedEthTokenSwapper"

# Check for required environment variables
if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "❌ Error: ETHERSCAN_API_KEY environment variable is not set"
    echo "   Please set it in your .env file or export it:"
    echo "   export ETHERSCAN_API_KEY=YOUR_KEY"
    exit 1
fi

echo "📋 Verification Details:"
echo "   Contract: $CONTRACT_NAME"
echo "   Address: $CONTRACT_ADDRESS"
echo "   Chain: Ethereum Mainnet (1)"
echo "   Etherscan: https://etherscan.io/address/$CONTRACT_ADDRESS"
echo ""

# Verify the contract
echo "🔨 Verifying contract on Etherscan..."
echo ""

forge verify-contract \
    "$CONTRACT_ADDRESS" \
    "$CONTRACT_PATH" \
    --chain-id 1 \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --watch \
    --verifier etherscan

VERIFY_STATUS=$?

echo ""
if [ $VERIFY_STATUS -eq 0 ]; then
    echo "✅ Contract verified successfully!"
    echo ""
    echo "🌐 View on Etherscan:"
    echo "   https://etherscan.io/address/$CONTRACT_ADDRESS#code"
    echo ""
else
    echo "⚠️  Verification may have failed or the contract is already verified."
    echo ""
    echo "Common issues:"
    echo "   • Contract already verified (check Etherscan)"
    echo "   • Etherscan API rate limit"
    echo "   • Constructor arguments mismatch (this contract has none)"
    echo ""
    echo "🌐 Check status on Etherscan:"
    echo "   https://etherscan.io/address/$CONTRACT_ADDRESS#code"
    echo ""
fi

exit $VERIFY_STATUS

