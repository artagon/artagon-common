#!/bin/bash
#
# Branch Protection Script for Artagon Projects
# Applies consistent branch protection rules to main branches
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
echo -e "${BLUE}Branch Protection Setup${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Function to apply branch protection
protect_branch() {
    local repo=$1
    local branch=$2

    echo -e "${YELLOW}Protecting branch '${branch}' in ${ORG}/${repo}...${NC}"

    # Branch protection configuration
    # Customize these settings based on your needs
    local protection_rules='{
        "required_status_checks": null,
        "enforce_admins": false,
        "required_pull_request_reviews": {
            "dismiss_stale_reviews": false,
            "require_code_owner_reviews": false,
            "required_approving_review_count": 0,
            "require_last_push_approval": false
        },
        "restrictions": null,
        "required_linear_history": false,
        "allow_force_pushes": false,
        "allow_deletions": false,
        "block_creations": false,
        "required_conversation_resolution": false,
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

# Function to show current protection status
show_protection_status() {
    local repo=$1
    local branch=$2

    echo -e "${BLUE}Current protection for ${ORG}/${repo}:${branch}${NC}"

    if gh api "/repos/${ORG}/${repo}/branches/${branch}/protection" 2>/dev/null; then
        echo ""
    else
        echo -e "${YELLOW}No protection currently enabled${NC}"
        echo ""
    fi
}

# Main execution
main() {
    echo "This script will apply branch protection to the following repositories:"
    echo ""
    for repo in "${REPOS[@]}"; do
        echo "  - ${ORG}/${repo}"
    done
    echo ""
    echo "Protection settings:"
    echo "  - Require pull request reviews: No (for solo development)"
    echo "  - Allow force pushes: No"
    echo "  - Allow branch deletion: No"
    echo "  - Enforce for admins: No (you can still override)"
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
        echo -e "${GREEN}All branches protected successfully!${NC}"
    else
        echo -e "${YELLOW}Some branches failed to be protected. Check the output above.${NC}"
    fi
}

# Run main function
main
