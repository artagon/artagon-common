# Artagon Common

Shared infrastructure, scripts, configurations, and templates for all Artagon LLC projects.

## Overview

This repository serves as a centralized collection of common tooling used across the Artagon ecosystem. By consolidating these resources, we ensure consistency, reduce duplication, and simplify maintenance across all projects.

### What's Included

- **Scripts**: Automation for builds, deployments, CI/CD, and development workflows
  - 🆕 **repo_setup.sh**: Unified project setup for Java, C, C++, and Rust
  - Deployment automation for Maven Central and GitHub Packages
  - Branch protection and CI/CD management
- **Templates**: Standardized project files for multiple languages
  - 🆕 **Java**: Maven POM, settings.xml with GitHub Packages
  - 🆕 **C**: CMake, clang-format, code quality configs
  - 🆕 **C++**: CMake with C++23, clang-tidy, modern C++ setup
  - 🆕 **Rust**: Cargo.toml, rustfmt, clippy configurations
- **Nix Integration**: See [artagon-nix](https://github.com/artagon/artagon-nix) for reproducible development environments
  - Lock down exact versions of compilers, build tools, and dependencies
  - Consistent development environments across teams and CI/CD
- **Configs**: Shared configuration files for code quality tools
- **Workflows**: See [artagon-workflows](https://github.com/artagon/artagon-workflows) for reusable GitHub Actions workflows

## Installation

### As a Git Submodule (Recommended)

The recommended way to use `artagon-common` is as a git submodule:

```bash
# Quick setup (installs to .common/artagon-common)
bash <(curl -fsSL https://raw.githubusercontent.com/artagon/artagon-common/main/scripts/repo_add_artagon_common.sh)

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
│   ├── repo_setup.sh            # 🆕 Unified project setup (all languages)
│   ├── gh_auto_create_and_push.sh  # GitHub repository creation and setup
│   ├── repo_add_artagon_common.sh  # Bootstrap this repo into projects
│   ├── deploy/                  # Deployment automation
│   │   ├── mvn_check_ready.sh       # Pre-deployment validation
│   │   ├── mvn_deploy_snapshot.sh   # Deploy snapshot to OSSRH
│   │   ├── mvn_release_nexus.sh     # Release from Nexus staging
│   │   └── mvn_release.sh           # Full release automation
│   ├── ci/                      # CI/CD and branch protection
│   │   ├── gh_branch_protection_common.sh  # Shared protection functions
│   │   ├── gh_check_branch_protection.sh   # View protection status
│   │   ├── gh_protect_main.sh       # Solo developer protection
│   │   ├── gh_protect_main_strict.sh # Maximum protection
│   │   ├── gh_protect_main_team.sh  # Team collaboration
│   │   └── gh_remove_branch_protection.sh  # Remove protection
│   ├── build/                   # Build-related scripts (future use)
│   └── dev/                     # Development tools (future use)
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
│   └── workflows/              # Workflows that run on this repo (tests, validation)
├── .gitignore                  # Git ignore for this repo
└── README.md                   # This file
```

> **Note:** Language templates formerly stored in `templates/` now reside in
> `configs/`. Update any project automation that referenced the legacy paths.

## Available Scripts

### 🆕 Unified Project Setup

#### `repo_setup.sh`
### 🧰 Artagon CLI

A Python-based command line interface consolidates release and deployment tasks. It lives at `scripts/artagon` and supports a dry-run mode for safe experimentation.

```bash
# Show available commands
scripts/artagon --help

# Run a Java release
scripts/artagon java release run --version 1.2.3
# When running outside a release-* branch
scripts/artagon java release run --version 1.2.3 --allow-branch-mismatch

# Publish a SNAPSHOT build
scripts/artagon java snapshot publish

# Update or verify dependency security baselines
scripts/artagon java security update
scripts/artagon java security verify

# Apply branch protection to a release branch
scripts/artagon java gh protect --branch release-1.2.3
```

Add `--dry-run` (or `-n`) before the command to inspect actions without executing them.

### ⚙️ CLI Configuration

The CLI reads defaults from `.artagonrc` (TOML format) at the repository root. Example:

```toml
[defaults]
language = "java"
owner = "artagon"
repo = "artagon-common"
```

Override values to match your GitHub organisation or preferred language; environment variable `ARTAGON_CONFIG` can point to an alternate configuration file if needed.


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
./scripts/repo_setup.sh --type java --name my-api --with-nix

# Private Rust project
./scripts/repo_setup.sh --type rust --name secret-lib --private

# C++ project with branch protection
    ./scripts/repo_setup.sh --type cpp --name game-engine --branch-protection

    # C project for different organization
    ./scripts/repo_setup.sh --type c --name firmware --owner embedded-team
```

### `gh_sync_codex.sh`

Keeps `codex/` overlays aligned with the shared Codex guidance distributed with `artagon-common`.

- The script links `codex/shared/` to the shared preferences, stubs local overlays, and wires `.codex/` for tools that rely on it.
- Git hooks (`pre-commit`, `post-checkout`, `post-merge`) run it automatically, and `repo_setup.sh` invokes it when bootstrapping a new repository.
- Run manually with `./scripts/gh_sync_codex.sh --ensure` to repair links or `--check` to validate structure.

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

#### `gh_auto_create_and_push.sh`

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
./scripts/gh_auto_create_and_push.sh --repo my-project --public

# With description and custom message
./scripts/gh_auto_create_and_push.sh \
  --repo api-server \
  --private \
  --description "REST API for Artagon platform" \
  --message "Initial commit"

# For organization
./scripts/gh_auto_create_and_push.sh \
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

#### `repo_add_artagon_common.sh`

Bootstrap script to add artagon-common as a submodule to any project.

**Usage:**

```bash
# Default installation (.common/artagon-common)
./scripts/repo_add_artagon_common.sh

# Custom path
./scripts/repo_add_artagon_common.sh tools/common

# Specific branch
./scripts/repo_add_artagon_common.sh .common/artagon-common develop
```

### Branch Protection

Protect your `main` branch across repositories with flexible, parameterized scripts. Works with any organization, repository, or branch.

#### Quick Start

```bash
# Protect a single repository
./scripts/ci/gh_protect_main.sh --repo artagon-common

# Protect all default repositories
./scripts/ci/gh_protect_main.sh --all

# Protect repository in different organization
./scripts/ci/gh_protect_main.sh --repo my-app --owner mycompany

# Protect custom branch
./scripts/ci/gh_protect_main.sh --repo my-app --branch develop
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

**`ci/gh_protect_main.sh` - Solo Development ⭐**
Basic protection for solo developers - blocks accidents but allows direct pushes.

```bash
# Single repo
./scripts/ci/gh_protect_main.sh --repo artagon-common

# Multiple repos in your org
./scripts/ci/gh_protect_main.sh --owner myorg --repo app1 --repo app2
```

**Protection:** Blocks force pushes & deletions | Allows direct pushes & admin overrides

**`ci/gh_protect_main_team.sh` - Team Collaboration ⭐**
Balanced protection for teams - requires PR reviews but allows admin emergency access.

```bash
./scripts/ci/gh_protect_main_team.sh --repo artagon-bom
```

**Protection:** Requires 1 PR approval & conversation resolution | Allows admin emergency access

**`ci/gh_protect_main_strict.sh` - Maximum Protection**
Strict protection for compliance environments - enforced for everyone including admins.

```bash
./scripts/ci/gh_protect_main_strict.sh --all
```

**Protection:** Requires PR approval, status checks & linear history | Enforced for admins

**`ci/gh_check_branch_protection.sh` - Status Check**
View current protection settings for all repositories.

```bash
# Check all default repos
./scripts/ci/gh_check_branch_protection.sh --all

# Check specific repo
./scripts/ci/gh_check_branch_protection.sh --repo artagon-common
```

**`gh_remove_branch_protection.sh` - Remove Protection**
Remove all branch protection (use with caution).

```bash
./scripts/ci/gh_remove_branch_protection.sh --repo artagon-common --force
```

#### Advanced Examples

```bash
# Protect multiple repos at once
./scripts/ci/gh_protect_main.sh \
  --repo artagon-common \
  --repo artagon-license \
  --repo artagon-bom

# Work across different organizations
./scripts/ci/gh_protect_main.sh --repo shared-lib --owner org1
./scripts/ci/gh_protect_main.sh --repo shared-lib --owner org2

# Protect non-main branches
./scripts/ci/gh_protect_main.sh --repo api-server --branch develop
./scripts/ci/gh_protect_main.sh --repo api-server --branch release/v1.0

# Automation-friendly (no prompts)
./scripts/ci/gh_protect_main.sh --all --force
```

**📚 Documentation:**
- [Full Guide](docs/BRANCH-PROTECTION.md) - Detailed comparison table and workflows
- [Usage Examples](docs/BRANCH-PROTECTION-USAGE.md) - Complete usage reference with all parameters

### 🆕 GitHub Actions Workflows for C/C++ Projects

**Workflows have moved to [artagon-workflows](https://github.com/artagon/artagon-workflows)**

Artagon provides production-ready, reusable GitHub Actions workflows for C and C++ projects with comprehensive CI/CD and multi-platform packaging.

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

Projects using `repo_setup.sh` automatically get example workflows configured. To use manually:

**C Project CI** (`.github/workflows/ci.yml`):
```yaml
name: CI
on: [push, pull_request]
jobs:
  ci:
    uses: artagon/artagon-workflows/.github/workflows/c-ci.yml@v1
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
    uses: artagon/artagon-workflows/.github/workflows/cpp-ci.yml@v1
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
    uses: artagon/artagon-workflows/.github/workflows/cpp-release.yml@v1
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
./scripts/repo_setup.sh --type cpp --name my-app --build-system bazel --with-nix

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
    uses: artagon/artagon-workflows/.github/workflows/bazel-ci.yml@v1
    with:
      bazel-configs: 'release,debug,asan,ubsan'
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
    uses: artagon/artagon-workflows/.github/workflows/bazel-release.yml@v1
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

For reproducible development environments, see [artagon-nix](https://github.com/artagon/artagon-nix).

Artagon Nix provides Nix flake templates for all supported languages (Java, C, C++, Rust), ensuring fully reproducible development environments and builds.

#### Why Nix?

- **True reproducibility** - Exact same environment on every machine
- **Version control** - Lock down exact versions of compilers, build tools, and system libraries
- **Polyglot support** - Manage Java, C/C++, and Rust toolchains seamlessly
- **Zero conflicts** - No more "works on my machine" issues
- **CI/CD consistency** - Identical environment locally and in GitHub Actions

#### Quick Start

```bash
# Create a project with Nix support (automatically adds artagon-nix submodule)
./scripts/repo_setup.sh --type java --name my-project --with-nix

# Enter development shell
cd my-project
nix develop
```

#### Adding to Existing Projects

```bash
# Add artagon-nix as submodule
git submodule add https://github.com/artagon/artagon-nix.git .nix/artagon-nix
git submodule update --init --recursive

# Checkout v1 tag for stability
cd .nix/artagon-nix && git checkout v1 && cd ../..

# Create symlink to appropriate template
ln -s .nix/artagon-nix/templates/java/flake.nix .

# Enter development environment
nix develop
```

#### Documentation

See [artagon-nix](https://github.com/artagon/artagon-nix) for:
- Complete installation guide
- Template reference and customization
- Troubleshooting common issues
- Advanced usage examples

## Using in Your Projects

### Option 1: Submodule (Recommended)

Add as a submodule and reference scripts:

```bash
# Add submodule
git submodule add git@github.com:artagon/artagon-common.git .common/artagon-common

# Use scripts
.common/artagon-common/scripts/gh_auto_create_and_push.sh --help

# Or symlink to project root
ln -s .common/artagon-common/scripts/gh_auto_create_and_push.sh ./scripts/
```

### Option 2: Copy Scripts

Copy individual scripts to your project:

```bash
cp .common/artagon-common/scripts/gh_auto_create_and_push.sh ./scripts/
```

### Option 3: Add to PATH

For personal use, symlink to your ~/bin:

```bash
ln -s ~/Projects/Artagon/artagon-common/scripts/gh_auto_create_and_push.sh ~/bin/
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

We use an **issue-driven development workflow** with semantic commits and automated branch management. All contributions must follow this process.

### Quick Start

```bash
# 1. Create or find an issue
gh issue create --title "Add feature X" --label "enhancement"
# Returns: Issue #42

# 2. Create semantic branch
./scripts/gh_create_issue_branch.sh 42
# Creates: feat/42-add-feature-x

# 3. Make changes and commit (semantic format)
git commit -m "feat(scope): add feature X

Detailed description of changes.

Closes #42"

# 4. Create pull request
./scripts/gh_create_pr.sh
```

### Semantic Commits

All commits must follow semantic format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `style` - Formatting
- `refactor` - Code refactoring
- `perf` - Performance
- `test` - Tests
- `build` - Build system
- `ci` - CI/CD
- `chore` - Maintenance

**Examples:**
```
feat(bazel): add C++26 support
fix(workflows): correct matrix syntax
docs: update API reference
```

### Branch Naming

Format: `<type>/<issue>-<description>`

**Examples:**
- `feat/42-add-cpp26-support` ✓
- `fix/38-workflow-matrix` ✓
- `docs/45-api-examples` ✓

### Automation Scripts

- `./scripts/gh_create_issue_branch.sh <issue>` - Create semantic branch
- `./scripts/gh_create_pr.sh` - Create pull request with template

### Complete Documentation

For full workflow details, see:
- **[CONTRIBUTING.md](docs/CONTRIBUTING.md)** - Complete contribution guide
- **[SEMANTIC-COMMITS.md](docs/SEMANTIC-COMMITS.md)** - Commit message format
- **[Issue Templates](.github/ISSUE_TEMPLATE/)** - Feature/bug/chore templates
- **[PR Template](.github/PULL_REQUEST_TEMPLATE.md)** - Pull request template

### Script Guidelines

When adding new scripts:
- Use `#!/usr/bin/env bash` shebang
- Include `set -euo pipefail` for safety
- Add help text and usage examples
- Handle errors gracefully
- Support `--help` flag
- Pass shellcheck validation
- Follow semantic commit for changes

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
- 🆕 Nix integration via [artagon-nix](https://github.com/artagon/artagon-nix) for reproducible development environments
- 🆕 Bazel build system support for C/C++ projects
- 🆕 Reusable CI/CD workflows via [artagon-workflows](https://github.com/artagon/artagon-workflows)
- 🆕 Unified repo_setup.sh script with build system selection
- 🆕 Language-specific templates and configs (CMake + Bazel)
- 🆕 Reusable GitHub Actions workflows for C/C++
- 🆕 Multi-platform packaging (DEB, RPM, AppImage, DMG, ZIP)
- 🆕 Comprehensive CI with coverage, sanitizers, static analysis
- Maven settings.xml with GitHub Packages

---

Last updated: 2025-10-18
