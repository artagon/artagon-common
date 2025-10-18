# Artagon Common - Codex/Copilot Code Patterns

## Project Type
Shared bash scripts and documentation repository for Maven JVM projects

## Primary Languages
- Bash (scripts)
- Markdown (documentation)
- YAML (GitHub Actions workflows)

## Bash Script Patterns

### Script Header Template
```bash
#!/usr/bin/env bash
# script-name.sh
#
# Brief description of what this script does.
#
# Usage:
#   script-name.sh [OPTIONS] ARGS
#
# Options:
#   --option PATH    Description of option
#   --help           Show this help message

set -euo pipefail
```

### Color Output Functions
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

warn() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}
```

### Argument Parsing Pattern
```bash
# Default configuration
OPTION1=""
OPTION2="default_value"
FLAG=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--option1)
            OPTION1="$2"
            shift 2
            ;;
        -p|--option2)
            OPTION2="$2"
            shift 2
            ;;
        -f|--flag)
            FLAG=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            # Positional argument
            ARGS+=("$1")
            shift
            ;;
    esac
done

# Validate required options
if [[ -z "${OPTION1}" ]]; then
    error "Option1 is required"
fi
```

### Safe Arithmetic with set -e
```bash
# WRONG - exits prematurely when counter is 0
((counter++))

# CORRECT - safe with set -e
counter=$((counter + 1))

# CORRECT - alternative
counter=$((counter + 1))
```

### File Existence Checks
```bash
# Check file exists
if [[ ! -f "${file_path}" ]]; then
    error "File not found: ${file_path}"
fi

# Check directory exists
if [[ ! -d "${dir_path}" ]]; then
    error "Directory not found: ${dir_path}"
fi

# Check executable exists
if [[ ! -x "${script_path}" ]]; then
    error "Script not executable: ${script_path}"
fi
```

### SHA Checksum Generation
```bash
# Generate SHA-256 checksum
sha256=$(openssl dgst -sha256 "${file}" | awk '{print $2}')

# Generate SHA-512 checksum
sha512=$(openssl dgst -sha512 "${file}" | awk '{print $2}')

# Write checksum to file
echo "${sha256}" > "${file}.sha256"
echo "${sha512}" > "${file}.sha512"
```

### SHA Checksum Verification
```bash
# Read expected checksum
expected=$(cat "${file}.sha256")

# Calculate actual checksum
actual=$(openssl dgst -sha256 "${file}" | awk '{print $2}')

# Compare
if [[ "${expected}" != "${actual}" ]]; then
    error "SHA-256 checksum mismatch for ${file}
Expected: ${expected}
Actual:   ${actual}"
fi

success "SHA-256: OK"
```

### Maven Coordinate Extraction
```bash
# Extract groupId from pom.xml
GROUP_ID=$(mvn help:evaluate -Dexpression=project.groupId -q -DforceStdout)

# Extract artifactId from pom.xml
ARTIFACT_ID=$(mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout)

# Create file prefix from coordinates
FILE_PREFIX="${GROUP_ID}-${ARTIFACT_ID}"
```

### Maven Dependency Resolution
```bash
# Resolve all dependencies
mvn dependency:resolve -DincludeScope=compile

# Copy dependencies to directory
mvn dependency:copy-dependencies \
    -DincludeScope=compile \
    -DoutputDirectory="${TARGET_DIR}"

# List dependencies in format
mvn dependency:list \
    -DincludeScope=compile \
    -DoutputFile="${OUTPUT_FILE}"
```

### Directory Traversal
```bash
# Get script directory (works with symlinks)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get project root (one level up)
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Change to directory safely
cd "${SECURITY_DIR}" || error "Cannot change to ${SECURITY_DIR}"
```

### Loop Through Files
```bash
# Array of files
FILES=("file1.csv" "file2.list" "file3.txt")

# Loop through array
for file in "${FILES[@]}"; do
    if [[ ! -f "${file}" ]]; then
        warn "File not found: ${file}, skipping"
        continue
    fi

    # Process file
    process_file "${file}"
done
```

### Help Message Pattern
```bash
show_help() {
    cat << 'EOF'
script-name.sh - Brief description

Longer description of what the script does and why you might use it.

USAGE:
    script-name.sh [OPTIONS] FILE [FILE...]

OPTIONS:
    -d, --directory PATH    Path to directory (default: current directory)
    -f, --format FMT        Output format: csv or json (default: csv)
    -v, --verbose           Enable verbose output
    -h, --help              Show this help message

EXAMPLES:
    # Basic usage
    script-name.sh file1.txt file2.txt

    # With custom directory
    script-name.sh --directory /path/to/dir file1.txt

EXIT CODES:
    0   Success
    1   Error occurred

EOF
}
```

### Wrapper Script Pattern
```bash
#!/usr/bin/env bash
set -euo pipefail

# Locate shared script in artagon-common submodule
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMMON_SCRIPT="${PROJECT_ROOT}/.common/artagon-common/scripts/security/shared-script.sh"

# Verify shared script exists
if [[ ! -x "${COMMON_SCRIPT}" ]]; then
    echo "ERROR: Shared script not found at ${COMMON_SCRIPT}" >&2
    echo "Ensure artagon-common submodule is initialized:" >&2
    echo "  git submodule update --init --recursive" >&2
    exit 1
fi

