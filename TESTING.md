# Testing Guide for Artagon Common

This document provides testing procedures for the artagon-common repository and its integration with downstream projects.

## Automated Workflow Testing

### Testing Submodule Updates

The automated update workflow runs weekly but can also be triggered manually to test the integration.

**Manual Trigger Steps:**
1. Navigate to the downstream repository (artagon-bom, artagon-parent, etc.)
2. Go to Actions > Update Common Scripts
3. Click "Run workflow" button
4. Select branch (usually `main`)
5. Click "Run workflow"

**Expected Behavior:**
- Workflow should complete successfully
- If updates are available, a PR should be created
- PR should include changelog of commits
- PR should be labeled with `dependencies` and `automated`

## Submodule Commands Testing

### Update Submodule Manually

```bash
# Navigate to project with submodule
cd ~/Projects/Artagon/artagon-bom

# Update submodule to latest
git submodule update --remote .common/artagon-common

# Check what changed
git diff .common/artagon-common

# Commit if there are changes
git add .common/artagon-common
git commit -m "Update artagon-common submodule"
git push
```

### Verify Submodule Status

```bash
# Check current commit
git submodule status

# View submodule details
cd .common/artagon-common
git log --oneline -5
cd ../..
```

## Script Testing

### Test auto_create_and_push.sh

```bash
# From any project with the submodule
.common/artagon-common/scripts/auto_create_and_push.sh --help

# Should display help text with all options
```

### Test setup-artagon-common.sh

```bash
# In a new test project
.common/artagon-common/scripts/setup-artagon-common.sh

# Should add submodule to current project
```

## Workflow File Validation

### Check Workflow Syntax

```bash
# Validate update-common.yml exists
cat .github/workflows/update-common.yml

# Verify it references the reusable workflow correctly
grep "artagon/artagon-common/.github/workflows" .github/workflows/update-common.yml
```

## Test Scenarios

### Scenario 1: New Script Added to artagon-common
1. Add new script to artagon-common/scripts/
2. Commit and push to artagon-common
3. Trigger update workflow in downstream projects
4. Verify new script appears in downstream submodule

### Scenario 2: Bug Fix in Existing Script
1. Fix bug in artagon-common script
2. Commit with clear message
3. Trigger updates
4. Verify fix propagates to all projects

### Scenario 3: Breaking Change
1. Make breaking change with major version bump
2. Create PR in downstream projects (don't auto-merge)
3. Review and test changes before merging
4. Update projects when ready

## Continuous Integration

### GitHub Actions Status

Monitor the following workflows:
- `.github/workflows/update-common.yml` - Should run weekly
- Check Actions tab for any failures
- Review PR descriptions for changelog accuracy

## Troubleshooting

### Submodule Not Updating
```bash
# Re-initialize submodule
git submodule update --init --recursive

# Force update
git submodule update --remote --force
```

### Workflow Not Triggering
- Check workflow file syntax
- Verify GITHUB_TOKEN has correct permissions
- Check repository settings for Actions enabled

### PR Not Created
- Verify peter-evans/create-pull-request action is accessible
- Check workflow logs for errors
- Ensure there are actual changes to commit

---

**Last Updated:** 2025-10-18
**Version:** 1.0
**Maintainer:** Artagon DevOps Team
