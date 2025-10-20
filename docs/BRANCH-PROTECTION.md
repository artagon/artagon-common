# Branch Protection Scripts for Artagon Projects

This directory contains scripts to manage branch protection across all Artagon repositories.

## Available Scripts

### 1. `check-branch-protection.sh`
**Check current protection status for all repositories**

```bash
./check-branch-protection.sh
```

Shows detailed protection settings for each repository including:
- Whether protection is enabled
- Required reviews configuration
- Status check requirements
- Admin enforcement
- Force push and deletion settings

### 2. `gh_protect_main.sh` ⭐ **Recommended for Solo Development**
**Apply basic branch protection (no PR reviews required)**

```bash
./gh_protect_main.sh
```

**Protection settings:**
- ✅ Block force pushes
- ✅ Block branch deletion
- ❌ No PR reviews required (you can push directly)
- ❌ Not enforced for admins (you can override if needed)

**Best for:** Solo development where you want safety rails but not strict review requirements.

### 3. `gh_protect_main_team.sh` ⭐ **Recommended for Teams**
**Apply team-level protection (PR reviews required, admin override allowed)**

```bash
./gh_protect_main_team.sh
```

**Protection settings:**
- ✅ Require 1 PR review before merging
- ✅ Dismiss stale reviews
- ✅ Require conversation resolution
- ✅ Block force pushes
- ✅ Block branch deletion
- ❌ No status checks required (optional CI/CD)
- ❌ No linear history requirement (allows merge commits)
- ❌ Not enforced for admins (emergency override allowed)

**Best for:** Team collaboration with code review, but allows admin flexibility for emergencies.

### 4. `gh_protect_main_strict.sh`
**Apply strict branch protection (maximum protection)**

```bash
./gh_protect_main_strict.sh
```

**Protection settings:**
- ✅ Require 1 PR review before merging
- ✅ Dismiss stale reviews
- ✅ Require status checks
- ✅ Require linear history (no merge commits)
- ✅ Require conversation resolution
- ✅ Block force pushes
- ✅ Block branch deletion
- ✅ **Enforced for admins (even you must follow rules!)**

**Best for:** Highly regulated environments, open source projects, or teams that need maximum protection.

⚠️ **WARNING:** With strict protection, you'll need to create PRs for all changes, even as the repo owner!

### 5. `remove-branch-protection.sh`
**Remove all branch protection**

```bash
./remove-branch-protection.sh
```

Completely removes branch protection from all repositories. Use with caution!

## Quick Start

### First Time Setup (Recommended)

1. **Check current status:**
   ```bash
   ./check-branch-protection.sh
   ```

2. **Apply basic protection:**
   ```bash
   ./gh_protect_main.sh
   ```

3. **Verify protection was applied:**
   ```bash
   ./check-branch-protection.sh
   ```

### Using GitHub CLI Directly

If you want to protect a single repository manually:

```bash
# Basic protection (no reviews)
gh api -X PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/artagon/REPO-NAME/branches/main/protection \
  -f required_pull_request_reviews=null \
  -f enforce_admins=false \
  -f allow_force_pushes=false \
  -f allow_deletions=false

# Check protection status
gh api /repos/artagon/REPO-NAME/branches/main/protection

# Remove protection
gh api -X DELETE /repos/artagon/REPO-NAME/branches/main/protection
```

## Understanding Protection Levels

### Comparison Table

| Feature | None | Basic (Solo) | Team | Strict |
|---------|------|-------------|------|--------|
| **Script** | - | `gh_protect_main.sh` | `gh_protect_main_team.sh` | `gh_protect_main_strict.sh` |
| **Direct push to main** | ✅ Yes | ✅ Yes | ❌ No | ❌ No |
| **Require PR reviews** | ❌ No | ❌ No | ✅ 1 approval | ✅ 1 approval |
| **Dismiss stale reviews** | - | - | ✅ Yes | ✅ Yes |
| **Block force pushes** | ❌ No | ✅ Yes | ✅ Yes | ✅ Yes |
| **Block branch deletion** | ❌ No | ✅ Yes | ✅ Yes | ✅ Yes |
| **Require status checks** | ❌ No | ❌ No | ❌ No | ✅ Yes |
| **Require linear history** | ❌ No | ❌ No | ❌ No | ✅ Yes |
| **Require conv. resolution** | ❌ No | ❌ No | ✅ Yes | ✅ Yes |
| **Enforce for admins** | - | ❌ No | ❌ No | ✅ Yes |
| **Admin can override** | - | ✅ Yes | ✅ Yes | ❌ No |
| **Best for** | ⚠️ Not recommended | Solo devs | Teams | Strict compliance |