# Forward all arguments to shared script with project root
exec "${COMMON_SCRIPT}" --project-root "${PROJECT_ROOT}" "$@"
```

## Maven POM Patterns

### exec-maven-plugin for Bash Script
```xml
<plugin>
    <groupId>org.codehaus.mojo</groupId>
    <artifactId>exec-maven-plugin</artifactId>
    <version>3.5.0</version>
    <executions>
        <execution>
            <id>verify-security-file-checksums</id>
            <phase>validate</phase>
            <goals>
                <goal>exec</goal>
            </goals>
            <configuration>
                <executable>${project.basedir}/.common/artagon-common/scripts/security/verify-checksums.sh</executable>
                <arguments>
                    <argument>--security-dir</argument>
                    <argument>${project.basedir}/security</argument>
                    <argument>file1.csv</argument>
                    <argument>file2.list</argument>
                </arguments>
            </configuration>
        </execution>
    </executions>
</plugin>
```

## Documentation Patterns

### README.md Documentation Section
```markdown
## Documentation

### Common Documentation

General-purpose documentation is maintained in artagon-common:

- **[Security Scripts Guide](.common/artagon-common/docs/SECURITY-SCRIPTS.md)** - Using security verification scripts
- **[Release Guide](.common/artagon-common/docs/RELEASE-GUIDE.md)** - How to create releases
- **[Deployment Guide](.common/artagon-common/docs/DEPLOYMENT.md)** - Deploying to Maven Central
- **[GitHub Packages Guide](.common/artagon-common/docs/GITHUB-PACKAGES.md)** - Using GitHub Packages
- **[Licensing Implementation](.common/artagon-common/docs/licensing/IMPLEMENTATION-GUIDE.md)** - Dual licensing setup
- **[Complete Documentation Index](.common/artagon-common/docs/README.md)** - All available documentation

### Project-Specific Guides

- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes
- **[security/README.md](security/README.md)** - Security baseline file documentation
```

## Git Patterns

### Submodule Operations
```bash
# Add submodule
git submodule add https://github.com/artagon/artagon-common.git .common/artagon-common

# Initialize submodules
git submodule update --init --recursive

# Update submodule to latest
cd .common/artagon-common
git pull origin main
cd ../..
git add .common/artagon-common
git commit -m "Update artagon-common submodule"

# Update all submodules
git submodule update --remote --merge
```

## File Naming Conventions

### Security Baseline Files
```bash
# Pattern: {groupId}-{artifactId}-{type}.{ext}
# Example for com.artagon:artagon-parent
com.artagon-artagon-parent-dependency-checksums.csv
com.artagon-artagon-parent-pgp-trusted-keys.list

# With checksums
com.artagon-artagon-parent-dependency-checksums.csv.sha256
com.artagon-artagon-parent-dependency-checksums.csv.sha512
```

### Scripts
```bash
# kebab-case with .sh extension
update-dependency-security.sh
verify-checksums.sh
generate-dependency-checksums.sh
```

### Documentation
```bash
# UPPERCASE with dashes
SECURITY-SCRIPTS.md
RELEASE-GUIDE.md
IMPLEMENTATION-GUIDE.md
```

## Common Script Invocations

### Security Scripts
```bash
# Update dependency security baselines
./scripts/update-dependency-security.sh --update

# Verify baselines are current
./scripts/update-dependency-security.sh --verify

# Verify checksum files
.common/artagon-common/scripts/security/verify-checksums.sh \
    --security-dir ./security \
    com.artagon-artagon-parent-dependency-checksums.csv \
    com.artagon-artagon-parent-pgp-trusted-keys.list
```

### Maven Commands
```bash
# Developer build
mvn verify

# Security verification
mvn -P artagon-oss-security verify

# Release build
mvn -P artagon-oss-release,artagon-oss-security clean verify
```

## Error Handling Patterns

### Exit on Error with Cleanup
```bash
# Trap to ensure cleanup on error
cleanup() {
    if [[ -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
    fi
}
trap cleanup EXIT

# Create temp directory
TEMP_DIR=$(mktemp -d)

# Do work that might fail
process_files "${TEMP_DIR}"

# Cleanup happens automatically via trap
```

### Validation Chain
```bash
# Validate all inputs before proceeding
validate_inputs() {
    local errors=0

    if [[ -z "${REQUIRED_VAR}" ]]; then
        error "REQUIRED_VAR must be set"
        errors=$((errors + 1))
    fi

    if [[ ! -d "${REQUIRED_DIR}" ]]; then
        error "Directory not found: ${REQUIRED_DIR}"
        errors=$((errors + 1))
    fi

    if [[ ${errors} -gt 0 ]]; then
        exit 1
    fi
}

validate_inputs
```

## Testing Patterns

### Dry Run Option
```bash
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
    esac
done

if [[ "${DRY_RUN}" == "true" ]]; then
    info "DRY RUN: Would execute: ${command}"
else
    ${command}
fi
```

## Project-Specific Conventions

1. **All scripts use strict mode**: `set -euo pipefail`
2. **Colored output for user feedback**: red/green/yellow/blue
3. **Consistent argument parsing**: long and short options
4. **Help messages**: Always provide `--help` option
5. **Exit codes**: 0 for success, 1 for error
6. **File naming**: Maven coordinate-based for security files
7. **Documentation**: Self-documenting with inline help
8. **Submodule pattern**: Scripts in artagon-common, wrappers in projects
