#!/bin/bash
#
# Team Branch Protection Script for Artagon Projects
# Balanced protection for team collaboration - requires reviews but allows admin override
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
echo -e "${BLUE}Team Branch Protection Setup${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Function to apply team-level branch protection
protect_branch_team() {
    local repo=$1
    local branch=$2

    echo -e "${YELLOW}Applying team protection to '${branch}' in ${ORG}/${repo}...${NC}"

    # Team-level branch protection configuration
    # Balanced approach: require reviews but allow admin override
    local protection_rules='{
        "required_status_checks": null,
        "enforce_admins": false,
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
    echo "This script will apply TEAM-LEVEL branch protection to the following repositories:"
    echo ""
    for repo in "${REPOS[@]}"; do
        echo "  - ${ORG}/${repo}"
    done
    echo ""
    echo -e "${BLUE}Team protection settings:${NC}"
    echo "  - Require pull request reviews: YES (1 approval required)"
    echo "  - Dismiss stale reviews: YES"
    echo "  - Require conversation resolution: YES"
    echo "  - Allow force pushes: NO"
    echo "  - Allow branch deletion: NO"
    echo "  - Enforce for admins: NO (admins can override for emergencies)"
    echo ""
    echo -e "${GREEN}✓ Good for: Team collaboration with code review${NC}"
    echo -e "${GREEN}✓ Admins can still push directly in emergencies${NC}"
    echo -e "${GREEN}✓ Allows merge commits (no linear history requirement)${NC}"
    echo -e "${GREEN}✓ No CI/CD requirements (status checks optional)${NC}"
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
        if protect_branch_team "$repo" "$BRANCH"; then
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
        echo ""
        echo "Next steps:"
        echo "  1. Team members should create branches for their work"
        echo "  2. Submit pull requests when ready for review"
        echo "  3. Get 1 approval before merging"
        echo "  4. Admins can still push directly if needed for emergencies"
    else
        echo -e "${YELLOW}Some branches failed to be protected. Check the output above.${NC}"
    fi
}

# Run main function
main
