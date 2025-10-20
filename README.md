# Artagon Common

Shared infrastructure, scripts, configurations, and templates for all Artagon LLC projects.

## Overview

This repository serves as a centralized collection of common tooling used across the Artagon ecosystem. By consolidating these resources, we ensure consistency, reduce duplication, and simplify maintenance across all projects.

### What's Included

- **Scripts**: Automation for builds, deployments, CI/CD, and development workflows
  - 🆕 **setup-repo.sh**: Unified project setup for Java, C, C++, and Rust
  - Deployment automation for Maven Central and GitHub Packages
  - Branch protection and CI/CD management
- **Templates**: Standardized project files for multiple languages
  - 🆕 **Java**: Maven POM, settings.xml with GitHub Packages
  - 🆕 **C**: CMake, clang-format, code quality configs
  - 🆕 **C++**: CMake with C++23, clang-tidy, modern C++ setup
  - 🆕 **Rust**: Cargo.toml, rustfmt, clippy configurations
- **Nix Flakes**: 🆕 Reproducible build environments for all languages
  - Lock down exact versions of compilers, build tools, and dependencies
  - Consistent development environments across teams and CI/CD
- **Configs**: Shared configuration files for code quality tools
- **Workflows**: Reusable GitHub Actions workflows

## Installation

### As a Git Submodule (Recommended)

The recommended way to use `artagon-common` is as a git submodule:

```bash
# Quick setup (installs to .common/artagon-common)
bash <(curl -fsSL https://raw.githubusercontent.com/artagon/artagon-common/main/scripts/setup-artagon-common.sh)

# Or manually
git submodule add git@github.com:artagon/artagon-common.git .common/artagon-common
git submodule update --init --recursive
```

### Direct Clone

If you prefer not to use submodules:

```bash
git clone git@github.com:artagon/artagon-common.git
```

## Repository Structure

```
artagon-common/
├── scripts/                      # Automation scripts
│   ├── setup-repo.sh            # 🆕 Unified project setup (all languages)
│   ├── auto_create_and_push.sh  # GitHub repository creation and setup
│   ├── setup-artagon-common.sh  # Bootstrap this repo into projects
│   ├── deploy/                  # Deployment automation
│   │   ├── check-deploy-ready.sh    # Pre-deployment validation
│   │   ├── deploy-snapshot.sh       # Deploy snapshot to OSSRH
│   │   ├── nexus-release.sh         # Release from Nexus staging
│   │   └── release.sh               # Full release automation
│   ├── ci/                      # CI/CD and branch protection
│   │   ├── branch-protection-common.sh  # Shared protection functions
│   │   ├── check-branch-protection.sh   # View protection status
│   │   ├── protect-main-branch.sh       # Solo developer protection
│   │   ├── protect-main-branch-strict.sh # Maximum protection
│   │   ├── protect-main-branch-team.sh  # Team collaboration
│   │   └── remove-branch-protection.sh  # Remove protection
│   ├── build/                   # Build-related scripts (future use)
│   └── dev/                     # Development tools (future use)
├── nix/                         # 🆕 Nix flakes for reproducible builds
│   └── templates/
│       ├── java/flake.nix      # Java 25 + Maven
│       ├── c/flake.nix         # C17 + CMake + GCC/Clang
│       ├── cpp/flake.nix       # C++23 + CMake + GCC/Clang
│       └── rust/flake.nix      # Rust stable + Cargo
├── configs/                     # Shared project templates and configs
│   ├── java/
│   │   └── settings.xml        # Maven settings with GitHub Packages
│   ├── c/                      # 🆕 C project templates (CMake + Bazel)
│   │   ├── CMakeLists.txt.template
│   │   ├── .clang-format
│   │   ├── .gitignore.template
│   │   └── bazel/              # Bazel starter files
│   ├── cpp/                    # 🆕 C++ project templates (CMake + Bazel)
│   │   ├── CMakeLists.txt.template
│   │   ├── .clang-format
│   │   ├── .clang-tidy
│   │   ├── .gitignore.template
│   │   └── bazel/              # Bazel starter files
│   ├── rust/                   # 🆕 Rust project templates
│   │   ├── Cargo.toml.template
│   │   ├── rustfmt.toml
│   │   ├── clippy.toml
│   │   ├── .cargo/config.toml
│   │   └── .gitignore.template
│   ├── .editorconfig          # Code style settings
│   └── .gitignore.template     # Generic .gitignore
├── .github/
│   └── workflows/              # 🆕 Reusable GitHub Actions workflows
│       ├── c-ci.yml           # C project CI (build, test, coverage, sanitizers)
│       ├── c-release.yml      # C project releases (DEB, RPM, AppImage, DMG, ZIP)
│       ├── cpp-ci.yml         # C++ project CI (multi-std, sanitizers, coverage)
│       ├── cpp-release.yml    # C++ project releases (all distribution formats)
│       ├── bazel-ci.yml       # 🆕 Bazel project CI (Nix-aware, multi-platform)
│       └── bazel-release.yml  # 🆕 Bazel project releases (multi-platform packaging)
├── .gitignore                  # Git ignore for this repo
└── README.md                   # This file
```

