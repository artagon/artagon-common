#!/usr/bin/env bash
# update-dependency-security.sh
#
# Updates dependency security baseline files (checksums and PGP keys) for Maven projects.
# Can operate in two modes: update (regenerate baselines) or verify (check against existing).
#
# This script:
# 1. Resolves all compile-scope dependencies (including transitives)
# 2. Downloads artifacts and their PGP signatures from Maven Central
# 3. Computes SHA-256 checksums for each artifact
# 4. Extracts PGP fingerprints from signatures
# 5. Generates or verifies security baseline files
#
# Usage:
#   update-dependency-security.sh [OPTIONS]
#
# Options:
#   --project-root PATH      Path to Maven project root (default: current directory)
#   --security-dir PATH      Path to security directory (default: <project-root>/security)
#   --checksum-format FMT    Format for checksums: 'csv' or 'properties' (default: csv)
#   --scopes SCOPES          Maven scopes to include, comma-separated (default: compile)
#   --transitive BOOL        Include transitive dependencies: true or false (default: true)
#   --update                 Update mode: regenerate baseline files (default)
#   --verify                 Verify mode: check existing baselines are current
#   --maven-cmd CMD          Maven command to use (default: mvn)
#   --help                   Show this help message
#
# Examples:
#   # Update baselines for current project
#   ./update-dependency-security.sh --update
#
#   # Verify baselines are current
#   ./update-dependency-security.sh --verify
#
#   # Update for specific project
#   ./update-dependency-security.sh --project-root /path/to/project --update
#
#   # Use properties format instead of CSV
#   ./update-dependency-security.sh --checksum-format properties --update

set -euo pipefail

# Default configuration
PROJECT_ROOT="$(pwd)"
SECURITY_DIR=""
CHECKSUM_FORMAT="csv"
MAVEN_SCOPES="compile"
TRANSITIVE="true"
MODE="update"
MVN_CMD="mvn"
REPO_BASE="https://repo1.maven.org/maven2"
LOCAL_REPO="${LOCAL_REPO:-${HOME}/.m2/repository}"

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
update-dependency-security.sh - Update Maven dependency security baselines

Updates or verifies dependency checksums and PGP key fingerprints for Maven projects.

USAGE:
    update-dependency-security.sh [OPTIONS]

OPTIONS:
    -p, --project-root PATH      Path to Maven project root (default: current directory)
    -s, --security-dir PATH      Path to security directory (default: <project-root>/security)
    -f, --checksum-format FMT    Format for checksums: 'csv' or 'properties' (default: csv)
    -S, --scopes SCOPES          Maven scopes to include, comma-separated (default: compile)
    -t, --transitive BOOL        Include transitive dependencies: true or false (default: true)
    -u, --update                 Update mode: regenerate baseline files (default)
    -v, --verify                 Verify mode: check existing baselines are current
    -m, --maven-cmd CMD          Maven command to use (default: mvn)
    -h, --help                   Show this help message

FILES GENERATED:
    {groupId}-{artifactId}-dependency-checksums.csv         SHA-256 checksums (CSV format)
    {groupId}-{artifactId}-dependency-checksums.properties  SHA-256 checksums (properties format)
    {groupId}-{artifactId}-pgp-trusted-keys.list           Trusted PGP fingerprints

    Where {groupId} and {artifactId} are the full Maven coordinates.
    For example, groupId="com.artagon" and artifactId="artagon-parent" generates:
      - com.artagon-artagon-parent-dependency-checksums.csv
      - com.artagon-artagon-parent-pgp-trusted-keys.list

EXAMPLES:
    # Update baselines for current project
    ./update-dependency-security.sh -u

    # Verify baselines are current
    ./update-dependency-security.sh -v

    # Update for specific project with properties format
    ./update-dependency-security.sh \
        -p /path/to/project \
        -f properties \
        -u

    # Only include compile scope, no transitives
    ./update-dependency-security.sh \
        -S compile \
        -t false \
        -u

EOF
}

