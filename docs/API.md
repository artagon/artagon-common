# artagon-common Shell Script API Reference

This document describes the shell script functions available in the artagon-common shared library (`scripts/lib/common.sh`).

## Table of Contents

- [Usage](#usage)
- [Functions](#functions)
  - [require_commands](#require_commands)
  - [generate_header_guard](#generate_header_guard)
  - [gh_repo_create](#gh_repo_create)
  - [clean_maven_dependency_line](#clean_maven_dependency_line)
- [Examples](#examples)
- [Best Practices](#best-practices)

## Usage

### Sourcing the Library

To use these functions in your scripts, source the common library:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source the common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# Now you can use the functions
require_commands "git" "gh"
```

### Safety Features

The library includes built-in safety features:

1. **Prevents direct execution**: The library can only be sourced, not executed directly
2. **Idempotent loading**: Can be sourced multiple times without side effects
3. **No global side effects**: Functions are pure and don't modify global state

## Functions

### require_commands

Verifies that all required command-line tools are available on the system PATH.

#### Signature

```bash
require_commands COMMAND...
```

#### Parameters

- `COMMAND...`: One or more command names to check for availability

#### Return Value

- `0`: All commands are available
- `1`: One or more commands are missing

#### Behavior

- Checks each command using `command -v`
- Prints missing commands to stderr
- Returns error if any commands are missing

#### Examples

```bash
# Check for single command
require_commands "git"

# Check for multiple commands
require_commands "git" "gh" "jq"

# Use in conditional
if ! require_commands "bazel" "buildifier"; then
    echo "Please install Bazel and Buildifier first"
    exit 1
fi
```

#### Error Output

```
Required tool(s) missing: bazel buildifier
```

---

### generate_header_guard

Converts a project name into a valid C/C++ header guard identifier.

#### Signature

```bash
generate_header_guard PROJECT_NAME
```

#### Parameters

- `PROJECT_NAME`: The project name to convert (can contain any characters)

#### Return Value

Returns the generated header guard via stdout

#### Behavior

- Replaces all non-alphanumeric characters with underscores
- Converts to uppercase
- Returns "PROJECT" if input is empty
- Does not add trailing underscores or `_H` suffix (caller's responsibility)

#### Examples

```bash
# Simple name
guard=$(generate_header_guard "myproject")
# Output: MYPROJECT

# Name with special characters
guard=$(generate_header_guard "my-awesome_project.v2")
# Output: MY_AWESOME_PROJECT_V2

# Use in header file generation
PROJECT_NAME="artagon-core"
GUARD=$(generate_header_guard "$PROJECT_NAME")
cat > include/config.h <<EOF
#ifndef ${GUARD}_H
#define ${GUARD}_H

// Project configuration
#define PROJECT_NAME "${PROJECT_NAME}"

#endif // ${GUARD}_H
EOF
```

#### Generated Header Guard Examples

| Input | Output |
|-------|--------|
| `my-project` | `MY_PROJECT` |
| `core.utils` | `CORE_UTILS` |
| `lib_v2.1` | `LIB_V2_1` |
| `123-start` | `123_START` |
| `` (empty) | `PROJECT` |

---

### gh_repo_create

Creates a GitHub repository using the GitHub CLI (`gh`) with proper argument handling.

#### Signature

```bash
gh_repo_create OWNER REPO VISIBILITY_FLAG [DESCRIPTION] [EXTRA_FLAGS...]
```

#### Parameters

- `OWNER`: GitHub username or organization
- `REPO`: Repository name
- `VISIBILITY_FLAG`: `--public` or `--private`
- `DESCRIPTION`: (Optional) Repository description
- `EXTRA_FLAGS...`: (Optional) Additional `gh repo create` flags

#### Return Value

Returns the exit code from `gh repo create`

#### Behavior

- Constructs a properly quoted `gh repo create` command
- Adds description if provided
- Passes through extra flags to `gh`
- Avoids `eval` for security

#### Examples

```bash
# Create public repository
gh_repo_create "myuser" "my-repo" "--public" "My awesome project"

# Create private repository
gh_repo_create "myorg" "secret-project" "--private" "Internal tool"

# Create and clone immediately
gh_repo_create "myuser" "new-project" "--public" "Description" --clone

# Create with confirmation prompt
gh_repo_create "myuser" "new-project" "--public" "" --confirm

# Create with custom template
gh_repo_create "myuser" "new-project" "--public" "From template" \
    --template "myuser/template-repo"
```

#### Common Extra Flags

| Flag | Description |
|------|-------------|
| `--clone` | Clone repository after creation |
| `--confirm` | Prompt for confirmation before creating |
| `--disable-issues` | Disable issues for repository |
| `--disable-wiki` | Disable wiki for repository |
| `--template REPO` | Create from template repository |
| `--add-readme` | Add README.md to repository |

---

### clean_maven_dependency_line

Cleans Maven log output by removing log level prefixes and whitespace.

#### Signature

```bash
clean_maven_dependency_line LINE
```

#### Parameters

- `LINE`: A line of Maven output to clean

#### Return Value

Returns the cleaned line via stdout

#### Behavior

- Removes carriage return characters (`\r`)
- Strips Maven log prefixes like `[INFO]`, `[WARNING]`, `[ERROR]`
- Trims leading whitespace
- Preserves the actual content

#### Examples

```bash
# Clean Maven INFO line
line="[INFO]    org.junit.jupiter:junit-jupiter:5.10.0"
cleaned=$(clean_maven_dependency_line "$line")
echo "$cleaned"
# Output: org.junit.jupiter:junit-jupiter:5.10.0

# Clean line with extra whitespace
line="[WARNING]       com.google.guava:guava:32.1.2-jre"
cleaned=$(clean_maven_dependency_line "$line")
echo "$cleaned"
# Output: com.google.guava:guava:32.1.2-jre

# Process Maven dependency tree
mvn dependency:tree | while IFS= read -r line; do
    cleaned=$(clean_maven_dependency_line "$line")
    if [[ "$cleaned" =~ ^[a-z] ]]; then
        echo "Dependency: $cleaned"
    fi
done
```

#### Maven Log Prefix Examples

The function handles all Maven log levels:

| Input | Output |
|-------|--------|
| `[INFO] message` | `message` |
| `[WARNING] message` | `message` |
| `[ERROR] message` | `message` |
| `[DEBUG] message` | `message` |
| `   [INFO]   message` | `message` |

---

## Examples

### Complete Script Example

Here's a complete script using multiple library functions:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source the common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# Check for required tools
if ! require_commands "git" "gh" "mvn"; then
    echo "ERROR: Missing required tools" >&2
    exit 1
fi

# Create a new C++ project repository
PROJECT_NAME="my-awesome-library"
OWNER="myuser"
GUARD=$(generate_header_guard "$PROJECT_NAME")

echo "Creating repository: $OWNER/$PROJECT_NAME"
gh_repo_create "$OWNER" "$PROJECT_NAME" "--public" \
    "Awesome C++ library" --clone

cd "$PROJECT_NAME"

# Generate header file with guard
cat > include/config.h <<EOF
#ifndef ${GUARD}_CONFIG_H
#define ${GUARD}_CONFIG_H

#define PROJECT_NAME "$PROJECT_NAME"
#define PROJECT_VERSION "0.1.0"

#endif // ${GUARD}_CONFIG_H
EOF

echo "Project setup complete!"
```

### Processing Maven Output

```bash
#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../lib/common.sh"

# Check Maven is available
require_commands "mvn" || exit 1

# Get and process dependency tree
echo "Analyzing dependencies..."
mvn dependency:tree -DoutputType=text | while IFS= read -r line; do
    cleaned=$(clean_maven_dependency_line "$line")

    # Filter for actual dependencies (not log messages)
    if [[ "$cleaned" =~ ^[a-z]+\. ]]; then
        echo "  $cleaned"
    fi
done
```

### Automated Repository Setup

```bash
#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../lib/common.sh"

setup_repo() {
    local name=$1
    local description=$2

    # Verify tools
    require_commands "gh" "git" || return 1

    # Create repo
    echo "Creating repository: $name"
    gh_repo_create "myorg" "$name" "--private" "$description" --clone || return 1

    cd "$name"

    # Initialize with header guard
    local guard=$(generate_header_guard "$name")
    mkdir -p include
    cat > include/${name}.h <<EOF
#ifndef ${guard}_H
#define ${guard}_H

// Public API for $name

#endif // ${guard}_H
EOF

    # Commit initial structure
    git add .
    git commit -m "Initial project structure"
    git push

    echo "Repository setup complete!"
}

# Create multiple repositories
setup_repo "data-processor" "High-performance data processing library"
setup_repo "network-utils" "Network utility functions"
```

## Best Practices

### Error Handling

Always check function return values:

```bash
# Good
if ! require_commands "git" "gh"; then
    echo "ERROR: Required tools missing" >&2
    exit 1
fi

# Bad - ignores errors
require_commands "git" "gh"
```

### Quoting

Always quote function outputs to preserve whitespace:

```bash
# Good
guard="$(generate_header_guard "$project_name")"

# Bad - word splitting issues
guard=$(generate_header_guard $project_name)
```

### Command Substitution

Use `$()` instead of backticks:

```bash
# Good
output="$(clean_maven_dependency_line "$line")"

# Avoid
output=`clean_maven_dependency_line "$line"`
```

### Array Handling

When passing arrays to functions:

```bash
# Good - expand array properly
commands=("git" "gh" "bazel")
require_commands "${commands[@]}"

# Bad - passes as single string
require_commands "${commands[*]}"
```

### Defensive Programming

Check inputs before processing:

```bash
process_project() {
    local name="${1:-}"

    if [[ -z "$name" ]]; then
        echo "ERROR: Project name required" >&2
        return 1
    fi

    local guard=$(generate_header_guard "$name")
    # ... rest of function
}
```

## See Also

- [scripts/lib/common.sh](../scripts/lib/common.sh) - Source code
- [scripts/repo_setup.sh](../scripts/repo_setup.sh) - Example usage
- [scripts/gh_auto_create_and_push.sh](../scripts/gh_auto_create_and_push.sh) - Complex example
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues and solutions
