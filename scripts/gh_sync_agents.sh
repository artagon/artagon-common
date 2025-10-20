#!/usr/bin/env bash
# gh_sync_agents.sh - Bootstrap agent configuration using hybrid approach (pointers + symlinks)
#
# This script sets up agent directories for new Artagon repositories that use
# artagon-common as a submodule. It creates a hybrid structure with:
# - YAML pointers (context.include, inherits_from) for agent context loading
# - Symlinks for human/tool convenience

set -euo pipefail

# Configuration
MODE="ensure"
QUIET=false
DRY_RUN=false
MODELS="claude codex"
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Paths to shared content
SHARED_BASE=".agents-shared"             # For artagon-common itself
SUBMODULE_SHARED="artagon-common/.agents-shared"  # For repos using artagon-common as submodule

usage() {
  cat <<'USAGE'
Usage: scripts/gh_sync_agents.sh [OPTIONS]

Bootstrap agent configuration for Artagon repositories using hybrid approach
(YAML pointers + convenience symlinks).

Options:
  --ensure       (default) create/update directories, files, and symlinks
  --check        verify structure only; fail if invariants are broken
  --dry-run      preview changes without making modifications
  --models M     sync specific models only (default: "claude codex")
  -q, --quiet    suppress informational output
  -h, --help     show this message

Examples:
  # Full bootstrap for all models
  ./scripts/gh_sync_agents.sh

  # Dry run to preview changes
  ./scripts/gh_sync_agents.sh --dry-run

  # Sync only Claude configuration
  ./scripts/gh_sync_agents.sh --models claude

Hybrid Approach:
  - Pointers: context.include and inherits_from in project.md files
  - Symlinks: convenience links for humans and tools
  - Works for both artagon-common itself and repos using it as submodule
USAGE
}

log() {
  $QUIET || printf '%s\n' "$1"
}

warn() {
  >&2 printf 'WARN: %s\n' "$1"
}

err() {
  >&2 printf 'ERROR: %s\n' "$1"
}

# Resolve where shared content lives
resolve_shared_path() {
  # Check if we're in artagon-common itself
  if [[ -d "$SHARED_BASE" ]]; then
    echo "$SHARED_BASE"
    return 0
  fi

  # Check for artagon-common submodule
  if [[ -d "$SUBMODULE_SHARED" ]]; then
    echo "$SUBMODULE_SHARED"
    return 0
  fi

  # Not found
  return 1
}

# Initialize artagon-common submodule if present
init_submodule() {
  if [[ -f .gitmodules ]] && grep -q 'artagon-common' .gitmodules 2>/dev/null; then
    log "Initializing artagon-common submodule..."
    if ! $DRY_RUN; then
      if ! git submodule update --init --recursive artagon-common 2>&1; then
        warn "Failed to initialize artagon-common submodule. Some features may not work correctly."
      fi
    fi
  fi
}

# Create symlink with cross-platform support
ensure_symlink() {
  local target="$1"
  local link="$2"
  local description="${3:-symlink}"

  if $DRY_RUN; then
    log "[DRY RUN] Would create $description: $link -> $target"
    return 0
  fi

  # Check if link already points to correct target
  if [[ -L "$link" ]]; then
    local current
    current="$(readlink "$link" 2>/dev/null || true)"
    if [[ "$current" == "$target" ]]; then
      return 0
    fi
    rm -f "$link"
  elif [[ -e "$link" ]]; then
    warn "Removing existing non-symlink at $link"
    rm -rf "$link"
  fi

  # Create symlink
  if ln -s "$target" "$link" 2>/dev/null; then
    log "Created $description: $link -> $target"
  else
    # Windows fallback (junction for directories only)
    case "$OSTYPE" in
      msys*|mingw*|cygwin*)
        if [[ -d "$target" ]]; then
          cmd //c "mklink /J \"$(cygpath -w "$link")\" \"$(cygpath -w "$target")\"" 2>/dev/null || \
            warn "Failed to create junction: $link"
        else
          warn "Cannot create symlink on Windows: $link"
        fi
        ;;
      *)
        warn "Failed to create symlink: $link -> $target"
        ;;
    esac
  fi
}

