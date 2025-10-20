# Troubleshooting Guide

This guide helps you diagnose and fix common issues with artagon-common workflows, build systems, and scripts.

## Table of Contents

- [GitHub Actions Workflows](#github-actions-workflows)
- [Bazel Build Issues](#bazel-build-issues)
- [CMake Build Issues](#cmake-build-issues)
- [Shell Script Issues](#shell-script-issues)
- [Nix Environment Issues](#nix-environment-issues)
- [License and Git Hooks](#license-and-git-hooks)
- [Branch Protection](#branch-protection)
- [Maven/Java Issues](#mavenjava-issues)

## GitHub Actions Workflows

### Workflow Matrix Not Creating Multiple Jobs

**Symptom:** Reusable workflow creates only 1 job instead of multiple jobs for different configurations.

**Example:**
```yaml
# Only creates 1 job instead of 3
with:
  bazel-configs: 'release debug asan'
```

**Cause:** Incorrect format in matrix input (space-separated instead of comma-separated).

**Solution:**

Use **comma-separated** values for matrix inputs:

```yaml
# Correct - creates 3 jobs
with:
  bazel-configs: 'release,debug,asan'
```

**Affected Workflows:**
- `bazel-ci.yml`
- `cpp-ci.yml` (test-standards parameter)

**Verification:**

Check the workflow run to see multiple jobs:
```
Build and Test (ubuntu-latest, release)
Build and Test (ubuntu-latest, debug)
Build and Test (ubuntu-latest, asan)
Build and Test (macos-latest, release)
...
```

---

### Workflow Fails with "Submodule Error"

**Symptom:**
```
Error: fatal: could not read Username for 'https://github.com':
No such device or address
```

**Cause:** Workflow trying to checkout private submodules without authentication.

**Solution 1:** Use SSH URL for submodules (recommended)

```bash
# .gitmodules
[submodule ".legal/artagon-license"]
    url = git@github.com:artagon/artagon-license.git
```

Add SSH key to GitHub secrets and configure workflow:
```yaml
- name: Checkout code
  uses: actions/checkout@v4
  with:
    submodules: recursive
    ssh-key: ${{ secrets.SSH_PRIVATE_KEY }}
```

**Solution 2:** Use GITHUB_TOKEN for HTTPS

```yaml
- name: Checkout code
  uses: actions/checkout@v4
  with:
    submodules: recursive
    token: ${{ secrets.GITHUB_TOKEN }}
```

---

### Nix Installation Fails in Workflow

**Symptom:**
```
Error: Nix installation failed
```

**Cause:** Workflow doesn't check if `flake.nix` exists before installing Nix.

**Solution:**

Ensure workflow has Nix detection:

```yaml
- name: Check for Nix
  id: check-nix
  run: |
    if [ -f "flake.nix" ]; then
      echo "has_nix=true" >> $GITHUB_OUTPUT
    else
      echo "has_nix=false" >> $GITHUB_OUTPUT
    fi

- name: Install Nix
  if: steps.check-nix.outputs.has_nix == 'true'
  uses: cachix/install-nix-action@v24
```

**Verification:**

The cpp-ci.yml workflow now includes this check (as of recent fixes).

---

### Workflow Timeout Issues

**Symptom:** Workflow times out after 6 hours (default limit).

**Cause:** Build or tests taking too long.

**Solutions:**

1. **Add timeout to job:**
```yaml
jobs:
  build:
    timeout-minutes: 60  # 1 hour limit
```

2. **Use caching:**
```yaml
- name: Cache Bazel
  uses: actions/cache@v3
  with:
    path: ~/.cache/bazel
    key: bazel-${{ runner.os }}-${{ hashFiles('**/*.bazel', '**/*.bzl') }}
```

3. **Reduce test scope:**
```yaml
# Only run fast tests in CI
bazel test --test_tag_filters=-slow //...
```

---

## Bazel Build Issues

### Headers Not Found

**Symptom:**
```
error: 'mylib.h' file not found
#include "mylib.h"
         ^~~~~~~~~
```

**Cause:** Headers not listed in `hdrs` attribute or incorrect `includes` path.

**Solution:**

Ensure headers are properly declared:

```python
cc_library(
    name = "mylib",
    srcs = ["mylib.c"],
    hdrs = ["mylib.h"],      # Public headers
    includes = ["."],         # Include path
)
```

**For subdirectories:**

```python
cc_library(
    name = "mylib",
    hdrs = ["include/mylib.h"],
    includes = ["include"],   # Makes #include "mylib.h" work
)
```

**Verification:**
```bash
bazel build //src:mylib --verbose_failures
```

---

### Undefined Reference Errors

**Symptom:**
```
undefined reference to `pthread_create'
```

**Cause:** Missing linker flags or dependencies.

**Solution 1:** Add linkopts

```python
cc_binary(
    name = "myapp",
    linkopts = ["-lpthread"],
)
```

**Solution 2:** Add missing dependency

```python
cc_test(
    name = "mytest",
    deps = [
        ":mylib",          # Missing this dependency
        "@googletest//:gtest",
    ],
)
```

**Common linkopts:**
- `-lpthread` - POSIX threads
- `-lm` - Math library
- `-ldl` - Dynamic linking
- `-lrt` - Real-time extensions

---

### Bazel Test Can't Find Data Files

**Symptom:**
```
FileNotFoundError: config.json
```

**Cause:** Test data files not declared in BUILD.bazel.

**Solution:**

Add data files to test:

```python
cc_test(
    name = "mytest",
    srcs = ["mytest.c"],
    data = [
        "testdata/config.json",
        "testdata/input.txt",
    ],
)
```

**Access in test code:**

```c
// Use Bazel runfiles to find data files
const char* runfiles_dir = getenv("TEST_SRCDIR");
const char* workspace = getenv("TEST_WORKSPACE");

char path[PATH_MAX];
snprintf(path, sizeof(path), "%s/%s/testdata/config.json",
         runfiles_dir, workspace);
```

---

### Sanitizer Builds Fail

**Symptom:**
```
ERROR: Build failed with ASAN errors
```

**Cause:** Memory safety issues detected by Address Sanitizer.

**Diagnosis:**

```bash
# Run with ASAN
bazel test --config=asan //...

# Check for leaks
bazel test --config=asan --test_env=ASAN_OPTIONS=detect_leaks=1 //...
```

**Common ASAN Errors:**

1. **Heap buffer overflow:**
```c
// Bad
char buf[10];
strcpy(buf, "this is too long");  // Overflow!

// Good
char buf[20];
strncpy(buf, "safe", sizeof(buf) - 1);
```

2. **Use after free:**
```c
// Bad
free(ptr);
*ptr = 42;  // Use after free!

// Good
free(ptr);
ptr = NULL;
```

3. **Memory leak:**
```c
// Bad
char* data = malloc(100);
return;  // Leak!

// Good
char* data = malloc(100);
free(data);
return;
```

---

### Bazel Cache Issues

**Symptom:** Rebuilds everything despite no changes.

**Cause:** Cache corruption or incorrect cache settings.

**Solutions:**

1. **Clean build:**
```bash
bazel clean
bazel build //...
```

2. **Clean with expunge (nuclear option):**
```bash
bazel clean --expunge
```

3. **Check disk cache settings:**
```bash
# .bazelrc
build --disk_cache=~/.cache/bazel-disk-cache
```

4. **Verify cache permissions:**
```bash
ls -la ~/.cache/bazel
# Should be writable by your user
```

---

## CMake Build Issues

### CMake Can't Find Compiler

**Symptom:**
```
CMake Error: CMAKE_CXX_COMPILER not set, after EnableLanguage
```

**Cause:** Compiler not in PATH or not specified.

**Solution:**

```bash
# Specify compiler explicitly
export CC=gcc-13
export CXX=g++-13
cmake -B build

# Or via CMake
cmake -B build -DCMAKE_C_COMPILER=gcc-13 -DCMAKE_CXX_COMPILER=g++-13
```

**For Nix environments:**

```bash
# Enter Nix shell first
nix develop
cmake -B build
```

---

### Missing Dependencies in CMake

**Symptom:**
```
CMake Error: Could not find package GTest
```

**Cause:** Dependency not installed or not in CMAKE_PREFIX_PATH.

**Solution 1:** Install via package manager

```bash
# Ubuntu
sudo apt-get install libgtest-dev

# macOS
brew install googletest
```

**Solution 2:** Use Nix development environment

```bash
nix develop  # Loads all dependencies from flake.nix
cmake -B build
```

**Solution 3:** Add to CMAKE_PREFIX_PATH

```bash
cmake -B build -DCMAKE_PREFIX_PATH=/path/to/install
```

---

## Shell Script Issues

### Script Fails with "Unbound Variable"

**Symptom:**
```
line 42: MY_VAR: unbound variable
```

**Cause:** Script uses `set -u` and variable is not set.

**Solution:**

Use parameter expansion with default values:

```bash
# Bad
echo "$MY_VAR"  # Fails if MY_VAR not set

# Good
echo "${MY_VAR:-default_value}"

# Or check first
if [[ -n "${MY_VAR:-}" ]]; then
    echo "$MY_VAR"
fi
```

---

### Script Exits Prematurely

**Symptom:** Script exits without clear error message.

**Cause:** `set -e` causes script to exit on any error.

**Solutions:**

1. **Check return values explicitly:**
```bash
if ! some_command; then
    echo "ERROR: command failed" >&2
    exit 1
fi
```

2. **Allow failure temporarily:**
```bash
set +e  # Disable exit-on-error
optional_command
set -e  # Re-enable
```

3. **Use `|| true` for expected failures:**
```bash
grep "pattern" file.txt || true  # Don't exit if not found
```

---

### Permission Denied Errors

**Symptom:**
```
bash: ./script.sh: Permission denied
```

**Cause:** Script not executable.

**Solution:**

```bash
chmod +x script.sh
./script.sh
```

**For Git:**

```bash
git add --chmod=+x script.sh
git commit -m "Make script executable"
```

---

## Nix Environment Issues

### Nix Flake Not Found

**Symptom:**
```
error: getting status of '/nix/store/.../flake.nix': No such file or directory
```

**Cause:** Not in project directory with flake.nix.

**Solution:**

```bash
cd /path/to/project
nix develop
```

---

### Nix Build Fails with Hash Mismatch

**Symptom:**
```
error: hash mismatch in fixed-output derivation
```

**Cause:** Hash in flake.nix doesn't match actual download.

**Solution:**

```bash
# Update flake lock
nix flake update

# Or use lib.fakeSha256 temporarily to get correct hash
# Then update flake.nix with real hash
```

---

### Nix Shell Missing Tools

**Symptom:** Command not found inside `nix develop`.

**Cause:** Tool not listed in flake.nix buildInputs.

**Solution:**

Add to flake.nix:

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
    # Add missing tool here
    newtool
  ];
};
```

Then:
```bash
nix flake update
nix develop
```

---

## License and Git Hooks

### Pre-commit Hook Blocks Commits

**Symptom:**
```
ERROR: LICENSE file not found in project root
```

**Cause:** Missing LICENSE file (required by pre-commit hook).

**Solution:**

For artagon projects using dual licensing:

```bash
# Add artagon-license submodule
git submodule add git@github.com:artagon/artagon-license.git .legal/artagon-license

# Export license files
.legal/artagon-license/scripts/export-license-assets.sh

# Copy to root
cp .legal/LICENSE .
cp -r .legal/licenses .

# Commit
git add LICENSE licenses/
git commit -m "Add dual licensing (AGPL-3.0 / Commercial)"
```

---

### Hook Fails with "Permission Denied"

**Symptom:**
```
.git/hooks/pre-commit: Permission denied
```

**Cause:** Git hook not executable.

**Solution:**

```bash
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/post-checkout
chmod +x .git/hooks/post-merge
```

---

## Branch Protection

### Can't Push to Protected Branch

**Symptom:**
```
remote: error: GH006: Protected branch update failed
```

**Cause:** Branch protection requires PR reviews.

**Solution:**

1. **Create feature branch:**
```bash
git checkout -b feature/my-changes
git push origin feature/my-changes
```

2. **Open pull request on GitHub**

3. **Get required approvals**

**For admins who need to bypass:**

```bash
# Check current protection
scripts/ci/check-branch-protection.sh --repo artagon-common

# Temporarily remove protection
scripts/ci/remove-branch-protection.sh --repo artagon-common

# Make changes
git push

# Re-apply protection
scripts/ci/gh_protect_main.sh --repo artagon-common
```

---

### Branch Protection Script Fails

**Symptom:**
```
Error: Resource not accessible by integration
```

**Cause:** Insufficient GitHub permissions.

**Solution:**

Ensure you have admin access to repository:

```bash
# Check your permissions
gh api /repos/artagon/artagon-common | jq .permissions

# Required: admin permission
```

---

## Maven/Java Issues

### Maven Dependency Download Fails

**Symptom:**
```
Could not resolve dependencies for project
```

**Cause:** Network issues or missing repository.

**Solutions:**

1. **Check internet connection**

2. **Clear local cache:**
```bash
rm -rf ~/.m2/repository
mvn clean install
```

3. **Use specific repository:**
```xml
<repositories>
  <repository>
    <id>central</id>
    <url>https://repo1.maven.org/maven2</url>
  </repository>
</repositories>
```

---

### GPG Signing Fails

**Symptom:**
```
gpg: signing failed: Inappropriate ioctl for device
```

**Cause:** GPG can't prompt for passphrase.

**Solution:**

```bash
export GPG_TTY=$(tty)
mvn deploy
```

**For CI/CD:**

```bash
# Use --batch mode
mvn deploy --batch-mode
```

---

## Getting More Help

### Debug Mode

Enable verbose output:

**Bazel:**
```bash
bazel build --verbose_failures --subcommands //...
```

**CMake:**
```bash
cmake -B build -DCMAKE_VERBOSE_MAKEFILE=ON
make VERBOSE=1
```

**Shell Scripts:**
```bash
bash -x script.sh  # Print each command
```

### Collect Diagnostic Information

```bash
# System info
uname -a
echo "Shell: $SHELL"
echo "PATH: $PATH"

# Tool versions
git --version
bazel --version
cmake --version
gcc --version
clang --version

# Bazel info
bazel info

# Git status
git status
git log --oneline -5
git submodule status
```

### Where to Ask

- **GitHub Issues**: https://github.com/artagon/artagon-common/issues
- **GitHub Discussions**: https://github.com/artagon/artagon-common/discussions
- **Bazel Slack**: https://slack.bazel.build/
- **Stack Overflow**: Tag with `bazel`, `cmake`, or `github-actions`

## See Also

- [BAZEL-MIGRATION.md](./BAZEL-MIGRATION.md) - Migrating from CMake to Bazel
- [API.md](./API.md) - Shell script API reference
- [BRANCH-PROTECTION.md](./BRANCH-PROTECTION.md) - Branch protection strategies
- [README.md](../README.md) - Main documentation