> **Note:** Language templates formerly stored in `templates/` now reside in
> `configs/`. Update any project automation that referenced the legacy paths.

## Available Scripts

### 🆕 Unified Project Setup

#### `setup-repo.sh`

**The recommended way to create new Artagon projects** - automatically sets up a complete project with language-specific templates, Nix integration, and GitHub configuration.

**Supported Languages:**
- **Java** - Maven with JDK 25, GitHub Packages integration
- **C** - CMake with C17, GCC/Clang toolchain
- **C++** - CMake with C++23, modern C++ best practices
- **Rust** - Cargo with stable Rust toolchain

**Features:**
- Creates GitHub repository
- Adds artagon-common as submodule
- Copies language-specific templates and configs
- Optional Nix flake for reproducible builds
- Optional branch protection rules
- Generates README and LICENSE
- Creates initial commit

**Usage:**

```bash
# Java project with Nix
./scripts/setup-repo.sh --type java --name my-api --with-nix

# Private Rust project
./scripts/setup-repo.sh --type rust --name secret-lib --private

# C++ project with branch protection
./scripts/setup-repo.sh --type cpp --name game-engine --branch-protection

# C project for different organization
./scripts/setup-repo.sh --type c --name firmware --owner embedded-team
```

**Options:**
- `--type <java|c|cpp|rust>` - Project language (required)
- `--name <name>` - Project name (required)
- `--owner <org|user>` - GitHub owner (default: artagon)
- `--description <text>` - Project description
- `--private` - Create private repository
- `--public` - Create public repository (default)
- `--build-system <cmake|bazel>` - Build system (default: cmake, for C/C++ only)
- `--with-nix` - Include Nix flake for reproducible builds
- `--branch-protection` - Apply branch protection rules
- `--ssh` - Use SSH protocol (default)
- `--https` - Use HTTPS protocol
- `--force` - Skip confirmation prompts
- `-h, --help` - Show help

### Repository Management

#### `auto_create_and_push.sh`

Automated script to create GitHub repositories, initialize git, and push initial commit.

**Features:**
- Creates GitHub repo via `gh` CLI
- Supports both SSH and HTTPS protocols
- Handles public/private repositories
- Auto-renames `master` branch to `main`
- Configurable commit messages and descriptions

**Usage:**

```bash
# Basic usage
./scripts/auto_create_and_push.sh --repo my-project --public

# With description and custom message
./scripts/auto_create_and_push.sh \
  --repo api-server \
  --private \
  --description "REST API for Artagon platform" \
  --message "Initial commit"

# For organization
./scripts/auto_create_and_push.sh \
  --owner artagon \
  --repo new-service \
  --private
```

