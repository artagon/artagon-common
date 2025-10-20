#!/usr/bin/env bash

# Shared shell helpers for artagon-common scripts.
# Functions here avoid side effects so they can be safely sourced.

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "scripts/lib/common.sh is intended to be sourced, not executed." >&2
  exit 1
fi

if [[ -n "${ARTAGON_COMMON_LIB_LOADED:-}" ]]; then
  return 0
fi
ARTAGON_COMMON_LIB_LOADED=1

# Ensure each required command exists on PATH.
require_commands() {
  local missing=()
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -ne 0 ]]; then
    printf 'Required tool(s) missing: %s\n' "${missing[*]}" >&2
    return 1
  fi
}

# Normalize a project name to an uppercase header guard identifier.
generate_header_guard() {
  local name="${1:-}"
  local guard="${name//[^A-Za-z0-9]/_}"
  guard="${guard^^}"
  if [[ -z "$guard" ]]; then
    guard="PROJECT"
  fi
  printf '%s' "$guard"
}

# Execute a GitHub repository creation via gh CLI without eval usage.
# Accepts optional trailing flags (e.g. --clone, --confirm).
gh_repo_create() {
  local owner="$1"
  local repo="$2"
  local visibility_flag="$3"
  local description="${4:-}"
  shift 4 || true
  local -a extra_flags=("$@")

  local -a cmd=(gh repo create "${owner}/${repo}" "$visibility_flag")
  if [[ -n "$description" ]]; then
    cmd+=(--description "$description")
  fi
  if [[ ${#extra_flags[@]} -gt 0 ]]; then
    cmd+=("${extra_flags[@]}")
  fi

  "${cmd[@]}"
}

# Trim Maven log prefixes like "[INFO]" and leading whitespace.
clean_maven_dependency_line() {
  local line="${1//$'\r'/}"
  if [[ "$line" =~ ^\[[A-Z]+\][[:space:]]* ]]; then
    local prefix="${BASH_REMATCH[0]}"
    line="${line#"$prefix"}"
  fi
  # Trim leading whitespace
  line="${line#"${line%%[![:space:]]*}"}"
  printf '%s' "$line"
}
