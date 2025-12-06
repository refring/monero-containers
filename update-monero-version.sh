#!/bin/bash

set -e

# Update Monero version script
# Usage: ./update-monero-version.sh <version> <checksum>
# Example: ./update-monero-version.sh 0.18.4.1 702ccb799c24160c0c76676d7a5b21a7e3432be47294d20e0a75451592f591b2

if [ $# -ne 2 ]; then
    echo "Usage: $0 <version> <checksum>"
    echo "Example: $0 0.18.4.1 702ccb799c24160c0c76676d7a5b21a7e3432be47294d20e0a75451592f591b2"
    exit 1
fi

NEW_VERSION="$1"
NEW_CHECKSUM="$2"

# Validate version format (x.y.z.w)
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format x.y.z.w (e.g., 0.18.4.1)"
    exit 1
fi

# Validate checksum format (64 hex characters)
if ! [[ "$NEW_CHECKSUM" =~ ^[a-fA-F0-9]{64}$ ]]; then
    echo "Error: Checksum must be a 64-character hex string"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANCH_NAME="v${NEW_VERSION}"

# Ensure we're on main branch and up to date
echo "Checking git status..."
cd "$SCRIPT_DIR"

CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "Error: Not on main branch (currently on '$CURRENT_BRANCH')"
    echo "Please switch to main branch first: git checkout main"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Error: You have uncommitted changes. Please commit or stash them first."
    exit 1
fi

# Pull latest changes
echo "Pulling latest changes from origin/main..."
git pull origin main

# Create new branch
echo "Creating branch '$BRANCH_NAME'..."
git checkout -b "$BRANCH_NAME"
echo ""

# Get current versions
MONEROD_VERSION=$(cat "$SCRIPT_DIR/monerod/VERSION" | tr -d '\n')
WALLET_RPC_VERSION=$(cat "$SCRIPT_DIR/monero-wallet-rpc/VERSION" | tr -d '\n')

echo "Updating Monero version..."
echo "  monerod: $MONEROD_VERSION -> $NEW_VERSION"
echo "  monero-wallet-rpc: $WALLET_RPC_VERSION -> $NEW_VERSION"
echo "  New checksum: $NEW_CHECKSUM"
echo ""

# Directories to update (excluding monero-lws)
DIRS=("monerod" "monero-wallet-rpc")

for dir in "${DIRS[@]}"; do
    echo "Updating $dir..."

    # Get the old version for this directory
    OLD_VERSION=$(cat "$SCRIPT_DIR/$dir/VERSION" | tr -d '\n')
    OLD_CHECKSUM=$(cat "$SCRIPT_DIR/$dir/SHASUM" | tr -d '\n')

    # Update VERSION file
    echo "$NEW_VERSION" > "$SCRIPT_DIR/$dir/VERSION"
    echo "  Updated VERSION"

    # Update SHASUM file
    echo "$NEW_CHECKSUM" > "$SCRIPT_DIR/$dir/SHASUM"
    echo "  Updated SHASUM"

    # Update Dockerfile
    sed -i "s/VERSION=\${VRS:-v${OLD_VERSION}}/VERSION=\${VRS:-v${NEW_VERSION}}/g" "$SCRIPT_DIR/$dir/Dockerfile"
    echo "  Updated Dockerfile"

    # Update README.md - replace all occurrences of the old version
    sed -i "s/${OLD_VERSION}/${NEW_VERSION}/g" "$SCRIPT_DIR/$dir/README.md"
    echo "  Updated README.md"

    echo ""
done

echo "Done! Updated to version $NEW_VERSION on branch '$BRANCH_NAME'"
echo ""
echo "Files modified:"
git status --short
echo ""
echo "Next steps:"
echo "  git add -A && git commit -m 'Updated to $NEW_VERSION'"
echo "  git push -u origin $BRANCH_NAME"
