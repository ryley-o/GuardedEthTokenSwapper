#!/bin/bash

# Setup script for GuardedEthTokenSwapper
# Installs the correct Foundry version for this project

set -e

echo "🔧 GuardedEthTokenSwapper - Foundry Setup"
echo "=========================================="
echo ""

# Check if foundryup is installed
if ! command -v foundryup &> /dev/null; then
    echo "❌ Error: foundryup not found"
    echo ""
    echo "Please install Foundry first:"
    echo "  curl -L https://foundry.paradigm.xyz | bash"
    echo "  foundryup"
    echo ""
    exit 1
fi

# Read version from .foundryrc
if [ -f .foundryrc ]; then
    REQUIRED_VERSION=$(grep "FOUNDRY_VERSION=" .foundryrc | cut -d'=' -f2)
    echo "📦 Required Foundry version: $REQUIRED_VERSION"
    echo ""
else
    echo "⚠️  Warning: .foundryrc not found"
    echo "   Using latest stable version"
    REQUIRED_VERSION="stable"
fi

# Install the required version
echo "⬇️  Installing Foundry $REQUIRED_VERSION..."
foundryup --version "$REQUIRED_VERSION"

echo ""
echo "✅ Foundry setup complete!"
echo ""
echo "📊 Installed versions:"
forge --version
echo ""
echo "🎯 Next steps:"
echo "   1. Install git hooks: ./install-hooks.sh"
echo "   2. Run tests: ./test_quick.sh"
echo ""

