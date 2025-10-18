#!/bin/bash
#
# Remove Branch Protection for Artagon Projects
# Removes branch protection rules from specified repositories
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

# List of repositories
REPOS=(
    "artagon-common"
    "artagon-license"
    "artagon-bom"
    "artagon-parent"
)

# Branch to unprotect
BRANCH="main"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Remove Branch Protection${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Function to remove branch protection
remove_protection() {
    local repo=$1
    local branch=$2

    echo -e "${YELLOW}Removing protection from '${branch}' in ${ORG}/${repo}...${NC}"

    # Remove protection using GitHub API
    if gh api \
        --method DELETE \
        -H "Accept: application/vnd.github+json" \
        "/repos/${ORG}/${repo}/branches/${branch}/protection" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Successfully removed protection from ${ORG}/${repo}:${branch}${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to remove protection (may not exist) ${ORG}/${repo}:${branch}${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${RED}⚠️  WARNING: This will remove branch protection!${NC}"
    echo ""
    echo "This script will remove branch protection from:"
    echo ""
    for repo in "${REPOS[@]}"; do
        echo "  - ${ORG}/${repo}"
    done
    echo ""
    echo -e "${YELLOW}After removal, anyone with write access can:${NC}"
    echo "  • Push directly to main"
    echo "  • Force push and rewrite history"
    echo "  • Delete the branch"
    echo ""
    read -p "Are you sure you want to continue? (y/n) " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi

    echo ""

    # Remove protection from each repository
    success_count=0
    fail_count=0

    for repo in "${REPOS[@]}"; do
        if remove_protection "$repo" "$BRANCH"; then
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
        echo -e "${GREEN}Protection removed from all branches!${NC}"
    else
        echo -e "${YELLOW}Some branches failed. Check the output above.${NC}"
    fi
}

# Run main function
main
