#!/usr/bin/env bash
# gh_sync_codex.sh - ensure Codex preferences/context overlays reference shared Artagon defaults.

set -euo pipefail

MODE="ensure"
QUIET=false
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

usage() {
  cat <<'USAGE'
Usage: scripts/gh_sync_codex.sh [--ensure|--check] [--quiet]

Ensures the repository exposes shared Codex preferences while allowing
project-specific overlays.

Options:
  --ensure       (default) create/update symlinks and stub overlays as needed
  --check        verify structure only; fail if invariants are broken
  -q, --quiet    suppress informational output
  -h, --help     show this message
USAGE
}

log() {
  $QUIET || printf '%s
' "$1"
}

warn() {
  >&2 printf 'WARN: %s
' "$1"
}

err() {
  >&2 printf 'ERROR: %s
' "$1"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ensure)
      MODE="ensure"
      ;;
    --check)
      MODE="check"
      ;;
    -q|--quiet)
      QUIET=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
  shift
done

cd "$ROOT_DIR"

resolve_shared_target() {
  if [[ -d .common/artagon-common/.agents-codex ]]; then
    SHARED_DIR=".common/artagon-common/.agents-codex"
    SHARED_LINK="../.common/artagon-common/.agents-codex"
    return 0
  elif [[ -d .agents-codex ]]; then
    SHARED_DIR=".agents-codex"
    SHARED_LINK="../.agents-codex"
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
  elif [[ -e "$link" ]]; then
    rm -rf "$link"
    ln -snf "$target" "$link"
  else
    ln -snf "$target" "$link"
  fi
}

ensure_overlay_file() {
  local file="$1"
  local shared_ref="$2"
  if [[ -L "$file" ]]; then
    rm -f "$file"
  fi
  if [[ ! -f "$file" ]]; then
    cat <<EOF > "$file"
# Project Codex $(basename "${file%.*}")

> Base guidance: see [shared/$(basename "$shared_ref")]($shared_ref)

## Project-specific notes
- Document local policies here.
EOF
  fi
}

check_contains_shared() {
  local file="$1"
  local ref="$2"
  if [[ ! -f "$file" ]]; then
    err "Missing overlay file: $file"
    return 1
  fi
  if ! grep -q "$ref" "$file"; then
    err "Overlay $file must reference $ref"
    return 1
  fi
  return 0
}

run_ensure() {
  if ! resolve_shared_target; then
    warn "Shared Codex preferences not found (.common/artagon-common/.agents/codex or .agents/codex)"
    return 0
  fi

  mkdir -p codex .codex
  ensure_symlink "$SHARED_LINK" "codex/shared"
  ensure_overlay_file "codex/preferences.md" "shared/preferences.md"
  ensure_overlay_file "codex/project-context.md" "shared/project-context.md"
  ensure_symlink "../codex/preferences.md" ".codex/preferences.md"
  ensure_symlink "../codex/project-context.md" ".codex/project-context.md"

  log "Codex shared references synchronized"
}

run_check() {
  local status=0
  if ! resolve_shared_target; then
    warn "Shared Codex preferences not found (.common/artagon-common/.agents/codex or .agents/codex)"
    return 0
  fi

  if [[ ! -L codex/shared ]]; then
    err "codex/shared must be a symlink"
    status=1
  fi

  check_contains_shared "codex/preferences.md" "shared/preferences.md" || status=1
  check_contains_shared "codex/project-context.md" "shared/project-context.md" || status=1

  if [[ ! -L .codex/preferences.md ]] || [[ "$(readlink .codex/preferences.md 2>/dev/null)" != "../codex/preferences.md" ]]; then
    err ".codex/preferences.md must symlink to ../codex/preferences.md"
    status=1
  fi
  if [[ ! -L .codex/project-context.md ]] || [[ "$(readlink .codex/project-context.md 2>/dev/null)" != "../codex/project-context.md" ]]; then
    err ".codex/project-context.md must symlink to ../codex/project-context.md"
    status=1
  fi

  return $status
}

if [[ "$MODE" == "ensure" ]]; then
  run_ensure
fi

if ! run_check; then
  exit 1
fi

exit 0