# Generate project.md with pointers to shared content
generate_project_md() {
  local model="$1"
  local agent_dir=".agents-$model"
  local project_file="$agent_dir/project.md"
  local shared_path="${SHARED_PATH}"

  if $DRY_RUN; then
    log "[DRY RUN] Would generate $project_file with pointers"
    return 0
  fi

  # Don't overwrite existing customizations
  if [[ -f "$project_file" ]]; then
    log "Skipping $project_file (already exists)"
    return 0
  fi

  mkdir -p "$agent_dir"

  # Determine paths based on shared location
  local context_path
  local prefs_path
  local inherits_path

  if [[ "$shared_path" == "$SHARED_BASE" ]]; then
    # In artagon-common itself
    context_path="../$shared_path/project-context.md"
    prefs_path="../$shared_path/preferences.md"
    inherits_path="../$shared_path/preferences.md#model_overrides/$model"
  else
    # In repo with artagon-common submodule
    context_path="../$shared_path/project-context.md"
    prefs_path="../$shared_path/preferences.md"
    inherits_path="../$shared_path/preferences.md#model_overrides/$model"
  fi

  cat > "$project_file" <<EOF
---
# ${model^} Agent Configuration
# This file contains ${model}-specific settings and references shared context
context:
  include:
    - $context_path
    - $prefs_path
    - ../.github/CONTRIBUTING.md
    - ../GOVERNANCE.md
inherits_from: "$inherits_path"
---

# ${model^} Agent for Project

## Agent Identity

You are assisting with this Artagon project repository.

## Core Context

All shared preferences and project context are maintained in:
- \`$prefs_path\` - Workflow preferences and standards
- \`$context_path\` - Project structure and recent changes

## ${model^}-Specific Settings

### Model Configuration
# Add ${model}-specific settings here (temperature, tone, tools, etc.)

## Key Reminders

1. **Never commit with AI attribution** - Human authors only
2. **All changes require an issue** - Use issue-driven workflow
3. **Follow semantic commit format** - Enforced by hooks
4. **Update documentation** - Keep docs in sync with code
5. **Test before committing** - Run relevant tests and linters

## See Also

- [Shared Preferences]($prefs_path)
- [Project Context]($context_path)
EOF

  log "Generated $project_file with pointers to shared content"
}

# Create convenience symlinks for model directories
setup_model_directory_links() {
  local model="$1"
  local agent_dir=".agents-$model"

  # Top-level convenience link (.claude -> .agents-claude)
  ensure_symlink "$agent_dir" ".$model" "directory link"

  # Backward compatibility link for Codex
  if [[ "$model" == "codex" ]]; then
    ensure_symlink "$agent_dir" ".agents" "backward compatibility link"
  fi
}

# Create project-specific files with semantic references to shared content
setup_project_files() {
  local model="$1"
  local agent_dir=".agents-$model"
  local shared_path="${SHARED_PATH}"

  mkdir -p "$agent_dir"

  # Generate preferences.md with reference to shared
  local prefs_file="$agent_dir/preferences.md"
  if [[ ! -f "$prefs_file" ]]; then
    if $DRY_RUN; then
      log "[DRY RUN] Would generate $prefs_file with pointer to shared"
    else
      cat > "$prefs_file" <<EOF
# ${model^} Agent Preferences

> **Base guidance:** See [Shared Preferences](../$shared_path/preferences.md)

## Project-Specific Preferences

Add project-specific workflow preferences, coding standards, or ${model}-specific
instructions here. These will be combined with the shared Artagon preferences.

### Example Customizations

- Project-specific naming conventions
- Custom git workflow variations
- Project-specific tools or scripts
- ${model^}-specific temperature or behavior settings

---

**Note:** This file complements the shared preferences. The shared content is
automatically included via pointers in project.md. Add only project-specific
overrides or additions here.
EOF
      log "Generated $prefs_file with reference to shared"
    fi
  else
    log "Skipping $prefs_file (already exists)"
  fi

  # Generate project-context.md with reference to shared
  local context_file="$agent_dir/project-context.md"
  if [[ ! -f "$context_file" ]]; then
    if $DRY_RUN; then
      log "[DRY RUN] Would generate $context_file with pointer to shared"
    else
      cat > "$context_file" <<EOF
# Project Context

> **Base context:** See [Shared Project Context](../$shared_path/project-context.md)

## Project-Specific Context

### Repository Overview

<!-- Describe this specific project -->

### Architecture

<!-- Key architectural decisions -->

### Recent Changes

<!-- Notable recent changes to this project -->

### Dependencies

<!-- Project-specific dependencies and versions -->

### Known Issues

<!-- Current known issues or limitations -->

---

**Note:** This file complements the shared context. The shared content is
automatically included via pointers in project.md. Add only project-specific
context here.
EOF
      log "Generated $context_file with reference to shared"
    fi
  else
    log "Skipping $context_file (already exists)"
  fi
}

# Run bootstrap for a single model
bootstrap_model() {
  local model="$1"

  log ""
  log "Bootstrapping $model agent configuration..."

  # 1. Generate project.md with pointers
  generate_project_md "$model"

  # 2. Create project-specific files with semantic references
  setup_project_files "$model"

  # 3. Create directory-level convenience links
  setup_model_directory_links "$model"
}

# Check structure for a single model
check_model() {
  local model="$1"
  local agent_dir=".agents-$model"
  local status=0

  # Check project.md exists with pointers
  if [[ ! -f "$agent_dir/project.md" ]]; then
    err "Missing $agent_dir/project.md"
    status=1
  else
    # Check for required pointers
    if ! grep -q "context:" "$agent_dir/project.md"; then
      err "$agent_dir/project.md missing 'context:' section"
      status=1
    fi
    if ! grep -q "inherits_from:" "$agent_dir/project.md"; then
      warn "$agent_dir/project.md missing 'inherits_from:' pointer"
    fi
  fi

  # Check project-specific files exist (not symlinks)
  if [[ ! -f "$agent_dir/preferences.md" ]]; then
    warn "Missing $agent_dir/preferences.md (project-specific file)"
  elif [[ -L "$agent_dir/preferences.md" ]]; then
    warn "$agent_dir/preferences.md is a symlink (should be a real file with reference)"
  fi

  if [[ ! -f "$agent_dir/project-context.md" ]]; then
    warn "Missing $agent_dir/project-context.md (project-specific file)"
  elif [[ -L "$agent_dir/project-context.md" ]]; then
    warn "$agent_dir/project-context.md is a symlink (should be a real file with reference)"
  fi

  # Check convenience directory symlinks
  if [[ ! -L ".$model" ]]; then
    warn "Missing convenience symlink: .$model"
  fi

  return $status
}

# Main bootstrap process
run_ensure() {
  local shared_path

  # Initialize submodule if needed
  init_submodule

  # Resolve shared content location
  if ! shared_path="$(resolve_shared_path)"; then
    warn "Shared agent content not found"
    warn "Expected: $SHARED_BASE or $SUBMODULE_SHARED"
    log "Skipping agent bootstrap (this is OK for non-Artagon repos)"
    return 0
  fi

  SHARED_PATH="$shared_path"
  log "Found shared content at: $shared_path"

  # Bootstrap each model
  for model in $MODELS; do
    bootstrap_model "$model"
  done

  log ""
  log "✓ Agent configuration bootstrap complete"
}

# Verification mode
run_check() {
  local shared_path
  local status=0

  # Resolve shared content location
  if ! shared_path="$(resolve_shared_path)"; then
    warn "Shared agent content not found"
    return 0
  fi

  SHARED_PATH="$shared_path"

  # Check each model
  for model in $MODELS; do
    log "Checking $model configuration..."
    check_model "$model" || status=1
  done

  if [[ $status -eq 0 ]]; then
    log "✓ All checks passed"
  else
    err "Some checks failed"
  fi

  return $status
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ensure)
      MODE="ensure"
      ;;
    --check)
      MODE="check"
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --models)
      shift
      MODELS="$1"
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

# Change to repo root
cd "$ROOT_DIR"

# Run requested mode
if [[ "$MODE" == "ensure" ]]; then
  run_ensure
fi

if [[ "$MODE" == "check" ]] || [[ "$MODE" == "ensure" ]]; then
  if ! run_check; then
    exit 1
  fi
fi

exit 0
