#!/usr/bin/env bash
# nix_install.sh - Comprehensive Nix installation script
#
# Installs Nix package manager with sensible defaults and optional features.
# Supports both macOS and Linux with multiple installation methods.

set -euo pipefail

SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
INSTALL_METHOD="determinate"  # "determinate" or "official"
ENABLE_FLAKES=true
INSTALL_DIRENV=false
AUTO_YES=false
UNATTENDED=false

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

# Output functions
info()    { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
success() { printf "${GREEN}[ OK ]${NC} %s\n" "$*"; }
warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$*" >&2; }
error()   { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; exit 1; }

print_usage() {
  cat <<'EOF'
Usage: nix_install.sh [options]

Installs Nix package manager with best practices for development.

Options:
  -m, --method METHOD    Installation method: "determinate" (default) or "official"
  -d, --direnv           Also install and configure direnv
  -y, --yes              Assume yes to all prompts
  -u, --unattended       Unattended mode (implies --yes, disables flakes)
  -h, --help             Show this help text

Installation Methods:
  determinate            Determinate Systems installer (recommended)
                         - Faster, more reliable uninstall
                         - Better macOS support
                         - https://zero-to-nix.com/

  official               Official Nix installer
                         - Traditional installation method
                         - https://nixos.org/

Examples:
  # Install with Determinate Systems installer (recommended)
  ./nix_install.sh

  # Install with official installer
  ./nix_install.sh --method official

  # Install with direnv integration
  ./nix_install.sh --direnv

  # Unattended CI installation
  ./nix_install.sh --unattended

Post-Installation:
  Source your shell config or start a new terminal session:
    source ~/.bashrc                    # Bash
    source ~/.zshrc                     # Zsh
    source ~/.config/fish/config.fish   # Fish

  Verify installation:
    nix --version
    nix-shell --version

  Try a development shell:
    cd your-project
    nix develop

Supported Shells:
  - Bash (~/.bashrc)
  - Zsh (~/.zshrc)
  - Fish (~/.config/fish/config.fish)

EOF
}

confirm() {
  local prompt=$1
  if $AUTO_YES; then
    return 0
  fi
  read -r -p "$prompt [y/N]: " reply || return 1
  [[ "$reply" =~ ^[Yy]$ ]]
}

parse_args() {
  # Try GNU getopt first
  if getopt --test >/dev/null 2>&1; then
    local parsed
    parsed=$(getopt -o m:dyuh -l method:,direnv,yes,unattended,help -- "$@") || exit 2
    eval set -- "$parsed"
    while true; do
      case "$1" in
        -m|--method) INSTALL_METHOD="$2"; shift 2 ;;
        -d|--direnv) INSTALL_DIRENV=true; shift ;;
        -y|--yes) AUTO_YES=true; shift ;;
        -u|--unattended) UNATTENDED=true; AUTO_YES=true; ENABLE_FLAKES=false; shift ;;
        -h|--help) print_usage; exit 0 ;;
        --) shift; break ;;
        *) break ;;
      esac
    done
  else
    # Portable argument parsing
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -m|--method)
          if [[ -z "${2:-}" || "$2" == -* ]]; then
            error "Option $1 requires an argument"
          fi
          INSTALL_METHOD="$2"
          shift 2
          ;;
        -d|--direnv) INSTALL_DIRENV=true; shift ;;
        -y|--yes) AUTO_YES=true; shift ;;
        -u|--unattended) UNATTENDED=true; AUTO_YES=true; ENABLE_FLAKES=false; shift ;;
        -h|--help) print_usage; exit 0 ;;
        --) shift; break ;;
        -*) error "Unknown option: $1" ;;
        *) break ;;
      esac
    done
  fi

  if [[ $# -gt 0 ]]; then
    error "Unexpected argument: $1"
  fi

  # Validate installation method
  case "$INSTALL_METHOD" in
    determinate|official) ;;
    *) error "Invalid method: $INSTALL_METHOD (must be 'determinate' or 'official')" ;;
  esac
}

detect_os() {
  local os
  os=$(uname -s)
  case "$os" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    *) error "Unsupported operating system: $os" ;;
  esac
}

check_prerequisites() {
  info "Checking prerequisites..."

  # Check for curl
  if ! command -v curl >/dev/null 2>&1; then
    error "curl is required but not installed"
  fi

  # Check if Nix is already installed
  if command -v nix >/dev/null 2>&1; then
    warn "Nix is already installed: $(nix --version 2>&1 | head -n1)"
    if ! confirm "Reinstall anyway?"; then
      exit 0
    fi
  fi

  # Check for existing /nix directory
  if [[ -d /nix ]]; then
    warn "/nix directory already exists"
    info "Consider running nix_cleanup.sh first"
    if ! confirm "Continue anyway?"; then
      exit 0
    fi
  fi

  success "Prerequisites check passed"
}

