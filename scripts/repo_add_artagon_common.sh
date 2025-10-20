#!/usr/bin/env bash
set -euo pipefail

# Setup script to add artagon-common as a submodule to your project
#
# Usage:
#   ./repo_add_artagon_common.sh [submodule-path] [branch]
#
# Arguments:
#   submodule-path  Path where submodule will be added (default: .common/artagon-common)
#   branch          Branch to checkout (default: main)
#
# Examples:
#   ./repo_add_artagon_common.sh
#   ./repo_add_artagon_common.sh .common/artagon-common main
#   ./repo_add_artagon_common.sh tools/common

SUBMODULE_PATH="${1:-.common/artagon-common}"
BRANCH="${2:-main}"
REPO_URL="git@github.com:artagon/artagon-common.git"

echo "=========================================="
echo "Artagon Common Setup"
echo "=========================================="
echo "Submodule path: $SUBMODULE_PATH"
echo "Branch: $BRANCH"
echo "Repository: $REPO_URL"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: Not in a git repository. Please run this script from within a git repository." >&2
  exit 1
fi

# Check if submodule already exists
if [[ -d "$SUBMODULE_PATH" ]] && [[ -f "$SUBMODULE_PATH/.git" || -d "$SUBMODULE_PATH/.git" ]]; then
  echo "✓ artagon-common already exists at $SUBMODULE_PATH"

  # Offer to update
  read -p "Do you want to update to latest $BRANCH? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Updating submodule..."
    cd "$SUBMODULE_PATH"
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
    cd - >/dev/null
    echo "✓ Updated to latest $BRANCH"
  fi

  exit 0
fi

# Check if directory exists but is not a submodule
if [[ -d "$SUBMODULE_PATH" ]]; then
  echo "ERROR: Directory $SUBMODULE_PATH already exists but is not a git submodule." >&2
  echo "Please remove it or choose a different path." >&2
  exit 1
fi

# Create parent directory if needed
PARENT_DIR="$(dirname "$SUBMODULE_PATH")"
if [[ ! -d "$PARENT_DIR" ]]; then
  echo "Creating parent directory: $PARENT_DIR"
  mkdir -p "$PARENT_DIR"
fi

# Add submodule
echo "Adding artagon-common as submodule..."
if ! git submodule add -b "$BRANCH" "$REPO_URL" "$SUBMODULE_PATH"; then
  echo "ERROR: Failed to add submodule. Check your network connection and permissions." >&2
  exit 1
fi

# Initialize and update submodule
echo "Initializing submodule..."
git submodule update --init --recursive "$SUBMODULE_PATH"

echo ""
echo "=========================================="
echo "✓ Successfully installed artagon-common!"
echo "=========================================="
echo ""
echo "Submodule location: $SUBMODULE_PATH"
echo ""
echo "Available scripts:"
ls -1 "$SUBMODULE_PATH/scripts"/*.sh 2>/dev/null | sed 's|^|  - |' || echo "  (no scripts found)"
echo ""
echo "Next steps:"
echo "  1. Review scripts in $SUBMODULE_PATH/artagon-common/scripts/"
echo "  2. Optionally symlink scripts to your project root or ~/bin"
echo "  3. Commit the .gitmodules file and submodule reference:"
echo "     git add .gitmodules $SUBMODULE_PATH"
echo "     git commit -m 'Add artagon-common submodule'"
echo ""
echo "To update in the future:"
echo "  cd $SUBMODULE_PATH && git pull origin $BRANCH"
echo "  # or"
echo "  git submodule update --remote $SUBMODULE_PATH"
echo ""
