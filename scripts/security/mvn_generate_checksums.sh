#!/usr/bin/env bash
# mvn_generate_checksums.sh
#
# Generate dependency checksums for Maven projects
# This script downloads dependencies and generates SHA-256 checksums
# for security verification during builds and releases.
#
# Usage:
#   mvn_generate_checksums.sh [OPTIONS]
#
# Options:
#   -t, --transitive          Include transitive dependencies (default: false)
#   -s, --scope SCOPE         Dependency scope to include (default: compile)
#   -o, --output FILE         Output CSV file (default: security/dependency-checksums.csv)
#   -h, --help                Show this help message
#
# Examples:
#   # Generate checksums for direct compile dependencies
#   ./mvn_generate_checksums.sh
#
#   # Include transitive dependencies
#   ./mvn_generate_checksums.sh --transitive
#
#   # Generate for test scope
#   ./mvn_generate_checksums.sh --scope test --output test.csv

set -euo pipefail

# Default values
TRANSITIVE="false"
SCOPE="compile"
OUTPUT="security/dependency-checksums.csv"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_PATH="${SCRIPT_DIR}/../lib/common.sh"

# shellcheck source=scripts/lib/common.sh
source "${LIB_PATH}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

show_help() {
    cat << 'EOF'
mvn_generate_checksums.sh - Generate dependency checksums

Generate SHA-256 checksums for Maven project dependencies.

USAGE:
    mvn_generate_checksums.sh [OPTIONS]

OPTIONS:
    -t, --transitive          Include transitive dependencies (default: false)
    -s, --scope SCOPE         Dependency scope to include (default: compile)
    -o, --output FILE         Output CSV file (default: security/dependency-checksums.csv)
    -h, --help                Show this help message

EXAMPLES:
    # Generate checksums for direct compile dependencies
    ./mvn_generate_checksums.sh

    # Include transitive dependencies
    ./mvn_generate_checksums.sh -t

    # Generate for test scope
    ./mvn_generate_checksums.sh -s test -o test.csv

EXIT CODES:
    0   Success
    1   Error occurred

EOF
}

# Parse command line arguments (portable - works on BSD and GNU)
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--transitive)
            TRANSITIVE="true"
            shift
            ;;
        -s|--scope)
            if [[ -z "$2" || "$2" == -* ]]; then
                error "Option $1 requires an argument"
            fi
            SCOPE="$2"
            shift 2
            ;;
        -o|--output)
            if [[ -z "$2" || "$2" == -* ]]; then
                error "Option $1 requires an argument"
            fi
            OUTPUT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            error "Unexpected positional argument: $1"
            ;;
    esac
done

# Check for required tools
if ! require_commands mvn openssl; then
    error "Required tools missing. Install the tool(s) listed above."
fi

# Check for pom.xml
if [ ! -f "pom.xml" ]; then
    error "pom.xml not found in current directory"
fi

info "Generating dependency checksums..."
info "  Transitive: $TRANSITIVE"
info "  Scope: $SCOPE"
info "  Output: $OUTPUT"

# Create output directory
OUTPUT_DIR="$(dirname "$OUTPUT")"
mkdir -p "$OUTPUT_DIR"

# Build temporary pom for dependency resolution
TEMP_POM=$(mktemp)
cat > "$TEMP_POM" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>temp</groupId>
    <artifactId>temp</artifactId>
    <version>1.0.0</version>
    <dependencies>
    </dependencies>
</project>
EOF

# Download dependencies and calculate checksums
info "Downloading dependencies..."
mvn dependency:resolve -DincludeScope=$SCOPE

info "Calculating checksums..."
if [ "$TRANSITIVE" = "true" ]; then
    mvn dependency:list -DincludeScope=$SCOPE -DoutputFile=dependency-list.txt
else
    mvn dependency:list -DincludeScope=$SCOPE -DexcludeTransitive=true -DoutputFile=dependency-list.txt
fi

# Generate checksum CSV
info "Generating $OUTPUT..."
echo "# Dependency Checksums (SHA-256)" > "$OUTPUT"
echo "# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$OUTPUT"
echo "# Scope: $SCOPE" >> "$OUTPUT"
echo "# Transitive: $TRANSITIVE" >> "$OUTPUT"

# Parse dependency list and calculate checksums
while IFS= read -r line; do
    clean_line="$(clean_maven_dependency_line "$line")"
    [[ -z "$clean_line" ]] && continue

    # Extract artifact coordinates
    if [[ "$clean_line" =~ ([^:]+):([^:]+):([^:]+):([^:]+):([^:]+) ]]; then
        GROUP_ID="${BASH_REMATCH[1]}"
        ARTIFACT_ID="${BASH_REMATCH[2]}"
        TYPE="${BASH_REMATCH[3]}"
        VERSION="${BASH_REMATCH[4]}"
        _SCOPE_FOUND="${BASH_REMATCH[5]}"

        # Find JAR in local repository
        JAR_PATH="$HOME/.m2/repository/${GROUP_ID//.//}/$ARTIFACT_ID/$VERSION/$ARTIFACT_ID-$VERSION.$TYPE"

        if [ -f "$JAR_PATH" ]; then
            CHECKSUM=$(openssl dgst -sha256 "$JAR_PATH" | awk '{print $2}')
            FILENAME=$(basename "$JAR_PATH")
            echo "$FILENAME,$CHECKSUM" >> "$OUTPUT"
            info "  ✓ $FILENAME"
        else
            warn "  ✗ File not found: $JAR_PATH"
        fi
    fi
done < dependency-list.txt

# Cleanup
rm -f dependency-list.txt "$TEMP_POM"

success "Checksums generated successfully: $OUTPUT"
info "$(grep -c "^[^#]" "$OUTPUT" || echo 0) dependencies processed"
