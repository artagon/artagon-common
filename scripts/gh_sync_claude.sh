#!/usr/bin/env bash
set -euo pipefail

# gh_sync_claude.sh - sync Claude agent configuration with shared preferences
# Usage: ./scripts/gh_sync_claude.sh [--dry-run]
#
# This script manages Claude agent configuration by ensuring the .claude symlink
# points to .agents-claude directory which contains symlinks to shared content.
#
# New structure (post-refactor):
#   .claude/ -> .agents-claude/
#   .agents-claude/
#     project.md (model-specific)
#     preferences.md -> ../.agents-shared/preferences.md
#     project-context.md -> ../.agents-shared/project-context.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage: gh_sync_claude.sh [--dry-run]

Ensures Claude agent configuration is properly set up with symlinks to shared content.

Options:
  --dry-run    Show what would be done without making changes
  -h, --help   Show this help message

Structure:
  .claude/                -> .agents-claude/
  .agents-claude/
    project.md            (Claude-specific configuration)
    preferences.md        -> ../.agents-shared/preferences.md
    project-context.md    -> ../.agents-shared/project-context.md
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

cd "$ROOT_DIR"

resolve_shared_target() {
  if [[ -d .common/artagon-common/.agents-claude ]]; then
    SHARED_DIR=".common/artagon-common/.agents-claude"
    SHARED_LINK="../.common/artagon-common/.agents-claude"
    return 0
  elif [[ -d .agents-claude ]]; then
    SHARED_DIR=".agents-claude"
    SHARED_LINK="../.agents-claude"
    return 0
  fi
  SHARED_DIR=""
  SHARED_LINK=""
  return 1
}

ensure_symlink() {
  local target="$1"
  local link="$2"
  if [[ -L "$link" ]]; then
    ln -snf "$target" "$link"
  elif [[ ! -e "$link" ]]; then
    ln -s "$target" "$link"
  elif [[ -d "$link" ]]; then
    echo "Warning: $link exists as directory, not symlink. Manual intervention needed." >&2
    return 1
  fi
}

if ! resolve_shared_target; then
  echo "Error: Could not locate Claude agent configuration directory" >&2
  exit 1
fi

echo "Found Claude agent configuration at: $SHARED_DIR"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[DRY RUN] Would ensure .claude symlink points to $SHARED_LINK"
else
  ensure_symlink "$SHARED_LINK" .claude
  echo "✓ Claude agent configuration synced"
  echo "  .claude -> $SHARED_LINK"
fi