# Parse command line arguments (portable - works on BSD and GNU)
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--project-root)
            if [[ -z "$2" || "$2" == -* ]]; then
                error "Option $1 requires an argument"
            fi
            PROJECT_ROOT="$2"
            shift 2
            ;;
        -s|--security-dir)
            if [[ -z "$2" || "$2" == -* ]]; then
                error "Option $1 requires an argument"
            fi
            SECURITY_DIR="$2"
            shift 2
            ;;
        -f|--checksum-format)
            if [[ -z "$2" || "$2" == -* ]]; then
                error "Option $1 requires an argument"
            fi
            CHECKSUM_FORMAT="$2"
            shift 2
            ;;
        -S|--scopes)
            if [[ -z "$2" || "$2" == -* ]]; then
                error "Option $1 requires an argument"
            fi
            MAVEN_SCOPES="$2"
            shift 2
            ;;
        -t|--transitive)
            if [[ -z "$2" || "$2" == -* ]]; then
                error "Option $1 requires an argument"
            fi
            TRANSITIVE="$2"
            shift 2
            ;;
        -u|--update)
            MODE="update"
            shift
            ;;
        -v|--verify)
            MODE="verify"
            shift
            ;;
        -m|--maven-cmd)
            if [[ -z "$2" || "$2" == -* ]]; then
                error "Option $1 requires an argument"
            fi
            MVN_CMD="$2"
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

# Validate project root
if [[ ! -d "${PROJECT_ROOT}" ]]; then
    error "Project root does not exist: ${PROJECT_ROOT}"
fi

if [[ ! -f "${PROJECT_ROOT}/pom.xml" ]]; then
    error "No pom.xml found in project root: ${PROJECT_ROOT}"
fi

# Set security directory default if not specified
if [[ -z "${SECURITY_DIR}" ]]; then
    SECURITY_DIR="${PROJECT_ROOT}/security"
fi

# Validate checksum format
case "${CHECKSUM_FORMAT}" in
    csv|properties)
        ;;
    *)
        error "Invalid checksum format: ${CHECKSUM_FORMAT}\nSupported formats: csv, properties"
        ;;
esac

# Validate transitive flag
case "${TRANSITIVE}" in
    true|false)
        ;;
    *)
        error "Invalid transitive flag: ${TRANSITIVE}\nMust be 'true' or 'false'"
        ;;
esac

# Ensure required tools are present
for tool in curl gpg openssl "${MVN_CMD}"; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        error "Required tool '${tool}' not found on PATH"
    fi
done

info "Project root: ${PROJECT_ROOT}"
info "Security directory: ${SECURITY_DIR}"
info "Checksum format: ${CHECKSUM_FORMAT}"
info "Maven scopes: ${MAVEN_SCOPES}"
info "Include transitives: ${TRANSITIVE}"
info "Mode: ${MODE}"

# Get groupId and artifactId from Maven
cd "${PROJECT_ROOT}"
GROUP_ID=$("${MVN_CMD}" help:evaluate -Dexpression=project.groupId -q -DforceStdout 2>/dev/null | grep -v "^WARNING")
ARTIFACT_ID=$("${MVN_CMD}" help:evaluate -Dexpression=project.artifactId -q -DforceStdout 2>/dev/null | grep -v "^WARNING")

if [[ -z "${GROUP_ID}" || -z "${ARTIFACT_ID}" ]]; then
    error "Failed to determine Maven coordinates (groupId: ${GROUP_ID}, artifactId: ${ARTIFACT_ID})"
fi

# Build file prefix using full Maven coordinates (e.g., "org.artagon-artagon-parent")
FILE_PREFIX="${GROUP_ID}-${ARTIFACT_ID}"

info "Group ID: ${GROUP_ID}"
info "Artifact ID: ${ARTIFACT_ID}"
info "Using file prefix: ${FILE_PREFIX}"

# Determine output files based on format
if [[ "${CHECKSUM_FORMAT}" == "csv" ]]; then
    CHECKSUM_FILE="${SECURITY_DIR}/${FILE_PREFIX}-dependency-checksums.csv"
else
    CHECKSUM_FILE="${SECURITY_DIR}/${FILE_PREFIX}-dependency-checksums.properties"
fi
KEYS_FILE="${SECURITY_DIR}/${FILE_PREFIX}-pgp-trusted-keys.list"

# Create temporary files
tmp_checks="$(mktemp)"
tmp_keys="$(mktemp)"
tmp_deps="$(mktemp)"
cleanup() {
    rm -f "${tmp_checks}" "${tmp_keys}" "${tmp_deps}"
}
trap cleanup EXIT

# Initialize temp files
if [[ "${CHECKSUM_FORMAT}" == "csv" ]]; then
    echo "#File,SHA-256" > "${tmp_checks}"
