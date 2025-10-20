#!/usr/bin/env bash
#
# Team Branch Protection Script for GitHub Repositories
# Balanced protection - requires PR reviews but allows admin override
#
# Usage:
#   ./protect-main-branch-team.sh --repo artagon-common
#   ./protect-main-branch-team.sh --all
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_OWNER="artagon"
DEFAULT_BRANCH="main"
DEFAULT_REPOS=(
    "artagon-common"
    "artagon-license"
    "artagon-bom"
    "artagon-parent"
)

# Variables
OWNER=""
BRANCH=""
REPOS=()
PROCESS_ALL=false
FORCE=false

# Show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Apply team-level branch protection to GitHub repositories.

OPTIONS:
    -r, --repo REPO         Repository name (can be specified multiple times)
    -o, --owner OWNER       GitHub owner/organization (default: ${DEFAULT_OWNER})
    -b, --branch BRANCH     Branch name to protect (default: ${DEFAULT_BRANCH})
    -a, --all               Process all default repositories
    -f, --force             Skip confirmation prompt
    -h, --help              Show this help message

EXAMPLES:
    # Protect a single repository
    $0 --repo artagon-common

    # Protect multiple repositories
    $0 --repo artagon-bom --repo artagon-parent

    # Protect repository in different organization
    $0 --repo my-project --owner myorg

    # Protect all default repositories
    $0 --all

PROTECTION SETTINGS:
    ✅ Require 1 PR approval before merging
    ✅ Dismiss stale reviews
    ✅ Require conversation resolution
    ✅ Block force pushes
    ✅ Block branch deletion
    ❌ No status checks required
    ❌ No linear history requirement
    ❌ Not enforced for admins (emergency override allowed)

Best for: Team collaboration with code review

EOF
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--repo)
                REPOS+=("$2")
                shift 2
                ;;
            -o|--owner)
                OWNER="$2"
                shift 2
                ;;
            -b|--branch)
                BRANCH="$2"
                shift 2
                ;;
            -a|--all)
                PROCESS_ALL=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo -e "${RED}Error: Unknown option: $1${NC}"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Set defaults
    OWNER=${OWNER:-$DEFAULT_OWNER}
    BRANCH=${BRANCH:-$DEFAULT_BRANCH}

    # Determine which repos to process
    if [ "$PROCESS_ALL" = true ]; then
        REPOS=("${DEFAULT_REPOS[@]}")
    elif [ ${#REPOS[@]} -eq 0 ]; then
        echo -e "${RED}Error: No repositories specified${NC}"
        echo "Use --repo to specify repositories or --all for all default repos"
        echo "Use --help for more information"
        exit 1
    fi
}

# Function to apply branch protection
protect_branch() {
    local repo=$1
    local branch=$2

    echo -e "${YELLOW}Protecting branch '${branch}' in ${OWNER}/${repo}...${NC}"

    # Team-level branch protection configuration
    local protection_rules='{
        "required_status_checks": null,
        "enforce_admins": false,
        "required_pull_request_reviews": {
            "dismiss_stale_reviews": true,
            "require_code_owner_reviews": false,
            "required_approving_review_count": 1,
            "require_last_push_approval": false
        },
        "restrictions": null,
        "required_linear_history": false,
        "allow_force_pushes": false,
        "allow_deletions": false,
        "block_creations": false,
        "required_conversation_resolution": true,
        "lock_branch": false,
        "allow_fork_syncing": false
    }'

    # Apply protection using GitHub API
    if gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        "/repos/${OWNER}/${repo}/branches/${branch}/protection" \
        --input - <<< "$protection_rules" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Successfully protected ${OWNER}/${repo}:${branch}${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to protect ${OWNER}/${repo}:${branch}${NC}"
        echo -e "${YELLOW}  Check that the repository exists and you have admin access${NC}"
        return 1
    fi
}

# Main execution
main() {
    parse_args "$@"

    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Team Branch Protection Setup${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
    echo "Target repositories:"
    for repo in "${REPOS[@]}"; do
        echo "  - ${OWNER}/${repo}:${BRANCH}"
    done
    echo ""
    echo "Protection settings:"
    echo "  - Require pull request reviews: Yes (1 approval)"
    echo "  - Dismiss stale reviews: Yes"
    echo "  - Require conversation resolution: Yes"
    echo "  - Allow force pushes: No"
    echo "  - Allow branch deletion: No"
    echo "  - Enforce for admins: No (admins can override for emergencies)"
    echo ""

    if [ "$FORCE" != true ]; then
        read -p "Continue? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi
        echo ""
    fi

    # Apply protection to each repository
    success_count=0
    fail_count=0

    for repo in "${REPOS[@]}"; do
        if protect_branch "$repo" "$BRANCH"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
        echo ""
    done

    # Summary
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Summary${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo -e "${GREEN}Successful: ${success_count}${NC}"
    echo -e "${RED}Failed: ${fail_count}${NC}"
    echo ""

    if [ $fail_count -eq 0 ]; then
        echo -e "${GREEN}All branches protected successfully with team rules!${NC}"
        exit 0
    else
        echo -e "${YELLOW}Some branches failed to be protected. Check the output above.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