install_nix_determinate() {
  info "Installing Nix using Determinate Systems installer..."

  local install_cmd="curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"

  if $UNATTENDED; then
    install_cmd="$install_cmd --no-confirm"
  fi

  info "Running: $install_cmd"

  if eval "$install_cmd"; then
    success "Nix installed successfully via Determinate Systems"
  else
    error "Installation failed"
  fi
}

install_nix_official() {
  info "Installing Nix using official installer..."

  local install_cmd="sh <(curl -L https://nixos.org/nix/install)"

  local os
  os=$(detect_os)

  if [[ "$os" == "macos" ]]; then
    install_cmd="$install_cmd --daemon"
    info "Using multi-user installation (recommended for macOS)"
  elif [[ "$os" == "linux" ]]; then
    if [[ $EUID -eq 0 ]]; then
      install_cmd="$install_cmd --daemon"
      info "Using multi-user installation (running as root)"
    else
      if confirm "Use multi-user installation? (requires sudo)"; then
        install_cmd="$install_cmd --daemon"
      else
        info "Using single-user installation"
      fi
    fi
  fi

  if $UNATTENDED; then
    install_cmd="$install_cmd --yes"
  fi

  info "Running: $install_cmd"

  if eval "$install_cmd"; then
    success "Nix installed successfully via official installer"
  else
    error "Installation failed"
  fi
}

configure_nix() {
  info "Configuring Nix..."

  local nix_conf_dir="$HOME/.config/nix"
  local nix_conf="$nix_conf_dir/nix.conf"

  mkdir -p "$nix_conf_dir"

  if $ENABLE_FLAKES; then
    info "Enabling experimental features (flakes, nix-command)..."

    if [[ -f "$nix_conf" ]]; then
      # Check if already configured
      if grep -q "experimental-features" "$nix_conf"; then
        warn "experimental-features already configured in $nix_conf"
      else
        echo "experimental-features = nix-command flakes" >> "$nix_conf"
        success "Added experimental features to $nix_conf"
      fi
    else
      cat > "$nix_conf" <<'EOF'
# Nix configuration
experimental-features = nix-command flakes
EOF
      success "Created $nix_conf with experimental features enabled"
    fi
  fi

  # Set up shell integration
  setup_shell_integration

  success "Nix configuration complete"
}

setup_shell_integration() {
  info "Setting up shell integration..."

  local os
  os=$(detect_os)

  local nix_profile_script
  if [[ "$os" == "macos" ]]; then
    nix_profile_script="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  else
    nix_profile_script="$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi

  # Check if the Nix profile script exists
  if [[ ! -f "$nix_profile_script" ]]; then
    warn "Nix profile script not found at $nix_profile_script"
    return 0
  fi

  local configured=0

  # Configure Bash
  if [[ -f "$HOME/.bashrc" ]]; then
    if ! grep -q "$nix_profile_script" "$HOME/.bashrc"; then
      info "Adding Nix to ~/.bashrc"
      cat >> "$HOME/.bashrc" <<EOF

# Nix
if [ -e $nix_profile_script ]; then
  . $nix_profile_script
fi
EOF
      success "Added Nix to ~/.bashrc"
      configured=$((configured + 1))
    else
      info "Nix already configured in ~/.bashrc"
    fi
  fi

  # Configure Zsh
  if [[ -f "$HOME/.zshrc" ]]; then
    if ! grep -q "$nix_profile_script" "$HOME/.zshrc"; then
      info "Adding Nix to ~/.zshrc"
      cat >> "$HOME/.zshrc" <<EOF

# Nix
if [ -e $nix_profile_script ]; then
  . $nix_profile_script
fi
EOF
      success "Added Nix to ~/.zshrc"
      configured=$((configured + 1))
    else
      info "Nix already configured in ~/.zshrc"
    fi
  fi

  # Configure Fish
  local fish_config="$HOME/.config/fish/config.fish"
  if command -v fish >/dev/null 2>&1 || [[ -d "$HOME/.config/fish" ]]; then
    mkdir -p "$HOME/.config/fish"
    if [[ ! -f "$fish_config" ]] || ! grep -q "$nix_profile_script" "$fish_config"; then
      info "Adding Nix to $fish_config"
      cat >> "$fish_config" <<EOF

# Nix
if test -e $nix_profile_script
  source $nix_profile_script
end
EOF
      success "Added Nix to $fish_config"
      configured=$((configured + 1))
    else
      info "Nix already configured in $fish_config"
    fi
  fi

  if [[ $configured -eq 0 ]]; then
    info "No shell configuration files updated (Nix already configured)"
  fi
}

