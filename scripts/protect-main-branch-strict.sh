#!/bin/bash
#
# Strict Branch Protection Script for Artagon Projects
# Applies strict branch protection rules with PR reviews required
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub organization
ORG="artagon"

# List of repositories to protect
REPOS=(
    "artagon-common"
    "artagon-license"
    "artagon-bom"
    "artagon-parent"
)

# Branch to protect
BRANCH="main"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Strict Branch Protection Setup${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Function to apply strict branch protection
protect_branch_strict() {
    local repo=$1
    local branch=$2

    echo -e "${YELLOW}Applying strict protection to '${branch}' in ${ORG}/${repo}...${NC}"

    # Strict branch protection configuration
    local protection_rules='{
        "required_status_checks": {
            "strict": true,
            "contexts": []
        },
        "enforce_admins": true,
        "required_pull_request_reviews": {
            "dismiss_stale_reviews": true,
            "require_code_owner_reviews": false,
            "required_approving_review_count": 1,
            "require_last_push_approval": false,
            "bypass_pull_request_allowances": {
                "users": [],
                "teams": [],
                "apps": []
            }
        },
        "restrictions": null,
        "required_linear_history": true,
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
        "/repos/${ORG}/${repo}/branches/${branch}/protection" \
        --input - <<< "$protection_rules" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Successfully protected ${ORG}/${repo}:${branch}${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to protect ${ORG}/${repo}:${branch}${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo "This script will apply STRICT branch protection to the following repositories:"
    echo ""
    for repo in "${REPOS[@]}"; do
        echo "  - ${ORG}/${repo}"
    done
    echo ""
    echo -e "${YELLOW}⚠️  STRICT protection settings:${NC}"
    echo "  - Require pull request reviews: YES (1 approval required)"
    echo "  - Dismiss stale reviews: YES"
    echo "  - Require status checks: YES"
    echo "  - Require linear history: YES (no merge commits)"
    echo "  - Require conversation resolution: YES"
    echo "  - Allow force pushes: NO"
    echo "  - Allow branch deletion: NO"
    echo "  - Enforce for admins: YES (even you must follow rules)"
    echo ""
    echo -e "${RED}WARNING: With these settings, you will need to create PRs for all changes!${NC}"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi

    echo ""

    # Apply protection to each repository
    success_count=0
    fail_count=0

    for repo in "${REPOS[@]}"; do
        if protect_branch_strict "$repo" "$BRANCH"; then
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
        echo -e "${GREEN}All branches protected successfully with strict rules!${NC}"
    else
        echo -e "${YELLOW}Some branches failed to be protected. Check the output above.${NC}"
    fi
}

# Run main function
main
