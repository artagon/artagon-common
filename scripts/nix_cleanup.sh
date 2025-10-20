#!/usr/bin/env bash
# nix_cleanup.sh - Inspect and optionally fix leftovers from a previous Nix multi-user install.
#
# This script helps prepare a system for a fresh Nix installation by detecting
# and optionally removing leftover files, directories, and volumes from previous
# Nix installations.

set -euo pipefail

SCRIPT_NAME=$(basename "$0")
FIX_MODE=false
ASSUME_YES=false
DRY_RUN=false

# Color output
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

print_usage() {
  cat <<'EOF'
Usage: nix_cleanup.sh [options]

Checks for files and volumes that block a fresh multi-user Nix installation.

Options:
  -f, --fix         Attempt automated cleanup (requires sudo)
  -n, --dry-run     Show what would be done without doing it
  -y, --yes         Assume "yes" to prompts when --fix is used
  -h, --help        Show this help text

Examples:
  # Inspect only (safe, no changes)
  ./nix_cleanup.sh

  # Show what would be cleaned up
  ./nix_cleanup.sh --dry-run

  # Interactive cleanup (prompts for each action)
  sudo ./nix_cleanup.sh --fix

  # Automated cleanup (no prompts)
  sudo ./nix_cleanup.sh --fix --yes

What This Script Checks:
  - Shell configuration backup files (*.backup-before-nix)
  - /nix directory
  - APFS volumes containing "Nix" (macOS only)
  - Nix daemon services (future enhancement)

After cleanup, you can install Nix fresh:
  ./nix_install.sh

EOF
}

