# Bazel Migration Guide

This guide helps you migrate C/C++ projects from CMake to Bazel using the artagon-common build system templates.

## Table of Contents

- [Why Migrate to Bazel?](#why-migrate-to-bazel)
- [Prerequisites](#prerequisites)
- [Migration Steps](#migration-steps)
- [Project Structure](#project-structure)
- [BUILD.bazel Files](#buildbazel-files)
- [Configuration](#configuration)
- [CI/CD Integration](#cicd-integration)
- [Common Patterns](#common-patterns)
- [Troubleshooting](#troubleshooting)

## Why Migrate to Bazel?

### Advantages of Bazel

**Hermetic Builds**
- Reproducible builds across different machines
- Isolated build environments prevent dependency conflicts
- Exact compiler and toolchain version control

**Performance**
- Intelligent incremental builds (only rebuild what changed)
- Distributed caching support
- Parallel execution by default

**Multi-Platform Support**
- Cross-compilation made easy
- Consistent builds on Linux, macOS, Windows
- Remote execution capabilities

**Scalability**
- Handles monorepos with thousands of targets
- Fine-grained dependency tracking
- Optimized for large codebases

### When to Use Bazel vs CMake

**Use Bazel when:**
- Building large, complex projects with many dependencies
- Need hermetic, reproducible builds
- Working in a monorepo architecture
- Require strong multi-language support
- Need advanced caching and distributed builds

**Stick with CMake when:**
- Small to medium projects with simple dependency chains
- Ecosystem heavily uses CMake (e.g., vcpkg)
- Team lacks Bazel expertise
- Need IDE integration (CMake has better support)

## Prerequisites

### Install Bazelisk

Bazelisk automatically downloads and uses the correct Bazel version:

```bash
# macOS
brew install bazelisk

# Linux
wget https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64
chmod +x bazelisk-linux-amd64
sudo mv bazelisk-linux-amd64 /usr/local/bin/bazel

# Verify installation
bazel --version
```

### Install Buildifier

Buildifier formats and validates Bazel files:

```bash
# macOS
brew install buildifier

# Linux via Go
go install github.com/bazelbuild/buildtools/buildifier@latest
```

## Migration Steps

### Step 1: Understand Your CMake Project

Before migrating, analyze your CMake structure:

```bash
# Find all CMakeLists.txt files
find . -name CMakeLists.txt

# Identify external dependencies
grep -r "find_package" .
grep -r "add_subdirectory" .

# Catalog build targets
grep -r "add_library\|add_executable" .
```

Document:
- All build targets (libraries, executables, tests)
- External dependencies and their versions
- Compiler flags and definitions
- Include directories
- Custom build steps

### Step 2: Set Up Bazel Workspace

**For C projects:**

```bash
# Copy Bazel templates from artagon-common
cp artagon-common/configs/c/bazel/WORKSPACE.bazel ./WORKSPACE.bazel
cp artagon-common/configs/c/bazel/MODULE.bazel ./MODULE.bazel
cp artagon-common/configs/c/.bazelrc ./.bazelrc
```

**For C++ projects:**

```bash
# Copy Bazel templates from artagon-common
cp artagon-common/configs/cpp/bazel/WORKSPACE.bazel ./WORKSPACE.bazel
cp artagon-common/configs/cpp/bazel/MODULE.bazel ./MODULE.bazel
cp artagon-common/configs/cpp/.bazelrc ./.bazelrc
```

### Step 3: Create Root BUILD.bazel

Create `BUILD.bazel` in your project root:

```python
# Root BUILD.bazel - usually empty or contains workspace-wide config
package(default_visibility = ["//visibility:public"])
```

### Step 4: Migrate Libraries

#### CMake Library Example

```cmake
# CMakeLists.txt
add_library(mylib STATIC
    src/mylib.c
    src/utils.c
)
target_include_directories(mylib PUBLIC include)
target_link_libraries(mylib pthread)
```

#### Equivalent BUILD.bazel

```python
# src/BUILD.bazel
cc_library(
    name = "mylib",
    srcs = [
        "mylib.c",
        "utils.c",
    ],
    hdrs = glob(["include/**/*.h"]),
    includes = ["include"],
    linkopts = ["-lpthread"],
    visibility = ["//visibility:public"],
)
```

### Step 5: Migrate Executables

#### CMake Executable Example

```cmake
# CMakeLists.txt
add_executable(myapp
    src/main.c
)
target_link_libraries(myapp mylib)
```

#### Equivalent BUILD.bazel

```python
# src/BUILD.bazel
cc_binary(
    name = "myapp",
    srcs = ["main.c"],
    deps = [":mylib"],
)
```

### Step 6: Migrate Tests

#### CMake Test Example

```cmake
# CMakeLists.txt
enable_testing()
add_executable(mylib_test test/test_mylib.c)
target_link_libraries(mylib_test mylib)
add_test(NAME mylib_test COMMAND mylib_test)
```

#### Equivalent BUILD.bazel

```python
# test/BUILD.bazel
cc_test(
    name = "mylib_test",
    srcs = ["test_mylib.c"],
    deps = ["//src:mylib"],
)
```

### Step 7: Handle External Dependencies

#### CMake Dependency Example

```cmake
find_package(GTest REQUIRED)
target_link_libraries(mytest GTest::gtest GTest::gtest_main)
```

#### Bazel with Bzlmod (MODULE.bazel)

```python
# MODULE.bazel
bazel_dep(name = "googletest", version = "1.14.0")
```

```python
# BUILD.bazel
cc_test(
    name = "mytest",
    srcs = ["test.cpp"],
    deps = [
        "@googletest//:gtest",
        "@googletest//:gtest_main",
    ],
)
```

## Project Structure

### Recommended Directory Layout

```
my-project/
├── MODULE.bazel              # Bzlmod module definition
├── WORKSPACE.bazel           # Bazel workspace (legacy)
├── .bazelrc                  # Bazel configuration
├── BUILD.bazel               # Root build file
├── src/
│   ├── BUILD.bazel          # Source library definitions
│   ├── lib/
│   │   ├── BUILD.bazel
│   │   ├── mylib.c
│   │   └── mylib.h
│   └── main.c
├── include/
│   └── myproject/
│       └── api.h
├── test/
│   ├── BUILD.bazel          # Test definitions
│   └── test_mylib.c
└── third_party/
    └── BUILD.bazel          # External dependencies
```

### Organizing BUILD.bazel Files

**Best Practices:**

1. **One BUILD.bazel per directory** - Bazel works best with fine-grained build files
2. **Colocate with source** - Place BUILD.bazel in the same directory as sources
3. **Small targets** - Create small, focused build targets for better caching
4. **Clear naming** - Use descriptive target names

## BUILD.bazel Files

### Common Patterns

#### Header-Only Library

```python
cc_library(
    name = "header_only_lib",
    hdrs = ["myheader.h"],
    includes = ["."],
    visibility = ["//visibility:public"],
)
```

#### Library with Private Headers

```python
cc_library(
    name = "mylib",
    srcs = [
        "mylib.c",
        "private_impl.h",  # Private header
    ],
    hdrs = ["mylib.h"],    # Public header
    includes = ["."],
)
```

#### Binary with Resources

```python
cc_binary(
    name = "myapp",
    srcs = ["main.c"],
    data = [
        "config.json",
        "//resources:data_files",
    ],
    deps = [":mylib"],
)
```

#### Test Suite

```python
cc_test(
    name = "unit_tests",
    srcs = glob(["*_test.c"]),
    deps = [
        ":mylib",
        "@googletest//:gtest_main",
    ],
)
```

## Configuration

### .bazelrc Settings

The artagon-common templates include comprehensive `.bazelrc` files:

**C Configuration Highlights:**
```
# Use C17 standard
build --copt=-std=c17

# Optimization levels
build:release --compilation_mode=opt
build:debug --compilation_mode=dbg

# Sanitizers
build:asan --features=asan
build:ubsan --features=ubsan
```

**C++ Configuration Highlights:**
```
# Use C++23 standard
build --cxxopt=-std=c++23

# Enable warnings
build --cxxopt=-Wall
build --cxxopt=-Wextra
build --cxxopt=-Werror
```

### Custom Configurations

Add project-specific settings to `.bazelrc`:

```
# Enable specific features
build --features=my_feature

# Set preprocessor definitions
build --copt=-DMY_DEFINE=1

# Link against specific libraries
build --linkopt=-lmylib
```

## CI/CD Integration

### Using Artagon Common Workflows

**For Bazel projects:**

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  ci:
    uses: artagon/artagon-common/.github/workflows/bazel-ci.yml@main
    with:
      bazel-configs: 'release,debug,asan,ubsan'
      enable-coverage: true
    secrets: inherit
```

**Key features:**
- Multi-platform builds (Linux, macOS, Windows)
- Multiple configurations (release, debug, sanitizers)
- Code coverage reporting
- Buildifier formatting checks

### Local CI Simulation

Test CI locally before pushing:

```bash
# Run all tests
bazel test //...

# Run with release config
bazel test --config=release //...

# Run with sanitizers
bazel test --config=asan //...
bazel test --config=ubsan //...

# Check formatting
buildifier -lint=warn -r .
```

## Common Patterns

### Conditional Compilation

**CMake:**
```cmake
if(BUILD_TESTS)
  add_subdirectory(test)
endif()
```

**Bazel:**
```python
# Bazel uses select() for platform/config-specific builds
cc_library(
    name = "mylib",
    srcs = select({
        "//conditions:default": ["impl_default.c"],
        "@platforms//os:windows": ["impl_windows.c"],
        "@platforms//os:linux": ["impl_linux.c"],
    }),
)
```

### Compiler Flags Per Target

**CMake:**
```cmake
target_compile_options(mylib PRIVATE -O3 -march=native)
```

**Bazel:**
```python
cc_library(
    name = "mylib",
    srcs = ["mylib.c"],
    copts = ["-O3", "-march=native"],
)
```

### Generated Code

**CMake:**
```cmake
add_custom_command(
  OUTPUT generated.c
  COMMAND generator ${INPUT}
  DEPENDS generator
)
```

**Bazel:**
```python
genrule(
    name = "generate_code",
    srcs = ["input.txt"],
    outs = ["generated.c"],
    cmd = "$(location :generator) $(SRCS) > $@",
    tools = [":generator"],
)
```

## Troubleshooting

### Common Migration Issues

#### Issue: Can't find headers

**Problem:**
```
error: 'mylib.h' file not found
```

**Solution:**
Ensure headers are listed in `hdrs` and includes are correct:
```python
cc_library(
    name = "mylib",
    hdrs = ["mylib.h"],
    includes = ["."],  # Or specific include path
)
```

#### Issue: Linking errors

**Problem:**
```
undefined reference to `pthread_create'
```

**Solution:**
Add linkopts:
```python
cc_binary(
    name = "myapp",
    linkopts = ["-lpthread"],
)
```

#### Issue: Tests can't find data files

**Problem:**
```
error: config.json not found
```

**Solution:**
Add data files to test:
```python
cc_test(
    name = "mytest",
    data = ["config.json"],
)
```

Access in code using Bazel runfiles:
```c
const char* runfiles_dir = getenv("TEST_SRCDIR");
```

### Debugging Bazel Builds

```bash
# Verbose output
bazel build --verbose_failures //...

# Show all commands
bazel build --subcommands //...

# Explain why target was rebuilt
bazel build --explain=explain.txt //...

# Show dependency graph
bazel query --output=graph //... > graph.dot
dot -Tpng graph.dot -o graph.png
```

### Performance Tips

```bash
# Use remote caching (if available)
bazel build --remote_cache=https://my-cache.example.com

# Increase parallelism
bazel build --jobs=16

# Disk cache
bazel build --disk_cache=/path/to/cache

# Profile builds
bazel build --profile=/tmp/profile.json
bazel analyze-profile /tmp/profile.json
```

## Additional Resources

- [Bazel C/C++ Tutorial](https://bazel.build/tutorials/cpp)
- [Bazel Best Practices](https://bazel.build/basics/best-practices)
- [Bzlmod Documentation](https://bazel.build/external/overview#bzlmod)
- [artagon-common Examples](../configs/)
- [Bazel Query Guide](https://bazel.build/query/guide)

## Getting Help

- Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues
- Review artagon-common examples in `configs/c/` and `configs/cpp/`
- Ask in GitHub Discussions: https://github.com/artagon/artagon-common/discussions
- Bazel Community Slack: https://slack.bazel.build/