**Options:**
- `--repo <name>` - Repository name (required)
- `--owner <org|user>` - GitHub owner (default: current user)
- `--public` - Create public repository (default)
- `--private` - Create private repository
- `--ssh` - Use SSH protocol (default)
- `--https` - Use HTTPS protocol
- `--description <text>` - Repository description
- `--message <text>` - Initial commit message
- `--force` - Skip repo creation if exists
- `--no-prompt` - Non-interactive mode

#### `setup-artagon-common.sh`

Bootstrap script to add artagon-common as a submodule to any project.

**Usage:**

```bash
# Default installation (.common/artagon-common)
./scripts/setup-artagon-common.sh

# Custom path
./scripts/setup-artagon-common.sh tools/common

# Specific branch
./scripts/setup-artagon-common.sh .common/artagon-common develop
```

### Branch Protection

Protect your `main` branch across repositories with flexible, parameterized scripts. Works with any organization, repository, or branch.

#### Quick Start

```bash
# Protect a single repository
./scripts/ci/protect-main-branch.sh --repo artagon-common

# Protect all default repositories
./scripts/ci/protect-main-branch.sh --all

# Protect repository in different organization
./scripts/ci/protect-main-branch.sh --repo my-app --owner mycompany

# Protect custom branch
./scripts/ci/protect-main-branch.sh --repo my-app --branch develop
```

#### Common Parameters

All branch protection scripts support:

| Parameter | Short | Description | Default |
|-----------|-------|-------------|---------|
| `--repo REPO` | `-r` | Repository name (repeatable) | Required* |
| `--owner OWNER` | `-o` | GitHub owner/organization | `artagon` |
| `--branch BRANCH` | `-b` | Branch name to protect | `main` |
| `--all` | `-a` | Process all default repos | - |
| `--force` | `-f` | Skip confirmation prompt | - |
| `--help` | `-h` | Show help message | - |

\* Not required when using `--all`

#### Available Scripts

**`ci/protect-main-branch.sh` - Solo Development ⭐**
Basic protection for solo developers - blocks accidents but allows direct pushes.

```bash
# Single repo
./scripts/ci/protect-main-branch.sh --repo artagon-common

# Multiple repos in your org
./scripts/ci/protect-main-branch.sh --owner myorg --repo app1 --repo app2
```

**Protection:** Blocks force pushes & deletions | Allows direct pushes & admin overrides

**`ci/protect-main-branch-team.sh` - Team Collaboration ⭐**
Balanced protection for teams - requires PR reviews but allows admin emergency access.

```bash
./scripts/ci/protect-main-branch-team.sh --repo artagon-bom
```

**Protection:** Requires 1 PR approval & conversation resolution | Allows admin emergency access

**`ci/protect-main-branch-strict.sh` - Maximum Protection**
Strict protection for compliance environments - enforced for everyone including admins.

```bash
./scripts/ci/protect-main-branch-strict.sh --all
```

**Protection:** Requires PR approval, status checks & linear history | Enforced for admins

**`ci/check-branch-protection.sh` - Status Check**
View current protection settings for all repositories.

```bash
# Check all default repos
./scripts/ci/check-branch-protection.sh --all

# Check specific repo
./scripts/ci/check-branch-protection.sh --repo artagon-common
```

**`remove-branch-protection.sh` - Remove Protection**
Remove all branch protection (use with caution).

```bash
./scripts/ci/remove-branch-protection.sh --repo artagon-common --force
```

#### Advanced Examples

```bash
# Protect multiple repos at once
./scripts/ci/protect-main-branch.sh \
  --repo artagon-common \
  --repo artagon-license \
  --repo artagon-bom

# Work across different organizations
./scripts/ci/protect-main-branch.sh --repo shared-lib --owner org1
./scripts/ci/protect-main-branch.sh --repo shared-lib --owner org2

# Protect non-main branches
./scripts/ci/protect-main-branch.sh --repo api-server --branch develop
./scripts/ci/protect-main-branch.sh --repo api-server --branch release/v1.0

# Automation-friendly (no prompts)
./scripts/ci/protect-main-branch.sh --all --force
```