info()    { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$*" >&2; }
error()   { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; exit 1; }
success() { printf "${GREEN}[ OK ]${NC} %s\n" "$*"; }

confirm() {
  local prompt=$1
  if $ASSUME_YES || $DRY_RUN; then
    return 0
  fi
  read -r -p "$prompt [y/N]: " reply || return 1
  [[ "$reply" =~ ^[Yy]$ ]]
}

ensure_root_if_fix() {
  if $FIX_MODE && ! $DRY_RUN && [[ $EUID -ne 0 ]]; then
    error "--fix requires sudo/root privileges (use --dry-run to preview without root)"
  fi
}

parse_args() {
  # Try GNU getopt first
  if getopt --test >/dev/null 2>&1; then
    local parsed
    parsed=$(getopt -o fnyh -l fix,dry-run,yes,help -- "$@") || exit 2
    eval set -- "$parsed"
    while true; do
      case "$1" in
        -f|--fix) FIX_MODE=true; shift ;;
        -n|--dry-run) DRY_RUN=true; FIX_MODE=true; shift ;;
        -y|--yes) ASSUME_YES=true; shift ;;
        -h|--help) print_usage; exit 0 ;;
        --) shift; break ;;
        *) break ;;
      esac
    done
  else
    # Portable argument parsing
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -f|--fix) FIX_MODE=true ;;
        -n|--dry-run) DRY_RUN=true; FIX_MODE=true ;;
        -y|--yes) ASSUME_YES=true ;;
        -h|--help) print_usage; exit 0 ;;
        --) shift; break ;;
        -*) error "Unknown option: $1" ;;
        *) break ;;
      esac
      shift
    done
  fi

  if [[ $# -gt 0 ]]; then
    error "Unexpected argument: $1"
  fi
}

backup_files=(
  "/etc/bashrc.backup-before-nix"
  "/etc/bash.bashrc.backup-before-nix"
  "/etc/zshrc.backup-before-nix"
)

handle_backup_files() {
  local found=0
  for file in "${backup_files[@]}"; do
    if [[ -e "$file" ]]; then
      found=$((found + 1))
      local dest="${file%.backup-before-nix}"
      info "Found leftover backup: $file"

      if $FIX_MODE; then
        if $DRY_RUN; then
          info "[DRY RUN] Would restore $file to $dest"
        else
          if [[ -e "$dest" ]]; then
            local ts
            ts=$(date +%Y%m%d%H%M%S)
            local safe_copy="${dest}.nix-cleanup-${ts}"
            cp -p "$dest" "$safe_copy"
            info "Saved current $dest to $safe_copy"
          fi

          if confirm "Restore $file to $dest?"; then
            mv "$file" "$dest"
            success "Moved $file back to $dest"
          else
            warn "Skipped restoring $file"
          fi
        fi
      else
        info "Suggested command: sudo mv \"$file\" \"$dest\""
      fi
    fi
  done

  if [[ $found -eq 0 ]]; then
    success "No backup-before-nix files detected"
  fi
}

check_nix_directory() {
  if [[ -d /nix ]]; then
    warn "/nix directory already exists"

    # Show disk usage
    if command -v du >/dev/null 2>&1; then
      local size
      size=$(du -sh /nix 2>/dev/null | cut -f1 || echo "unknown")
      info "Directory size: $size"
    fi

    if $FIX_MODE; then
      if $DRY_RUN; then
        info "[DRY RUN] Would remove /nix directory"
      else
        if confirm "Remove /nix? (irreversible)"; then
          info "Removing /nix (this may take a while)..."
          if rm -rf /nix; then
            success "Removed /nix"
          else
            error "Failed to remove /nix"
          fi
        else
          warn "Skipped removing /nix"
        fi
      fi
    else
      info "Suggested command: sudo rm -rf /nix"
    fi
  else
    success "/nix directory not present"
  fi
}

detect_apfs_nix_volumes() {
  local volumes=()

  if [[ "$(uname -s)" == "Darwin" ]] && command -v diskutil >/dev/null 2>&1; then
    local diskutil_output
    if ! diskutil_output=$(diskutil apfs list 2>&1); then
      warn "diskutil failed to list APFS volumes: $diskutil_output"
      return 0
    fi

    # Parse diskutil output for Nix volumes
    while IFS= read -r vol; do
      [[ -n "$vol" ]] && volumes+=("$vol")
    done < <(echo "$diskutil_output" | awk '
      /APFS Volume Disk/ {disk=$4}
      /Name: *Nix/ || /Name: *Nix Store/ {if (disk) print disk; disk=""}
    ')

    if (( ${#volumes[@]} > 0 )); then
      warn "Detected Nix APFS volume(s): ${volumes[*]}"

      if $FIX_MODE; then
        for vol in "${volumes[@]}"; do
          if $DRY_RUN; then
            info "[DRY RUN] Would delete APFS volume $vol"
          else
            if confirm "Delete APFS volume $vol with diskutil?"; then
              info "Deleting APFS volume $vol..."
              if diskutil apfs deleteVolume "$vol"; then
                success "Deleted $vol"
              else
                error "diskutil failed for $vol"
              fi
            else
              warn "Skipped deleting $vol"
            fi
          fi
        done
      else
        for vol in "${volumes[@]}"; do
          info "Suggested command: sudo diskutil apfs deleteVolume $vol"
        done
      fi
    else
      success "No APFS volumes mentioning Nix found"
    fi
  else
    info "APFS volume check skipped (not macOS or diskutil unavailable)"
  fi
}

check_nix_daemon() {
  info "Checking for Nix daemon services..."

  local os
  os=$(uname -s)

  case "$os" in
    Darwin)
      # Check for launchd services
      local launchd_files=(
        "/Library/LaunchDaemons/org.nixos.nix-daemon.plist"
        "/Library/LaunchDaemons/org.nixos.darwin-store.plist"
      )

      local found=0
      for plist in "${launchd_files[@]}"; do
        if [[ -f "$plist" ]]; then
          found=$((found + 1))
          warn "Found Nix launchd service: $plist"

          if $FIX_MODE; then
            if $DRY_RUN; then
              info "[DRY RUN] Would unload and remove $plist"
            else
              if confirm "Unload and remove $plist?"; then
                # Try to unload first
                if launchctl unload "$plist" 2>/dev/null; then
                  info "Unloaded $plist"
                fi

                # Remove the file
                if rm -f "$plist"; then
                  success "Removed $plist"
                else
                  warn "Failed to remove $plist"
                fi
              fi
            fi
          else
            info "Suggested commands:"
            info "  sudo launchctl unload $plist"
            info "  sudo rm $plist"
          fi
        fi
      done

      if [[ $found -eq 0 ]]; then
        success "No Nix launchd services found"
      fi
      ;;

    Linux)
      # Check for systemd services
      if command -v systemctl >/dev/null 2>&1; then
        if systemctl list-unit-files | grep -q "nix-daemon"; then
          warn "Found Nix systemd service"

          if $FIX_MODE; then
            if $DRY_RUN; then
              info "[DRY RUN] Would stop and disable nix-daemon.service"
            else
              if confirm "Stop and disable nix-daemon.service?"; then
                systemctl stop nix-daemon.service 2>/dev/null || true
                systemctl disable nix-daemon.service 2>/dev/null || true
                success "Stopped and disabled nix-daemon.service"
              fi
            fi
          else
            info "Suggested commands:"
            info "  sudo systemctl stop nix-daemon.service"
            info "  sudo systemctl disable nix-daemon.service"
          fi
        else
          success "No Nix systemd services found"
        fi
      else
        info "systemctl not available, skipping systemd check"
      fi
      ;;
  esac
}

check_nix_users_groups() {
  info "Checking for Nix build users and groups..."

  local os
  os=$(uname -s)

  # Check for nixbld group
  if getent group nixbld >/dev/null 2>&1 || dscl . -read /Groups/nixbld >/dev/null 2>&1; then
    warn "Found nixbld group"

    if $FIX_MODE; then
      if $DRY_RUN; then
        info "[DRY RUN] Would remove nixbld group and users"
      else
        info "Removing Nix build users/groups requires manual intervention"
        info "See: https://nixos.org/manual/nix/stable/installation/uninstall.html"
      fi
    else
      case "$os" in
        Darwin)
          info "Suggested commands (macOS):"
          info "  for u in \$(dscl . -list /Users | grep nixbld); do"
          info "    sudo dscl . -delete /Users/\$u"
          info "  done"
          info "  sudo dscl . -delete /Groups/nixbld"
          ;;
        Linux)
          info "Suggested commands (Linux):"
          info "  for u in nixbld{1..32}; do"
          info "    sudo userdel \$u 2>/dev/null || true"
          info "  done"
          info "  sudo groupdel nixbld"
          ;;
      esac
    fi
  else
    success "No nixbld group found"
  fi
}

main() {
  parse_args "$@"
  ensure_root_if_fix

  if $DRY_RUN; then
    info "Running in DRY RUN mode (no changes will be made)"
  fi

  info "Starting Nix installer cleanup check"
  echo ""

  handle_backup_files
  echo ""

  check_nix_directory
  echo ""

  detect_apfs_nix_volumes
  echo ""

  check_nix_daemon
  echo ""

  check_nix_users_groups
  echo ""

  if $DRY_RUN; then
    info "Dry run complete. Run without --dry-run to apply changes."
  elif ! $FIX_MODE; then
    info "Run with --fix to attempt automatic cleanup (requires sudo)"
    info "Run with --dry-run to preview changes without root"
  fi

  echo ""
  info "After cleanup, install Nix fresh with:"
  info "  ./nix_install.sh"
}

main "$@"