else
    printf '' > "${tmp_checks}"
fi

{
    echo "# Trusted PGP fingerprints for dependency verification"
    echo "# Generated by scripts/security/update-dependency-security.sh"
    echo "# Project: ${PROJECT_ROOT}"
    echo "# Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    echo
} > "${tmp_keys}"

# Get list of dependencies from Maven
info "Resolving dependencies from Maven..."
cd "${PROJECT_ROOT}"

# Build Maven command to list dependencies
MAVEN_OPTS="-q -DincludeScope=${MAVEN_SCOPES} -DoutputFile=${tmp_deps}"
if [[ "${TRANSITIVE}" == "true" ]]; then
    MAVEN_OPTS="${MAVEN_OPTS} -DexcludeTransitive=false"
else
    MAVEN_OPTS="${MAVEN_OPTS} -DexcludeTransitive=true"
fi

if ! "${MVN_CMD}" dependency:list ${MAVEN_OPTS} >/dev/null 2>&1; then
    error "Failed to resolve dependencies with Maven"
fi

# Parse dependency list and extract coordinates
# Expected format: groupId:artifactId:packaging:version:scope
declare -a DEP_COORDS=()
while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue

    # Extract coordinates (format: groupId:artifactId:packaging:version:scope)
    if [[ "${line}" =~ ^[[:space:]]*([^:]+):([^:]+):([^:]+):([^:]+):([^:]+) ]]; then
        group="${BASH_REMATCH[1]}"
        artifact="${BASH_REMATCH[2]}"
        packaging="${BASH_REMATCH[3]}"
        version="${BASH_REMATCH[4]}"
        scope="${BASH_REMATCH[5]}"

        # Only process jar artifacts in specified scopes
        if [[ "${packaging}" == "jar" ]]; then
            DEP_COORDS+=("${group}:${artifact}:${version}")
        fi
    fi
done < "${tmp_deps}"