**📚 Documentation:**
- [Full Guide](docs/BRANCH-PROTECTION.md) - Detailed comparison table and workflows
- [Usage Examples](docs/BRANCH-PROTECTION-USAGE.md) - Complete usage reference with all parameters

### 🆕 GitHub Actions Workflows for C/C++ Projects

Artagon Common provides production-ready, reusable GitHub Actions workflows for C and C++ projects with comprehensive CI/CD and multi-platform packaging.

#### Features

**CI Workflows:**
- ✅ Multi-platform builds (Linux, macOS, Windows)
- ✅ Multiple compilers (GCC, Clang, MSVC)
- ✅ Code coverage with Codecov integration
- ✅ Sanitizers (Address, Undefined, Thread, Memory)
- ✅ Static analysis (clang-tidy, cppcheck)
- ✅ Memory checks (Valgrind)
- ✅ Format validation (clang-format)
- ✅ Automatic Nix detection and usage
- ✅ C++: Multi-standard testing (C++17/20/23)

**Release Workflows:**
- 📦 Debian packages (.deb)
- 📦 RPM packages (.rpm)
- 📦 AppImage (universal Linux)
- 📦 macOS DMG
- 📦 Windows ZIP
- 📦 Source tarballs

#### Quick Start

Projects using `setup-repo.sh` automatically get example workflows configured. To use manually:

**C Project CI** (`.github/workflows/ci.yml`):
```yaml
name: CI
on: [push, pull_request]
jobs:
  ci:
    uses: artagon/artagon-common/.github/workflows/c-ci.yml@main
    with:
      c-standard: '17'
      enable-coverage: true
      enable-sanitizers: true
    secrets: inherit
```

**C++ Project CI** (`.github/workflows/ci.yml`):
```yaml
name: CI
on: [push, pull_request]
jobs:
  ci:
    uses: artagon/artagon-common/.github/workflows/cpp-ci.yml@main
    with:
      cxx-standard: '23'
      test-standards: '17,20,23'  # Test multiple standards
      enable-coverage: true
      enable-sanitizers: true
    secrets: inherit
```

**Release Workflow** (`.github/workflows/release.yml`):
```yaml
name: Release
on:
  push:
    tags: ['v*']
jobs:
  release:
    uses: artagon/artagon-common/.github/workflows/cpp-release.yml@main
    with:
      cxx-standard: '23'
      build-deb: true
      build-rpm: true
      build-appimage: true
      build-macos: true
      build-windows: true
    secrets: inherit
```

#### Workflow Inputs

**CI Workflows:**
- `cmake-options` - Additional CMake configuration options
- `c-standard` / `cxx-standard` - Language standard version
- `test-standards` - (C++ only) Comma-separated standards to test
- `enable-coverage` - Enable code coverage reporting (default: true)
- `enable-sanitizers` - Enable sanitizer builds (default: true)

**Release Workflows:**
- `project-name` - Project name (defaults to repository name)
- `cmake-options` - Additional CMake options
- `c-standard` / `cxx-standard` - Language standard version
- `build-deb` - Build Debian package (default: true)
- `build-rpm` - Build RPM package (default: true)
- `build-appimage` - Build AppImage (default: true)
- `build-macos` - Build macOS DMG (default: true)
- `build-windows` - Build Windows ZIP (default: true)

#### Nix Integration

Workflows automatically detect and use Nix if `flake.nix` exists in your project:
- Installs Nix on CI runners
- Runs builds within `nix develop` environment
- Ensures reproducibility across all platforms
- Falls back to traditional tooling if Nix not present

#### Creating Releases

1. **Tag your release:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Workflow automatically:**
   - Creates GitHub release
   - Builds all package formats
   - Uploads artifacts to release
   - Generates release notes

3. **Download packages** from GitHub Releases page

### 🆕 Bazel Build System Support

Artagon Common now supports Bazel as an alternative build system for C and C++ projects, with full Nix integration and reusable workflows.

#### Why Bazel?

