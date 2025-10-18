#!/bin/bash
#
# Check Branch Protection Status for Artagon Projects
# Shows current protection settings for all repositories
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# GitHub organization
ORG="artagon"

# List of repositories to check
REPOS=(
    "artagon-common"
    "artagon-license"
    "artagon-bom"
    "artagon-parent"
)

# Branch to check
BRANCH="main"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Branch Protection Status${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Function to check and display branch protection
check_protection() {
    local repo=$1
    local branch=$2

    echo -e "${CYAN}Repository: ${ORG}/${repo}${NC}"
    echo -e "${CYAN}Branch: ${branch}${NC}"
    echo -e "${CYAN}----------------------------------------${NC}"

    # Check if protection exists
    if protection=$(gh api "/repos/${ORG}/${repo}/branches/${branch}/protection" 2>/dev/null); then
        echo -e "${GREEN}✓ Branch protection is ENABLED${NC}"
        echo ""

        # Parse and display key settings
        echo "Settings:"

        # Required pull request reviews
        if echo "$protection" | jq -e '.required_pull_request_reviews' > /dev/null 2>&1; then
            reviews=$(echo "$protection" | jq -r '.required_pull_request_reviews.required_approving_review_count')
            dismiss_stale=$(echo "$protection" | jq -r '.required_pull_request_reviews.dismiss_stale_reviews')
            echo "  • Require PR reviews: YES (${reviews} approval(s) required)"
            echo "  • Dismiss stale reviews: ${dismiss_stale}"
        else
            echo "  • Require PR reviews: NO"
        fi

        # Status checks
        if echo "$protection" | jq -e '.required_status_checks' > /dev/null 2>&1; then
            strict=$(echo "$protection" | jq -r '.required_status_checks.strict // false')
            contexts=$(echo "$protection" | jq -r '.required_status_checks.contexts // [] | length')
            echo "  • Require status checks: YES (${contexts} check(s), strict: ${strict})"
        else
            echo "  • Require status checks: NO"
        fi

        # Other settings
        enforce_admins=$(echo "$protection" | jq -r '.enforce_admins.enabled // false')
        linear_history=$(echo "$protection" | jq -r '.required_linear_history.enabled // false')
        force_push=$(echo "$protection" | jq -r '.allow_force_pushes.enabled // false')
        deletions=$(echo "$protection" | jq -r '.allow_deletions.enabled // false')
        conversations=$(echo "$protection" | jq -r '.required_conversation_resolution.enabled // false')

        echo "  • Enforce for admins: ${enforce_admins}"
        echo "  • Require linear history: ${linear_history}"
        echo "  • Allow force pushes: ${force_push}"
        echo "  • Allow deletions: ${deletions}"
        echo "  • Require conversation resolution: ${conversations}"

    else
        echo -e "${RED}✗ Branch protection is DISABLED${NC}"
        echo ""
        echo "The main branch is not protected. Anyone with write access can:"
        echo "  • Push directly to main"
        echo "  • Force push and rewrite history"
        echo "  • Delete the branch"
        echo ""
        echo -e "${YELLOW}Run ./protect-main-branch.sh to enable protection${NC}"
    fi

    echo ""
}

# Main execution
main() {
    for repo in "${REPOS[@]}"; do
        check_protection "$repo" "$BRANCH"
    done

    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Done${NC}"
    echo -e "${BLUE}======================================${NC}"
}

# Run main function
main
