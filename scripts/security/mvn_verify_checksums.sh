#!/usr/bin/env bash
# mvn_verify_checksums.sh
#
# Verifies SHA-256 and SHA-512 checksums for security baseline files.
#
# Usage:
#   mvn_verify_checksums.sh [OPTIONS] FILE [FILE...]
#
# Options:
#   --security-dir PATH    Path to security directory (default: current directory)
#   --help                 Show this help message
#
# Examples:
#   # Verify files in current directory
#   mvn_verify_checksums.sh file1.csv file2.list
#
#   # Verify files in specific directory
#   mvn_verify_checksums.sh --security-dir /path/to/security file1.csv file2.list

set -euo pipefail

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
mvn_verify_checksums.sh - Verify SHA checksums for security baseline files

Verifies SHA-256 and SHA-512 checksums against corresponding .sha256 and .sha512 files.

USAGE:
    mvn_verify_checksums.sh [OPTIONS] FILE [FILE...]

OPTIONS:
    -d, --security-dir PATH    Path to security directory (default: current directory)
    -h, --help                 Show this help message

FILES:
    Each FILE argument should be the name of a file to verify (without path).
    The script will look for FILE.sha256 and FILE.sha512 in the security directory.

EXAMPLES:
    # Verify files in current directory
    mvn_verify_checksums.sh file1.csv file2.list

    # Verify files in specific directory
    mvn_verify_checksums.sh --security-dir /path/to/security file1.csv file2.list

EXIT CODES:
    0   All checksums verified successfully
    1   Checksum verification failed or error occurred

EOF
}

# Default configuration
SECURITY_DIR="$(pwd)"
FILES=()

# Parse command line arguments (portable - works on BSD and GNU)
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--security-dir)
            if [[ -z "$2" || "$2" == -* ]]; then
                error "Option $1 requires an argument"
            fi
            SECURITY_DIR="$2"
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
            # Positional argument - add to files list
            FILES+=("$1")
            shift
            ;;
    esac
done

# Validate security directory
if [[ ! -d "${SECURITY_DIR}" ]]; then
    error "Security directory does not exist: ${SECURITY_DIR}"
fi

# Validate at least one file provided
if [[ ${#FILES[@]} -eq 0 ]]; then
    error "No files specified for verification"
fi

# Change to security directory
cd "${SECURITY_DIR}"

# Verify each file
verified=0
_failed=0

for file in "${FILES[@]}"; do
    if [[ ! -f "${file}" ]]; then
        warn "File not found: ${file}, skipping"
        continue
    fi

    echo "Verifying ${file} checksums..."

    # Verify SHA-256
    if [[ -f "${file}.sha256" ]]; then
        expected=$(cat "${file}.sha256")
        actual=$(openssl dgst -sha256 "${file}" | awk '{print $2}')

        if [[ "${expected}" != "${actual}" ]]; then
            error "SHA-256 checksum mismatch for ${file}
Expected: ${expected}
Actual:   ${actual}"
        fi

        echo "  SHA-256: OK"
        verified=$((verified + 1))
    else
        warn "  No SHA-256 checksum file found (${file}.sha256)"
    fi

    # Verify SHA-512
    if [[ -f "${file}.sha512" ]]; then
        expected=$(cat "${file}.sha512")
        actual=$(openssl dgst -sha512 "${file}" | awk '{print $2}')

        if [[ "${expected}" != "${actual}" ]]; then
            error "SHA-512 checksum mismatch for ${file}
Expected: ${expected}
Actual:   ${actual}"
        fi

        echo "  SHA-512: OK"
        verified=$((verified + 1))
    else
        warn "  No SHA-512 checksum file found (${file}.sha512)"
    fi
done

if [[ ${verified} -gt 0 ]]; then
    success "Verified ${verified} checksum(s) successfully"
else
    warn "No checksums were verified"
fi

exit 0