- **Fast builds** - Incremental builds and remote caching
- **Hermetic** - Reproducible builds guaranteed
- **Scalable** - Handles monorepos with thousands of targets
- **Multi-language** - Single build system for polyglot projects
- **Remote execution** - Optional distributed builds

#### Quick Start with Bazel

```bash
# Create C++ project with Bazel
./scripts/setup-repo.sh --type cpp --name my-app --build-system bazel --with-nix

cd my-app

# Build everything
bazel build //...

# Run tests
bazel test //...

# Run binary
bazel run //:main

# Build with sanitizers
bazel build --config=asan //...
```

#### Bazel Configurations

All Bazel projects include pre-configured `.bazelrc` with:

**Build Configs:**
- `release` - Optimized release build (-O3, LTO, stripped)
- `debug` - Debug build with symbols
- `coverage` - Code coverage with lcov

**Sanitizers:**
- `asan` - Address Sanitizer
- `ubsan` - Undefined Behavior Sanitizer
- `tsan` - Thread Sanitizer
- `msan` - Memory Sanitizer (C++ only)

**Features:**
- Hermetic C++ toolchain resolution
- Disk caching enabled
- Color output
- Verbose failures
- Keep-going mode

#### Bazel CI/CD Workflows

**CI Workflow** (`.github/workflows/ci.yml`):
```yaml
name: CI
on: [push, pull_request]
jobs:
  ci:
    uses: artagon/artagon-common/.github/workflows/bazel-ci.yml@main
    with:
      bazel-configs: 'release debug asan ubsan'
      enable-coverage: true
      targets: '//...'
    secrets: inherit
```

**Release Workflow** (`.github/workflows/release.yml`):
```yaml
name: Release
on:
  push:
    tags: ['v*']
jobs:
  release:
    uses: artagon/artagon-common/.github/workflows/bazel-release.yml@main
    with:
      binary-targets: '//:main //cmd:cli'
      create-packages: true
    secrets: inherit
```

#### Workflow Features

**CI:**
- Multi-platform builds (Linux, macOS, Windows)
- Multiple Bazel configurations tested
- Code coverage with Codecov
- Buildifier format checking
- Dependency graph analysis
- Automatic Nix detection and usage

**Release:**
- Linux tarballs and DEB packages
- macOS universal binaries
- Windows ZIP archives
- Source code archives
- Optional container images

#### Nix + Bazel Integration

Workflows automatically detect and use Nix:
```yaml
- name: Build with Nix (if available)
  run: nix develop --command bazel build //...
```

Projects with `flake.nix` get:
- Bazel 7.0 pre-installed
- Bazelisk for version management
- All build tools hermetically managed
- Reproducible builds guaranteed

#### Bazel Project Templates

Templates include:

**Modern Bzlmod (Bazel 6.0+):**
- `MODULE.bazel` - Dependency management
- `.bazelversion` - Pin Bazel version
- `.bazelrc` - Configuration presets
- `BUILD.bazel` - Build targets

**Legacy Support:**
- `WORKSPACE.bazel` - For Bazel <6.0
- Compatible with existing workflows

**Example BUILD.bazel:**
```python
cc_library(
    name = "mylib",
    srcs = glob(["src/**/*.cpp"]),
    hdrs = glob(["include/**/*.hpp"]),
    includes = ["include"],
    deps = ["@com_google_absl//absl/strings"],
)

cc_binary(
    name = "main",
    srcs = ["src/main.cpp"],
    deps = [":mylib"],
)

cc_test(
    name = "mylib_test",
    srcs = glob(["tests/**/*_test.cpp"]),
    deps = [
        ":mylib",
        "@googletest//:gtest_main",
    ],
)
```

### 🆕 Nix Integration for Reproducible Builds

Artagon Common provides Nix flakes for all supported languages, ensuring fully reproducible development environments and builds.

#### Why Nix?

