# Git Hooks

This directory contains Git hooks for the GuardedEthTokenSwapper project.

## Available Hooks

### pre-commit

Automatically formats Solidity files before each commit using `forge fmt`.

**Features:**
- ✅ Formats all staged `.sol` files
- ✅ Re-stages formatted files automatically
- ✅ Ensures consistent code style
- ✅ Prevents formatting-related CI failures

## Installation

From the repository root, run:

```bash
./install-hooks.sh
```

This will copy the hooks to `.git/hooks/` and make them executable.

## Manual Installation

If you prefer manual installation:

```bash
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Requirements

- **Foundry** must be installed for the pre-commit hook to work
- Install from: https://getfoundry.sh/

## Bypassing the Hook

If you need to commit without running the hook (not recommended):

```bash
git commit --no-verify
```

## How It Works

1. When you run `git commit`, the hook triggers before the commit is created
2. It checks for staged `.sol` files
3. Runs `forge fmt` on the project
4. If files were formatted, it re-stages them automatically
5. The commit proceeds with properly formatted code

## Benefits

- **Consistent Code Style**: All commits follow the same formatting rules
- **Prevent CI Failures**: No more formatting-related CI failures
- **Zero Manual Work**: Formatting happens automatically
- **Team Alignment**: Everyone uses the same formatting

## Troubleshooting

### Hook not running

Make sure the hook is executable:
```bash
chmod +x .git/hooks/pre-commit
```

### Forge not found

Install Foundry:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Hook failing

Check that `forge fmt` works manually:
```bash
forge fmt --check
```