install_direnv() {
  if ! $INSTALL_DIRENV; then
    return 0
  fi

  info "Installing direnv..."

  if command -v direnv >/dev/null 2>&1; then
    warn "direnv is already installed"
    return 0
  fi

  # Source Nix profile to make nix-env available
  if [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
    # shellcheck source=/dev/null
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi

  if command -v nix-env >/dev/null 2>&1; then
    if nix-env -iA nixpkgs.direnv; then
      success "direnv installed via Nix"
      configure_direnv
    else
      warn "Failed to install direnv via nix-env"
    fi
  else
    warn "nix-env not available, skipping direnv installation"
    info "Install direnv manually: nix-env -iA nixpkgs.direnv"
  fi
}

configure_direnv() {
  info "Configuring direnv..."

  local configured=0

  # Configure Bash
  if [[ -f "$HOME/.bashrc" ]]; then
    if ! grep -q "direnv hook bash" "$HOME/.bashrc"; then
      info "Adding direnv to ~/.bashrc"
      cat >> "$HOME/.bashrc" <<'EOF'

# direnv
eval "$(direnv hook bash)"
EOF
      success "Added direnv hook to ~/.bashrc"
      configured=$((configured + 1))
    else
      info "direnv already configured in ~/.bashrc"
    fi
  fi

  # Configure Zsh
  if [[ -f "$HOME/.zshrc" ]]; then
    if ! grep -q "direnv hook zsh" "$HOME/.zshrc"; then
      info "Adding direnv to ~/.zshrc"
      cat >> "$HOME/.zshrc" <<'EOF'

# direnv
eval "$(direnv hook zsh)"
EOF
      success "Added direnv hook to ~/.zshrc"
      configured=$((configured + 1))
    else
      info "direnv already configured in ~/.zshrc"
    fi
  fi

  # Configure Fish
  local fish_config="$HOME/.config/fish/config.fish"
  if command -v fish >/dev/null 2>&1 || [[ -d "$HOME/.config/fish" ]]; then
    mkdir -p "$HOME/.config/fish"
    if [[ ! -f "$fish_config" ]] || ! grep -q "direnv hook fish" "$fish_config"; then
      info "Adding direnv to $fish_config"
      cat >> "$fish_config" <<'EOF'

# direnv
direnv hook fish | source
EOF
      success "Added direnv hook to $fish_config"
      configured=$((configured + 1))
    else
      info "direnv already configured in $fish_config"
    fi
  fi

  if [[ $configured -eq 0 ]]; then
    info "No shell configuration files updated (direnv already configured)"
  fi
}

verify_installation() {
  info "Verifying Nix installation..."

  # Source Nix profile for this script
  if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck source=/dev/null
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  elif [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
    # shellcheck source=/dev/null
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi

  if ! command -v nix >/dev/null 2>&1; then
    error "Nix command not found after installation"
  fi

  local nix_version
  nix_version=$(nix --version 2>&1 | head -n1)
  success "Nix is installed: $nix_version"

  if $ENABLE_FLAKES; then
    info "Testing flakes support..."
    if nix flake --version >/dev/null 2>&1; then
      success "Flakes are enabled"
    else
      warn "Flakes not working - you may need to restart your shell"
    fi
  fi

  if $INSTALL_DIRENV && command -v direnv >/dev/null 2>&1; then
    local direnv_version
    direnv_version=$(direnv --version 2>&1)
    success "direnv is installed: $direnv_version"
  fi
}

print_next_steps() {
  cat <<EOF

${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${GREEN}Nix installation complete!${NC}
${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

${BLUE}Next steps:${NC}

1. Start a new terminal session or source your shell config:
   ${YELLOW}source ~/.bashrc${NC}   (Bash)
   ${YELLOW}source ~/.zshrc${NC}    (Zsh)
   ${YELLOW}source ~/.config/fish/config.fish${NC}  (Fish)

2. Verify Nix is working:
   ${YELLOW}nix --version${NC}

3. Try a simple example:
   ${YELLOW}nix-shell -p hello${NC}
   ${YELLOW}hello${NC}

4. Use a development shell in a project with flake.nix:
   ${YELLOW}cd your-project${NC}
   ${YELLOW}nix develop${NC}

${BLUE}Resources:${NC}
  - Zero to Nix: https://zero-to-nix.com/
  - Nix Manual: https://nixos.org/manual/nix/stable/
  - Nix Pills: https://nixos.org/guides/nix-pills/

${BLUE}Uninstallation:${NC}
EOF

  case "$INSTALL_METHOD" in
    determinate)
      echo "  ${YELLOW}/nix/nix-installer uninstall${NC}"
      ;;
    official)
      echo "  See: https://nixos.org/manual/nix/stable/installation/uninstall.html"
      ;;
  esac

  echo ""
}

main() {
  parse_args "$@"

  info "Nix Installation Script"
  info "Method: $INSTALL_METHOD"
  info "OS: $(detect_os)"

  check_prerequisites

  case "$INSTALL_METHOD" in
    determinate) install_nix_determinate ;;
    official) install_nix_official ;;
  esac

  configure_nix
  install_direnv
  verify_installation
  print_next_steps
}

main "$@"
