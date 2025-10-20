# Changelog

All notable changes to artagon-common will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Added comprehensive `docs/BAZEL-MIGRATION.md` guide for migrating from CMake to Bazel
- Added `docs/API.md` documentation for shell script library functions
- Added `docs/TROUBLESHOOTING.md` guide for common issues and solutions
- Added Shellcheck CI workflow (`.github/workflows/shellcheck.yml`) for shell script validation
- Added Nix detection step to C++ CI workflow matching C workflow pattern
- Added dual licensing (AGPL-3.0 / Commercial) via artagon-license submodule
- Added `LICENSE` file and `licenses/` directory to repository root
- Added `.legal/artagon-license` git submodule for centralized license management

### Changed
- **BREAKING**: Changed Bazel workflow matrix input format from space-separated to comma-separated
  - Old: `bazel-configs: 'release debug asan'`
  - New: `bazel-configs: 'release,debug,asan'`
- Improved shell script safety by adding `set -euo pipefail` to all deployment and CI scripts:
  - `scripts/deploy/mvn_check_ready.sh`
  - `scripts/deploy/mvn_deploy_snapshot.sh`
  - `scripts/deploy/mvn_release_nexus.sh`
  - `scripts/deploy/mvn_release.sh`
  - `scripts/ci/gh_protect_main.sh`
  - `scripts/ci/gh_protect_main_team.sh`
  - `scripts/ci/gh_protect_main_strict.sh`
  - `scripts/ci/gh_check_branch_protection.sh`
  - `scripts/ci/gh_remove_branch_protection.sh`
  - `scripts/ci/gh_branch_protection_common.sh`
- Standardized all CI and deployment script shebangs to `#!/usr/bin/env bash` for better portability
- Updated `README.md` Bazel examples to use comma-separated configs
- Enhanced `.github/workflows/cpp-ci.yml` with automatic Nix detection

### Fixed
- Fixed critical bug in `.github/workflows/bazel-ci.yml` where matrix was creating single job instead of multiple jobs per configuration
  - Issue: `format('["{0}"]', inputs.bazel-configs)` was wrapping entire string in quotes
  - Fix: Changed to `format('[{0}]', inputs.bazel-configs)` and updated input to comma-separated format
- Fixed inconsistency between C and C++ CI workflows (C++ now has Nix detection like C workflow)

## [Previous Changes]

### Added (Earlier Releases)
- Multi-shell support to Nix installation script (6b76bbb)
- Meta Folly and Google Benchmark to C/C++ Bazel configs (93a74b7)
- Template paths improvements in Nix flake checks (d576050)
- Comprehensive branch protection scripts for GitHub repositories
- Reusable GitHub Actions workflows for C, C++, Rust, Java, and Bazel projects
- Professional repo_setup.sh script (740 lines)
- Nix flakes for reproducible development environments (Java, C, C++, Rust)
- Automated project scaffolding for 4 languages
- Security scanning integration (OWASP, OSS Index, Trivy)
- Dependency checksum verification scripts
- Maven deployment automation
- Release process documentation
- EditorConfig for consistent code formatting

### Changed (Earlier Releases)
- Updated Claude preferences to require documentation and script reviews (00e5b37)
- Various refactorings for code quality (00c488f)
- Documentation improvements (261461e, 1859b61)
- Release process enhancements (156b011)

## Migration Guide

### Upgrading to Unreleased (Bazel Matrix Fix)

If you're using the Bazel CI workflow, update your workflow calls:

**Before:**
```yaml
jobs:
  ci:
    uses: artagon/artagon-common/.github/workflows/bazel-ci.yml@main
    with:
      bazel-configs: 'release debug asan ubsan'
```

**After:**
```yaml
jobs:
  ci:
    uses: artagon/artagon-common/.github/workflows/bazel-ci.yml@main
    with:
      bazel-configs: 'release,debug,asan,ubsan'
```

### Shell Script Safety Improvements

All scripts now use `set -euo pipefail` for enhanced safety:
- `-e`: Exit on error
- `-u`: Error on unset variables
- `-o pipefail`: Catch errors in pipelines

If you've copied these scripts, consider updating them to match the improved versions.

### Dual Licensing

The repository now uses dual licensing (AGPL-3.0 / Commercial). See:
- `LICENSE` - Main license notice
- `licenses/LICENSING.md` - Detailed licensing guide
- `licenses/CLA.md` - Contributor License Agreement

## Documentation

- [README.md](./README.md) - Main documentation
- [docs/BAZEL-MIGRATION.md](./docs/BAZEL-MIGRATION.md) - Migrating from CMake to Bazel
- [docs/API.md](./docs/API.md) - Shell script API reference
- [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) - Common issues and solutions
- [docs/BRANCH-PROTECTION.md](./docs/BRANCH-PROTECTION.md) - Branch protection strategies
- [docs/BRANCH-PROTECTION-USAGE.md](./docs/BRANCH-PROTECTION-USAGE.md) - Usage examples

## Contributing

See `licenses/CLA.md` for contribution requirements.

## License

This project is dual-licensed under:
- AGPL-3.0 License (for open source use)
- Commercial License (for proprietary use)

See `LICENSE` and `licenses/LICENSING.md` for details.