if [[ ${#DEP_COORDS[@]} -eq 0 ]]; then
    error "No dependencies found in scope '${MAVEN_SCOPES}'"
fi

info "Found ${#DEP_COORDS[@]} dependencies to process"

# Load special key flags if config file exists
declare -A SPECIAL_KEY_FLAGS=()
SPECIAL_KEYS_CONFIG="${SECURITY_DIR}/special-keys.conf"
if [[ -f "${SPECIAL_KEYS_CONFIG}" ]]; then
    info "Loading special key flags from ${SPECIAL_KEYS_CONFIG}"
    while IFS='=' read -r coord flag; do
        # Skip empty lines and comments
        [[ -z "${coord}" || "${coord}" =~ ^[[:space:]]*# ]] && continue
        coord="$(echo "${coord}" | xargs)"  # trim whitespace
        flag="$(echo "${flag}" | xargs)"
        SPECIAL_KEY_FLAGS["${coord}"]="${flag}"
    done < "${SPECIAL_KEYS_CONFIG}"
fi

# Process each dependency
processed=0
for coord in "${DEP_COORDS[@]}"; do
    IFS=':' read -r group artifact version <<<"${coord}"

    info "Processing ${group}:${artifact}:${version}"

    group_path="${group//./\/}"
    jar="${artifact}-${version}.jar"
    jar_path="${LOCAL_REPO}/${group_path}/${artifact}/${version}/${jar}"
    jar_url="${REPO_BASE}/${group_path}/${artifact}/${version}/${jar}"
    sig_url="${jar_url}.asc"

    # Ensure artifact is in local repository
    if [[ ! -f "${jar_path}" ]]; then
        info "  Downloading ${jar}..."
        if ! "${MVN_CMD}" -q dependency:get -Dartifact="${group}:${artifact}:${version}" -Dtransitive=false >/dev/null 2>&1; then
            warn "  Failed to download ${group}:${artifact}:${version}, skipping"
            continue
        fi
    fi

    if [[ ! -f "${jar_path}" ]]; then
        warn "  Jar ${jar_path} not found after resolution, skipping"
        continue
    fi

    # Compute SHA-256 checksum
    sha256="$(openssl dgst -sha256 "${jar_path}" | awk '{print $2}')"
    if [[ -z "${sha256}" ]]; then
        warn "  Failed to compute SHA-256 for ${jar}, skipping"
        continue
    fi

    # Write checksum in appropriate format
    if [[ "${CHECKSUM_FORMAT}" == "csv" ]]; then
        echo "${jar},${sha256}" >> "${tmp_checks}"
    else
        echo "${group}:${artifact}:${version}=${sha256}" >> "${tmp_checks}"
    fi

    # Download and process PGP signature
    sig_path="${jar_path}.asc"
    sig_tmp="$(mktemp)"

    if [[ -f "${sig_path}" ]]; then
        cp "${sig_path}" "${sig_tmp}"
    else
        info "  Downloading signature..."
        if ! curl -sSfL "${sig_url}" -o "${sig_tmp}" 2>/dev/null; then
            warn "  Failed to download signature ${sig_url}"
            # Mark as noKey if signature unavailable
            printf "%s:%s = noKey\n" "${group}" "${artifact}" >> "${tmp_keys}"
            rm -f "${sig_tmp}"
            ((processed++))
            continue
        fi
        cp "${sig_tmp}" "${sig_path}"
    fi

    # Extract PGP fingerprint
    fingerprint="$(gpg --list-packets "${sig_tmp}" 2>/dev/null | awk '/issuer fpr/ {print $NF; exit}')"
    fingerprint="${fingerprint//[\(\)]/}"

    if [[ -z "${fingerprint}" ]]; then
        warn "  Unable to extract fingerprint from ${sig_url}"
        printf "%s:%s = noKey\n" "${group}" "${artifact}" >> "${tmp_keys}"
        rm -f "${sig_tmp}"
        ((processed++))
        continue
    fi

    # Build key entry with any special flags
    key_entry="0x${fingerprint}"
    special_flag="${SPECIAL_KEY_FLAGS["${group}:${artifact}"]:-}"
    if [[ -n "${special_flag}" ]]; then
        key_entry="${key_entry}, ${special_flag}"
    fi
    printf "%s:%s = %s\n" "${group}" "${artifact}" "${key_entry}" >> "${tmp_keys}"

    rm -f "${sig_tmp}"
    ((processed++))
done

info "Processed ${processed} dependencies"

# Create security directory if needed
mkdir -p "${SECURITY_DIR}"

# Verify or update mode
if [[ "${MODE}" == "verify" ]]; then
    info "Verifying existing baseline files..."

    if [[ ! -f "${CHECKSUM_FILE}" ]]; then
        error "Checksum file does not exist: ${CHECKSUM_FILE}"
    fi

    if [[ ! -f "${KEYS_FILE}" ]]; then
        error "Keys file does not exist: ${KEYS_FILE}"
    fi

    if ! cmp -s "${tmp_checks}" "${CHECKSUM_FILE}"; then
        error "Checksum file ${CHECKSUM_FILE} is out of date.\nRun with --update to regenerate."
    fi

    if ! cmp -s "${tmp_keys}" "${KEYS_FILE}"; then
        error "PGP key file ${KEYS_FILE} is out of date.\nRun with --update to regenerate."
    fi

    success "Dependency checksums and PGP keys verified successfully"
else
    info "Updating baseline files..."

    mv "${tmp_checks}" "${CHECKSUM_FILE}"
    mv "${tmp_keys}" "${KEYS_FILE}"

    success "Updated ${CHECKSUM_FILE}"
    success "Updated ${KEYS_FILE}"

    # Generate SHA-256 and SHA-512 checksums for the security files
    info "Generating SHA-256 and SHA-512 checksums for security files..."

    openssl dgst -sha256 "${CHECKSUM_FILE}" | awk '{print $2}' > "${CHECKSUM_FILE}.sha256"
    openssl dgst -sha512 "${CHECKSUM_FILE}" | awk '{print $2}' > "${CHECKSUM_FILE}.sha512"
    success "Updated ${CHECKSUM_FILE}.sha256"
    success "Updated ${CHECKSUM_FILE}.sha512"

    openssl dgst -sha256 "${KEYS_FILE}" | awk '{print $2}' > "${KEYS_FILE}.sha256"
    openssl dgst -sha512 "${KEYS_FILE}" | awk '{print $2}' > "${KEYS_FILE}.sha512"
    success "Updated ${KEYS_FILE}.sha256"
    success "Updated ${KEYS_FILE}.sha512"

    echo ""
    info "Baseline files and checksums have been updated. Review and commit them:"
    echo "  git add ${CHECKSUM_FILE}* ${KEYS_FILE}*"
    echo "  git commit -m \"Update dependency security baselines and checksums\""
fi