- **True reproducibility** - Exact same environment on every machine
- **Version control** - Lock down JDK, compilers, build tools, and system libraries
- **Polyglot support** - Manage Java, C/C++, and Rust toolchains seamlessly
- **Zero conflicts** - No more "works on my machine" issues
- **CI/CD consistency** - Identical environment locally and in GitHub Actions

#### Quick Start with Nix

```bash
# Install Nix (if not already installed)
curl -L https://nixos.org/nix/install | sh

# Enable flakes (add to ~/.config/nix/nix.conf)
experimental-features = nix-command flakes

# Create a project with Nix support
./scripts/setup-repo.sh --type rust --name my-project --with-nix

# Enter development shell
cd my-project
nix develop

# Or use direnv for automatic activation
echo "use flake" > .envrc
direnv allow
```

#### Available Nix Templates

Each language has a pre-configured Nix flake with:

**Java (nix/templates/java/flake.nix)**
- JDK 25 (Temurin distribution)
- Maven 3.x
- GitHub CLI (`gh`)
- GPG for artifact signing
- Pre-configured environment variables for GitHub Packages and OSSRH

**C (nix/templates/c/flake.nix)**
- GCC 13 and Clang 18
- CMake and Make/Ninja
- GDB and Valgrind for debugging
- clang-format and clang-tidy
- Doxygen for documentation

**C++ (nix/templates/cpp/flake.nix)**
- GCC 13 and Clang 18 with C++23 support
- CMake, Make, Ninja, and Meson
- GDB and LLDB debuggers
- clang-format, clang-tidy, and cppcheck
- Optional Google Test and Catch2

**Rust (nix/templates/rust/flake.nix)**
- Rust stable toolchain (customizable to nightly/specific version)
- Cargo with rust-analyzer, clippy, rustfmt
- cargo-watch, cargo-edit, cargo-audit, cargo-deny
- Cross-compilation support
- WASM target support

#### Using Nix in Existing Projects

```bash
# Copy appropriate flake to your project
cp .common/artagon-common/nix/templates/java/flake.nix .

# Enter development environment
nix develop

# Build with Nix (for CI/CD)
nix build
```

#### direnv Integration

For automatic environment activation when entering project directories:

```bash
# Install direnv
# macOS: brew install direnv
# Linux: apt-get install direnv

# Add to shell rc file (~/.bashrc, ~/.zshrc)
eval "$(direnv hook bash)"  # or zsh

# In your project
echo "use flake" > .envrc
direnv allow

# Now the Nix environment activates automatically!
```

## Using in Your Projects

### Option 1: Submodule (Recommended)

Add as a submodule and reference scripts:

```bash
# Add submodule
git submodule add git@github.com:artagon/artagon-common.git .common/artagon-common

# Use scripts
.common/artagon-common/scripts/auto_create_and_push.sh --help

# Or symlink to project root
ln -s .common/artagon-common/scripts/auto_create_and_push.sh ./scripts/
```

### Option 2: Copy Scripts

Copy individual scripts to your project:

```bash
cp .common/artagon-common/scripts/auto_create_and_push.sh ./scripts/
```

### Option 3: Add to PATH

For personal use, symlink to your ~/bin:

```bash
ln -s ~/Projects/Artagon/artagon-common/scripts/auto_create_and_push.sh ~/bin/
```

## Updating

### Update Submodule to Latest

```bash
# From your project root
cd .common/artagon-common
git checkout main
git pull origin main
cd ../..
git add .common/artagon-common
git commit -m "Update artagon-common to latest"
```

### Or use git submodule command

```bash
git submodule update --remote .common/artagon-common
git add .common/artagon-common
git commit -m "Update artagon-common submodule"
```

### Automated Updates

Use the provided GitHub Actions workflow to automatically update submodules weekly:

```yaml
# .github/workflows/update-common.yml
name: Update Common Scripts

on:
  schedule:
    - cron: "0 6 * * 1"  # Weekly on Monday
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true

      - name: Update submodule
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git submodule update --remote .common/artagon-common

      - name: Check for changes
        id: changes
        run: |
          if git diff --quiet; then
            echo "changed=false" >> $GITHUB_OUTPUT
          else
            echo "changed=true" >> $GITHUB_OUTPUT
          fi

      - name: Create Pull Request
        if: steps.changes.outputs.changed == 'true'
        uses: peter-evans/create-pull-request@v5
        with:
          commit-message: "Update artagon-common submodule"
          title: "Update artagon-common to latest"
          body: "Automated update of artagon-common submodule"
          branch: update-artagon-common
```

## Versioning

This repository follows semantic versioning:

- **Major versions**: Breaking changes to scripts or APIs
- **Minor versions**: New features, backward compatible
- **Patch versions**: Bug fixes

### Pinning to Specific Version

```bash
# Pin to specific tag
cd .common/artagon-common
git checkout v1.2.3
cd ../..
git add .common/artagon-common
git commit -m "Pin artagon-common to v1.2.3"
```

## Contributing

### Adding New Scripts

1. Create script in appropriate subdirectory (`scripts/build/`, `scripts/ci/`, etc.)
2. Make executable: `chmod +x scripts/your-script.sh`
3. Add documentation to this README
4. Test thoroughly
5. Submit pull request

### Script Guidelines

- Use `#!/usr/bin/env bash` shebang
- Include `set -euo pipefail` for safety
- Add help text and usage examples
- Handle errors gracefully
- Support `--help` flag
- Document all options and flags

### Example Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

# Script description
#
# Usage:
#   ./script-name.sh [options]
#
# Options:
#   --option1 <value>  Description
#   --option2          Description
#   -h, --help         Show help

# Help text
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat << 'EOF'
Usage: script-name.sh [options]

Description of what this script does.

Options:
  --option1 <value>  Description
  --option2          Description
  -h, --help         Show this help
EOF
  exit 0
fi

# Script logic here
echo "Script running..."
```

## FAQ

### Q: Should I commit the submodule or just reference it?

**A:** Commit the submodule reference (the `.gitmodules` file and the submodule directory entry). This allows others to clone your repo and automatically get the common scripts.

### Q: How do I update to the latest version?

**A:** Run `git submodule update --remote .common/artagon-common` from your project root, then commit the change.

### Q: Can I use only specific scripts?

**A:** Yes! You can copy individual scripts to your project or symlink them. However, using as a submodule ensures you get updates easily.

### Q: What if I need a different version than other projects?

**A:** That's fine! Each project's submodule can point to different commits/tags. This is actually a feature of submodules.

### Q: How do I contribute improvements?

**A:** Fork this repo, make your changes, test them, and submit a pull request. See Contributing section above.

## Support

For questions or issues:

- **General inquiries**: info@artagon.com
- **Technical issues**: Create an issue in this repository
- **Security concerns**: security@artagon.com

## License

Copyright (C) 2025 Artagon LLC. All rights reserved.

See [LICENSE](LICENSE) for details.

---

**Related Repositories:**
- [artagon-license](https://github.com/artagon/artagon-license) - Dual licensing bundle
- [artagon-parent](https://github.com/artagon/artagon-parent) - Maven parent POM
- [artagon-bom](https://github.com/artagon/artagon-bom) - Bill of Materials

**Maintainers:**
- Artagon DevOps Team <devops@artagon.com>

**New in Latest Release:**
- 🆕 Multi-language support (Java, C, C++, Rust)
- 🆕 Nix flakes for reproducible builds with Bazel support
- 🆕 Bazel build system support for C/C++ projects
- 🆕 Reusable Bazel CI/CD workflows with Nix integration
- 🆕 Unified setup-repo.sh script with build system selection
- 🆕 Language-specific templates and configs (CMake + Bazel)
- 🆕 Reusable GitHub Actions workflows for C/C++
- 🆕 Multi-platform packaging (DEB, RPM, AppImage, DMG, ZIP)
- 🆕 Comprehensive CI with coverage, sanitizers, static analysis
- Maven settings.xml with GitHub Packages

---

Last updated: 2025-10-18
