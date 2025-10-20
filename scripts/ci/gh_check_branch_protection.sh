#!/usr/bin/env bash
#
# Check Branch Protection Status for GitHub Repositories
#
# Usage:
#   ./check-branch-protection.sh --repo artagon-common
#   ./check-branch-protection.sh --all
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Defaults
DEFAULT_OWNER="artagon"
DEFAULT_BRANCH="main"
DEFAULT_REPOS=("artagon-common" "artagon-license" "artagon-bom" "artagon-parent")

OWNER=""
BRANCH=""
REPOS=()
PROCESS_ALL=false

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Check branch protection status for GitHub repositories.

OPTIONS:
    -r, --repo REPO         Repository name (repeatable)
    -o, --owner OWNER       GitHub owner/org (default: ${DEFAULT_OWNER})
    -b, --branch BRANCH     Branch to check (default: ${DEFAULT_BRANCH})
    -a, --all               Check all default repositories
    -h, --help              Show help

EXAMPLES:
    $0 --repo artagon-common
    $0 --all
    $0 --repo my-project --owner myorg

EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--repo) REPOS+=("$2"); shift 2;;
            -o|--owner) OWNER="$2"; shift 2;;
            -b|--branch) BRANCH="$2"; shift 2;;
            -a|--all) PROCESS_ALL=true; shift;;
            -h|--help) usage;;
            *) echo -e "${RED}Error: Unknown option: $1${NC}"; exit 1;;
        esac
    done
    OWNER=${OWNER:-$DEFAULT_OWNER}
    BRANCH=${BRANCH:-$DEFAULT_BRANCH}
    if [ "$PROCESS_ALL" = true ]; then
        REPOS=("${DEFAULT_REPOS[@]}")
    elif [ ${#REPOS[@]} -eq 0 ]; then
        echo -e "${RED}Error: No repositories specified${NC}"; exit 1
    fi
}

check_protection() {
    local repo=$1 branch=$2
    echo -e "${CYAN}Repository: ${OWNER}/${repo}${NC}"
    echo -e "${CYAN}Branch: ${branch}${NC}"
    echo -e "${CYAN}----------------------------------------${NC}"
    
    if protection=$(gh api "/repos/${OWNER}/${repo}/branches/${branch}/protection" 2>/dev/null); then
        echo -e "${GREEN}✓ Branch protection is ENABLED${NC}\n"
        
        # Parse key settings
        if echo "$protection" | jq -e '.required_pull_request_reviews' > /dev/null 2>&1; then
            reviews=$(echo "$protection" | jq -r '.required_pull_request_reviews.required_approving_review_count')
            dismiss=$(echo "$protection" | jq -r '.required_pull_request_reviews.dismiss_stale_reviews')
            echo "  • Require PR reviews: YES ($reviews approval(s))"
            echo "  • Dismiss stale reviews: $dismiss"
        else
            echo "  • Require PR reviews: NO"
        fi
        
        enforce=$(echo "$protection" | jq -r '.enforce_admins.enabled // false')
        linear=$(echo "$protection" | jq -r '.required_linear_history.enabled // false')
        force=$(echo "$protection" | jq -r '.allow_force_pushes.enabled // false')
        delete=$(echo "$protection" | jq -r '.allow_deletions.enabled // false')
        conv=$(echo "$protection" | jq -r '.required_conversation_resolution.enabled // false')
        
        echo "  • Enforce for admins: $enforce"
        echo "  • Require linear history: $linear"
        echo "  • Allow force pushes: $force"
        echo "  • Allow deletions: $delete"
        echo "  • Require conversation resolution: $conv"
    else
        echo -e "${RED}✗ Branch protection is DISABLED${NC}"
    fi
    echo ""
}

main() {
    parse_args "$@"
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Branch Protection Status${NC}"
    echo -e "${BLUE}======================================${NC}\n"
    
    for repo in "${REPOS[@]}"; do
        check_protection "$repo" "$BRANCH"
    done
}

main "$@"