### Detailed Breakdown

#### No Protection
```
Anyone with write access can:
✅ Push directly to main
✅ Force push (rewrite history)
✅ Delete the branch
✅ Skip all checks

⚠️ Not recommended - too risky!
```

#### Basic Protection (Solo Development)
```
You can:
✅ Push directly to main
✅ Override protection if needed (admin)

You cannot:
❌ Force push
❌ Delete branch

Perfect for: Solo developers who want safety rails
```

#### Team Protection (Team Collaboration)
```
Team members must:
✅ Create PRs for all changes
✅ Get 1 approval before merging
✅ Resolve all conversations

Admins can:
✅ Push directly in emergencies
✅ Override protection when needed

You cannot:
❌ Force push
❌ Delete branch

Perfect for: Team collaboration with flexibility
```

#### Strict Protection (Maximum Security)
```
Everyone must (including admins):
✅ Create PRs for all changes
✅ Get 1 approval before merging
✅ Pass all status checks
✅ Resolve all conversations
✅ Maintain linear history

No one can:
❌ Push directly (even admins!)
❌ Force push
❌ Delete branch
❌ Override protection

Perfect for: Open source, regulated environments
```

## Common Workflows

### Solo Development
Use **basic protection** to prevent accidents while maintaining flexibility:

```bash
./gh_protect_main.sh
```

**What you get:**
- ✅ Direct push capability (no PRs needed)
- ✅ Protection from force pushes
- ✅ Protection from branch deletion
- ✅ Admin override for emergencies

**Workflow:**
1. Make changes locally
2. Commit and push directly to main
3. No PR reviews required

### Team Development (Recommended for Teams)
Use **team protection** for code review with admin flexibility:

```bash
./gh_protect_main_team.sh
```

**What you get:**
- ✅ Require 1 PR approval
- ✅ Conversation resolution required
- ✅ Admin can push directly in emergencies
- ✅ Allows merge commits
- ❌ No CI/CD requirements

**Workflow:**
1. Team members create feature branches
2. Submit PRs when ready for review
3. Get 1 approval from team member
4. Resolve all conversations
5. Merge to main
6. Admins can push directly if needed

### Strict Compliance / Open Source
Use **strict protection** for maximum protection:

```bash
./gh_protect_main_strict.sh
```

**What you get:**
- ✅ Require 1 PR approval
- ✅ Require status checks (CI/CD)
- ✅ Require linear history
- ✅ Enforced for everyone (including admins)
- ❌ No direct pushes allowed

**Workflow:**
1. Everyone (including admins) creates feature branches
2. Submit PRs when ready
3. Wait for CI/CD checks to pass
4. Get 1 approval
5. Resolve all conversations
6. Merge to main (squash or rebase only)

### Temporary Changes
Need to make emergency changes? You have options:

**Option 1:** Remove protection temporarily
```bash
./remove-branch-protection.sh
# Make your changes
./gh_protect_main.sh  # Re-enable protection
```

**Option 2:** Use basic protection instead of strict
```bash
./gh_protect_main.sh  # Allows direct pushes
```

## Repository Coverage

These scripts manage protection for:
- `artagon/artagon-common` - Common infrastructure
- `artagon/artagon-license` - Licensing documentation
- `artagon/artagon-bom` - Bill of Materials
- `artagon/artagon-parent` - Parent POM

To add more repositories, edit the `REPOS` array in each script.

## Troubleshooting

### "Failed to protect" errors
- Ensure you're authenticated: `gh auth status`
- Verify you have admin access to the repository
- Check if branch exists: `gh api /repos/artagon/REPO/branches/main`

### Can't push even with basic protection
- Check if you accidentally ran the strict script
- Run `./check-branch-protection.sh` to verify settings
- If stuck, run `./remove-branch-protection.sh` and reapply

### Need to bypass protection
- Use basic protection instead of strict (allows direct push)
- Or temporarily remove protection for emergency changes

## Best Practices

1. **Start with basic protection** - Easy to work with, prevents major accidents
2. **Check status regularly** - Run `check-branch-protection.sh` periodically
3. **Document exceptions** - If you bypass protection, document why
4. **Re-enable after emergencies** - Always restore protection after temporary removal
5. **Upgrade to strict when ready** - Move to strict protection when working with teams

## Additional Resources

- [GitHub Branch Protection Docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub CLI API Docs](https://cli.github.com/manual/gh_api)

---

**Last Updated:** 2025-10-18
**Maintained by:** Artagon DevOps
