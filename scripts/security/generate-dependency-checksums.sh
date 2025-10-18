#!/usr/bin/env bash
#
# Generate dependency checksums for Maven projects
# This script downloads dependencies and generates SHA-256 checksums
# for security verification during builds and releases.
#
# Usage: ./generate-dependency-checksums.sh [OPTIONS]
#
# Options:
#   --transitive     Include transitive dependencies (default: false)
#   --scope SCOPE    Dependency scope to include (default: compile)
#   --output FILE    Output CSV file (default: security/dependency-checksums.csv)
#   --help           Show this help message
#

set -euo pipefail

# Default values
TRANSITIVE="false"
SCOPE="compile"
OUTPUT="security/dependency-checksums.csv"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Generate dependency checksums for Maven projects"
    echo ""
    echo "Options:"
    echo "  --transitive          Include transitive dependencies"
    echo "  --scope SCOPE         Dependency scope (default: compile)"
    echo "  --output FILE         Output CSV file (default: security/dependency-checksums.csv)"
    echo "  --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Generate checksums for direct compile dependencies"
    echo "  $0 --transitive                       # Include transitive dependencies"
    echo "  $0 --scope test --output test.csv     # Generate for test scope"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --transitive)
            TRANSITIVE="true"
            shift
            ;;
        --scope)
            SCOPE="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Check for Maven
if ! command -v mvn &> /dev/null; then
    log_error "Maven (mvn) not found in PATH"
    exit 1
fi

# Check for pom.xml
if [ ! -f "pom.xml" ]; then
    log_error "pom.xml not found in current directory"
    exit 1
fi

log_info "Generating dependency checksums..."
log_info "  Transitive: $TRANSITIVE"
log_info "  Scope: $SCOPE"
log_info "  Output: $OUTPUT"

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
log_info "Downloading dependencies..."
mvn dependency:resolve -DincludeScope=$SCOPE

log_info "Calculating checksums..."
if [ "$TRANSITIVE" = "true" ]; then
    mvn dependency:list -DincludeScope=$SCOPE -DoutputFile=dependency-list.txt
else
    mvn dependency:list -DincludeScope=$SCOPE -DexcludeTransitive=true -DoutputFile=dependency-list.txt
fi

# Generate checksum CSV
log_info "Generating $OUTPUT..."
echo "# Dependency Checksums (SHA-256)" > "$OUTPUT"
echo "# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$OUTPUT"
echo "# Scope: $SCOPE" >> "$OUTPUT"
echo "# Transitive: $TRANSITIVE" >> "$OUTPUT"

# Parse dependency list and calculate checksums
while IFS= read -r line; do
    # Skip non-dependency lines
    if [[ ! "$line" =~ ^[[:space:]]*[a-zA-Z] ]]; then
        continue
    fi

    # Extract artifact coordinates
    if [[ "$line" =~ ([^:]+):([^:]+):([^:]+):([^:]+):([^:]+) ]]; then
        GROUP_ID="${BASH_REMATCH[1]}"
        ARTIFACT_ID="${BASH_REMATCH[2]}"
        TYPE="${BASH_REMATCH[3]}"
        VERSION="${BASH_REMATCH[4]}"
        SCOPE_FOUND="${BASH_REMATCH[5]}"

        # Find JAR in local repository
        JAR_PATH="$HOME/.m2/repository/${GROUP_ID//.//}/$ARTIFACT_ID/$VERSION/$ARTIFACT_ID-$VERSION.$TYPE"

        if [ -f "$JAR_PATH" ]; then
            CHECKSUM=$(sha256sum "$JAR_PATH" | awk '{print $1}')
            FILENAME=$(basename "$JAR_PATH")
            echo "$FILENAME,$CHECKSUM" >> "$OUTPUT"
            log_info "  ✓ $FILENAME"
        else
            log_warn "  ✗ File not found: $JAR_PATH"
        fi
    fi
done < dependency-list.txt

# Cleanup
rm -f dependency-list.txt "$TEMP_POM"

log_info "✅ Checksums generated successfully: $OUTPUT"
log_info "$(grep -c "^[^#]" "$OUTPUT" || echo 0) dependencies processed"
