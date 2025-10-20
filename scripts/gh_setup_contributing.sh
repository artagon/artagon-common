#!/usr/bin/env bash
# gh_setup_contributing.sh - Generate CONTRIBUTING.md from template with variable substitution
#
# This script generates a CONTRIBUTING.md file from the template with automatic
# variable substitution based on the current repository.

set -euo pipefail

# Configuration
DRY_RUN=false
FORCE=false
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TEMPLATE_PATH=""

usage() {
  cat <<'USAGE'
Usage: scripts/gh_setup_contributing.sh [OPTIONS]

Generate CONTRIBUTING.md from template with variable substitution.

Options:
  --dry-run      preview changes without creating file
  --force        overwrite existing CONTRIBUTING.md
  -h, --help     show this message

Example:
  ./scripts/gh_setup_contributing.sh
  ./scripts/gh_setup_contributing.sh --dry-run

Template Variables:
  {{ repository.name }}         - Repository name
  {{ repository.owner }}        - Organization/owner name
  {{ repository.description }}  - Repository description (from GitHub)
USAGE
}

log() {
  printf '%s\n' "$1"
}

warn() {
  >&2 printf 'WARN: %s\n' "$1"
}

err() {
  >&2 printf 'ERROR: %s\n' "$1"
}

# Detect repository information
get_repo_name() {
  basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
}

get_repo_owner() {
  local remote_url
  remote_url="$(git remote get-url origin 2>/dev/null || echo "")"

  if [[ -z "$remote_url" ]]; then
    echo "artagon"
    return
  fi

  # Extract owner from git@github.com:owner/repo or https://github.com/owner/repo
  echo "$remote_url" | sed -E 's|.*[:/]([^/]+)/[^/]+.*|\1|'
}

get_repo_description() {
  # Try to get description from GitHub via gh CLI
  if command -v gh &>/dev/null; then
    local desc
    desc="$(gh repo view --json description -q .description 2>/dev/null || echo "")"
    if [[ -n "$desc" ]]; then
      echo "$desc"
      return
    fi
  fi

  # Fallback: check README.md first line
  if [[ -f README.md ]]; then
    local first_line
    first_line="$(head -1 README.md | sed 's/^#* *//')"
    if [[ -n "$first_line" ]]; then
      echo "$first_line"
      return
    fi
  fi

  # Default
  echo "An Artagon project"
}

# Find template
find_template() {
  # Check for template in .common/artagon-common submodule (new location)
  if [[ -f .common/artagon-common/templates/CONTRIBUTING.md.template ]]; then
    echo ".common/artagon-common/templates/CONTRIBUTING.md.template"
    return 0
  fi

  # Check for template in artagon-common submodule (legacy location)
  if [[ -f artagon-common/templates/CONTRIBUTING.md.template ]]; then
    echo "artagon-common/templates/CONTRIBUTING.md.template"
    return 0
  fi

  # Check for local template
  if [[ -f templates/CONTRIBUTING.md.template ]]; then
    echo "templates/CONTRIBUTING.md.template"
    return 0
  fi

  return 1
}

# Substitute variables in template
substitute_variables() {
  local template="$1"
  local repo_name="$2"
  local repo_owner="$3"
  local repo_desc="$4"

  # Escape replacement values for sed
  local repo_name_escaped repo_owner_escaped repo_desc_escaped
  repo_name_escaped=$(printf '%s' "$repo_name" | sed -e 's/[&|\\/]/\\&/g')
  repo_owner_escaped=$(printf '%s' "$repo_owner" | sed -e 's/[&|\\/]/\\&/g')
  repo_desc_escaped=$(printf '%s' "$repo_desc" | sed -e 's/[&|\\/]/\\&/g')

  # Read template and substitute variables
  sed -e "s|{{ repository.name }}|$repo_name_escaped|g" \
      -e "s|{{ repository.owner }}|$repo_owner_escaped|g" \
      -e "s|{{ repository.description }}|$repo_desc_escaped|g" \
      "$template"
}

# Main execution
main() {
  cd "$ROOT_DIR"

  # Check if CONTRIBUTING.md already exists
  if [[ -f CONTRIBUTING.md ]] && [[ "$FORCE" == "false" ]]; then
    warn "CONTRIBUTING.md already exists (use --force to overwrite)"
    exit 0
  fi

  # Find template
  if ! TEMPLATE_PATH="$(find_template)"; then
    err "Could not find CONTRIBUTING.md.template"
    err "Expected locations:"
    err "  - .common/artagon-common/templates/CONTRIBUTING.md.template"
    err "  - artagon-common/templates/CONTRIBUTING.md.template"
    err "  - templates/CONTRIBUTING.md.template"
    exit 1
  fi

  log "Found template: $TEMPLATE_PATH"

  # Get repository information
  local repo_name repo_owner repo_desc
  repo_name="$(get_repo_name)"
  repo_owner="$(get_repo_owner)"
  repo_desc="$(get_repo_description)"

  log ""
  log "Repository Information:"
  log "  Name:        $repo_name"
  log "  Owner:       $repo_owner"
  log "  Description: $repo_desc"
  log ""

  # Dry run mode
  if [[ "$DRY_RUN" == "true" ]]; then
    log "[DRY RUN] Would generate CONTRIBUTING.md with substitutions"
    log ""
    log "Preview (first 20 lines):"
    log "----------------------------------------"
    substitute_variables "$TEMPLATE_PATH" "$repo_name" "$repo_owner" "$repo_desc" | head -20
    log "----------------------------------------"
    log ""
    log "[DRY RUN] No file created"
    exit 0
  fi

  # Generate CONTRIBUTING.md
  substitute_variables "$TEMPLATE_PATH" "$repo_name" "$repo_owner" "$repo_desc" > CONTRIBUTING.md

  log "✓ Generated CONTRIBUTING.md from template"
  log ""
  log "Next steps:"
  log "  1. Review CONTRIBUTING.md"
  log "  2. Customize project-specific sections:"
  log "     - Prerequisites"
  log "     - Install Dependencies"
  log "     - Language-Specific Standards"
  log "     - Testing"
  log "     - Project-Specific Guidelines"
  log "  3. Commit the file"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    --force)
      FORCE=true
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

main
