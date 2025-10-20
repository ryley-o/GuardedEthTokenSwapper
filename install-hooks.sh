#!/bin/bash

# Install Git Hooks for GuardedEthTokenSwapper
# This script installs the pre-commit hook that auto-formats Solidity files

set -e

echo "🔧 Installing Git hooks for GuardedEthTokenSwapper"
echo "================================================="
echo ""

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo "❌ Error: Not in a git repository"
    echo "   Please run this script from the repository root"
    exit 1
fi

# Check if forge is installed
if ! command -v forge &> /dev/null; then
    echo "⚠️  Warning: forge (Foundry) not found"
    echo "   The pre-commit hook will be installed but won't work until you install Foundry"
    echo "   Install from: https://getfoundry.sh/"
    echo ""
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy pre-commit hook
if [ -f hooks/pre-commit ]; then
    cp hooks/pre-commit .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    echo "✅ Pre-commit hook installed"
else
    echo "❌ Error: hooks/pre-commit not found"
    exit 1
fi

echo ""
echo "✨ Git hooks successfully installed!"
echo ""
echo "📝 What this does:"
echo "   • Automatically runs 'forge fmt' before each commit"
echo "   • Formats all Solidity files (.sol)"
echo "   • Re-stages formatted files automatically"
echo "   • Ensures consistent code formatting"
echo ""
echo "💡 To bypass the hook (not recommended):"
echo "   git commit --no-verify"
echo ""
echo "🚀 Ready to commit with automatic formatting!"

