# Branch Protection Scripts - Quick Reference

## ✨ New Parameterized Usage

All branch protection scripts now support flexible parameter-based execution.

### Basic Protection Script

**`protect-main-branch.sh`** - ✅ Fully Parameterized

```bash
# Protect a single repository
./scripts/ci/protect-main-branch.sh --repo artagon-common

# Protect multiple repositories
./scripts/ci/protect-main-branch.sh --repo artagon-bom --repo artagon-parent

# Protect repository in different organization
./scripts/ci/protect-main-branch.sh --repo my-project --owner myorg

# Protect all default repositories
./scripts/ci/protect-main-branch.sh --all

# Protect custom branch
./scripts/ci/protect-main-branch.sh --repo artagon-common --branch develop

# Skip confirmation
./scripts/ci/protect-main-branch.sh --repo artagon-common --force
```

### Parameters

All scripts support these common parameters:

| Parameter | Short | Description | Default |
|-----------|-------|-------------|---------|
| `--repo REPO` | `-r` | Repository name (repeatable) | Required* |
| `--owner OWNER` | `-o` | GitHub owner/organization | `artagon` |
| `--branch BRANCH` | `-b` | Branch name to protect | `main` |
| `--all` | `-a` | Process all default repos | - |
| `--force` | `-f` | Skip confirmation prompt | - |
| `--help` | `-h` | Show help message | - |

\* Not required if using `--all`

### Default Repositories

When using `--all`, these repositories are processed:
- artagon-common
- artagon-license
- artagon-bom
- artagon-parent

### Examples by Use Case

#### Protect Your Own Organization

```bash
# Single repo in your org
./scripts/ci/protect-main-branch.sh --repo my-app --owner mycompany

# Multiple repos in your org
./scripts/ci/protect-main-branch.sh \
  --owner mycompany \
  --repo api-server \
  --repo web-frontend \
  --repo mobile-app
```

#### Protect Specific Branches

```bash
# Protect develop branch
./scripts/ci/protect-main-branch.sh --repo artagon-common --branch develop

# Protect release branches
./scripts/ci/protect-main-branch.sh --repo artagon-bom --branch release/v1.0
```

#### Automated/CI Usage

```bash
# Non-interactive mode for CI/CD
./scripts/ci/protect-main-branch.sh --all --force
```

### Script Status

| Script | Status | Notes |
|--------|--------|-------|
| `protect-main-branch.sh` | ✅ Ready | Full parameterization |
| `protect-main-branch-team.sh` | 🔄 In Progress | Being updated |
| `protect-main-branch-strict.sh` | 🔄 In Progress | Being updated |
| `check-branch-protection.sh` | 🔄 In Progress | Being updated |
| `remove-branch-protection.sh` | 🔄 In Progress | Being updated |

### Migration Guide

**Old way (hardcoded):**
```bash
# Had to edit script to change repos or owner
./scripts/ci/protect-main-branch.sh
```

**New way (parameterized):**
```bash
# Flexible, no editing needed
./scripts/ci/protect-main-branch.sh --repo my-repo --owner my-org
```

### Common Workflows

#### Weekly Protection Audit
```bash
# Check all repos
./scripts/ci/check-branch-protection.sh --all

# Check specific repo
./scripts/ci/check-branch-protection.sh --repo artagon-common
```

#### New Repository Setup
```bash
# Protect new repo immediately
./scripts/ci/protect-main-branch.sh --repo new-project --force
```

#### Multi-Organization Management
```bash
# Protect same repo name across orgs
./scripts/ci/protect-main-branch.sh --repo shared-lib --owner org1
./scripts/ci/protect-main-branch.sh --repo shared-lib --owner org2
```

### Error Handling

The scripts provide clear error messages:

```bash
# No repos specified
$ ./scripts/ci/protect-main-branch.sh
Error: No repositories specified
Use --repo to specify repositories or --all for all default repos

# Invalid option
$ ./scripts/ci/protect-main-branch.sh --invalid
Error: Unknown option: --invalid
Use --help for usage information

# Failed protection
✗ Failed to protect artagon/my-repo:main
  Check that the repository exists and you have admin access
```

### Integration with CI/CD

**GitHub Actions Example:**
```yaml
name: Apply Branch Protection

on:
  repository_dispatch:
    types: [protect-branches]

jobs:
  protect:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true

      - name: Apply protection
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          .common/artagon-commo./scripts/ci/protect-main-branch.sh \
            --repo ${{ github.event.repository.name }} \
            --owner ${{ github.event.repository.owner.login }} \
            --force
```

### Best Practices

1. **Always use `--owner`** when working with multiple organizations
2. **Use `--force`** in automated scripts to avoid interactive prompts
3. **Specify `--branch`** explicitly for non-main branches
4. **Use `--all`** for bulk operations on standard repos
5. **Test with `--help`** first to verify syntax

### Troubleshooting

**Problem:** Command not found
```bash
# Solution: Use full path or add to PATH
bash /path/t./scripts/ci/protect-main-branch.sh --help
```

**Problem:** Permission denied
```bash
# Solution: Ensure script is executable
chmod +x scripts/ci/protect-main-branch.sh
```

**Problem:** Authentication failed
```bash
# Solution: Authenticate with GitHub CLI
gh auth login
gh auth status
```

---

**Last Updated:** 2025-10-18
**Version:** 2.0 (Parameterized)
