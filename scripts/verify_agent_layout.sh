#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

info() {
  echo "[verify-agent-layout] $*"
}

error() {
  echo "[verify-agent-layout] ERROR: $*" >&2
}

check_symlink() {
  local link_path="$1"
  local expected_target="$2"

  if [[ ! -L "$link_path" ]]; then
    error "Missing symlink: $link_path"
    return 1
  fi

  local actual_target
  actual_target="$(readlink "$link_path")"
  if [[ "$actual_target" != "$expected_target" ]]; then
    error "Symlink $link_path points to $actual_target (expected $expected_target)"
    return 1
  fi

  info "Symlink OK: $link_path -> $expected_target"
}

main() {
  local status=0

  check_symlink "$REPO_ROOT/.agents" ".agents-codex" || status=1
  check_symlink "$REPO_ROOT/.codex" ".agents-codex" || status=1
  check_symlink "$REPO_ROOT/.claude" ".agents-claude" || status=1
  check_symlink "$REPO_ROOT/codex" ".agents-codex" || status=1

  for dir in ".agents-claude" ".agents-codex" ".agents-shared"; do
    if [[ ! -d "$REPO_ROOT/$dir" ]]; then
      error "Missing directory: $dir"
      status=1
    else
      info "Directory OK: $dir"
    fi
  done

  if ! "$REPO_ROOT/scripts/agents/generate_agent_configs.py" --check; then
    error "Generated agent configs are out of sync with manifest"
    status=1
  else
    info "Agent configs match manifest"
  fi

  return "$status"
}

main "$@" || exit $?
