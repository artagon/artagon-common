#!/usr/bin/env bash
#
# Strict Branch Protection Script for GitHub Repositories
# Maximum protection - enforced for everyone including admins
#
# Usage:
#   ./gh_protect_main_strict.sh --repo artagon-common
#   ./gh_protect_main_strict.sh --all
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
DEFAULT_OWNER="artagon"
DEFAULT_BRANCH="main"
DEFAULT_REPOS=("artagon-common" "artagon-license" "artagon-bom" "artagon-parent")

# Variables
OWNER=""
BRANCH=""
REPOS=()
PROCESS_ALL=false
FORCE=false

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Apply strict branch protection to GitHub repositories.

OPTIONS:
    -r, --repo REPO         Repository name (repeatable)
    -o, --owner OWNER       GitHub owner/org (default: ${DEFAULT_OWNER})
    -b, --branch BRANCH     Branch to protect (default: ${DEFAULT_BRANCH})
    -a, --all               Process all default repositories
    -f, --force             Skip confirmation
    -h, --help              Show help

PROTECTION SETTINGS:
    ✅ Require 1 PR approval
    ✅ Dismiss stale reviews
    ✅ Require status checks
    ✅ Require linear history
    ✅ Require conversation resolution
    ✅ Block force pushes
    ✅ Block branch deletion
    ✅ Enforced for admins (NO override!)

Best for: Compliance environments, open source projects

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
            -f|--force) FORCE=true; shift;;
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

protect_branch() {
    local repo=$1 branch=$2
    echo -e "${YELLOW}Protecting '${branch}' in ${OWNER}/${repo}...${NC}"
    
    local rules='{
        "required_status_checks": {"strict": true, "contexts": []},
        "enforce_admins": true,
        "required_pull_request_reviews": {
            "dismiss_stale_reviews": true,
            "require_code_owner_reviews": false,
            "required_approving_review_count": 1
        },
        "restrictions": null,
        "required_linear_history": true,
        "allow_force_pushes": false,
        "allow_deletions": false,
        "required_conversation_resolution": true,
        "lock_branch": false
    }'
    
    if gh api --method PUT -H "Accept: application/vnd.github+json" \
        "/repos/${OWNER}/${repo}/branches/${branch}/protection" \
        --input - <<< "$rules" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Successfully protected ${OWNER}/${repo}:${branch}${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to protect ${OWNER}/${repo}:${branch}${NC}"
        return 1
    fi
}

main() {
    parse_args "$@"
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Strict Branch Protection Setup${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
    for repo in "${REPOS[@]}"; do echo "  - ${OWNER}/${repo}:${BRANCH}"; done
    echo ""
    
    if [ "$FORCE" != true ]; then
        read -p "⚠️  WARNING: This enforces rules for EVERYONE (including admins). Continue? (y/n) " -r
        echo; [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    fi
    
    success=0 fail=0
    for repo in "${REPOS[@]}"; do
        protect_branch "$repo" "$BRANCH" && ((success++)) || ((fail++))
        echo ""
    done
    
    echo -e "${BLUE}Summary: ${GREEN}Success: $success ${RED}Failed: $fail${NC}\n"
    [ $fail -eq 0 ] && exit 0 || exit 1
}

main "$@"
