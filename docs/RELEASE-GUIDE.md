# Release Guide - Artagon BOM & Parent

Complete guide for releasing artagon-bom and artagon-parent to GitHub Packages and Maven Central.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Release (GitHub Packages)](#quick-release-github-packages)
- [Full Release Process](#full-release-process)
- [Release to Maven Central](#release-to-maven-central)
- [Version Management](#version-management)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required GitHub Secrets

Go to **Settings > Secrets and variables > Actions** in each repository and ensure these secrets are set:

**For GitHub Packages (required):**
- `GITHUB_TOKEN` - *Automatically provided by GitHub Actions* ✅

**For Maven Central/OSSRH (optional, if releasing there):**
- `OSSRH_USERNAME` - Your Sonatype OSSRH username
- `OSSRH_PASSWORD` - Your Sonatype OSSRH password
- `GPG_PRIVATE_KEY` - Your GPG private key (full block)
- `GPG_PASSPHRASE` - Your GPG passphrase

**For signing (optional but recommended):**
- `GPG_PRIVATE_KEY` - Can be used for both OSSRH and GitHub Packages
- `GPG_PASSPHRASE` - Your GPG key passphrase

### Repository Permissions

Ensure the GitHub Actions workflow has permission to:
- Read repository contents
- Write packages

Go to **Settings > Actions > General > Workflow permissions** and select:
- ✅ Read and write permissions
- ✅ Allow GitHub Actions to create and approve pull requests (optional)

---

## Quick Release (GitHub Packages)

### Option 1: Automatic Deployment on Push

Simply push to the `main` branch:

```bash
# The GitHub Actions workflow will automatically:
# 1. Build the project
# 2. Deploy to GitHub Packages

git push origin main
```

**What happens:**
- Workflow: `.github/workflows/github-packages-deploy.yml` triggers
- Builds the project
- Deploys current version to GitHub Packages
- Packages available at: `https://github.com/artagon/artagon-bom/packages`

### Option 2: Manual Workflow Dispatch

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **"Deploy to GitHub Packages"** workflow (left sidebar)
4. Click **"Run workflow"** button (right side)
5. Select:
   - **Branch**: `main`
   - **Deploy type**: `snapshot` or `release`
6. Click **"Run workflow"** (green button)

**Screenshots walkthrough:**

```
Actions → Deploy to GitHub Packages → Run workflow
   ↓
[Use workflow from: main ▼]
[Deployment type: snapshot ▼]
   ↓
[Run workflow]
```

The workflow will:
- ✅ Checkout code
- ✅ Set up Java 25
- ✅ Configure Maven for GitHub authentication
- ✅ Build and deploy to GitHub Packages
- ✅ Show deployment summary with package URL

### Option 3: Tag-based Release

Create and push a git tag:

**For artagon-bom:**
```bash
cd artagon-bom
git tag bom-v1.0.0
git push origin bom-v1.0.0
```

**For artagon-parent:**
```bash
cd artagon-parent
git tag v1
git push origin v1
```

The workflow automatically triggers on tag push and deploys to GitHub Packages.

---

## Full Release Process

### Step 1: Prepare the Release

#### For artagon-bom (Semantic Versioning)

```bash
cd /Users/gtrump001c@cable.comcast.com/Projects/Artagon/artagon-bom

# Check current version
mvn help:evaluate -Dexpression=project.version -q -DforceStdout

# Update to release version (example: 1.0.0 → 1.0.1)
mvn versions:set -DnewVersion=1.0.1

# Verify changes
git diff pom.xml

# Update checksums
mvn clean verify
shasum -a 256 pom.xml
shasum -a 512 pom.xml
# Update security/artagon-bom-checksums.csv with new checksums

# Commit the version change
git add pom.xml security/artagon-bom-checksums.csv
git commit -m "chore: bump version to 1.0.1 for release"
```

#### For artagon-parent (Integer Versioning)

```bash
cd /Users/gtrump001c@cable.comcast.com/Projects/Artagon/artagon-parent

# Check current version
mvn help:evaluate -Dexpression=project.version -q -DforceStdout

# Update to next release version (example: 1 → 2)
mvn versions:set -DnewVersion=2

# Also update the BOM version if needed
# Edit pom.xml and update artagon-bom import version

# Commit the version change
git add pom.xml
git commit -m "chore: bump version to 2 for release"
```

### Step 2: Tag the Release

#### artagon-bom
```bash
cd artagon-bom
git tag -a bom-v1.0.1 -m "Release artagon-bom 1.0.1"
git push origin bom-v1.0.1
```

#### artagon-parent
```bash
cd artagon-parent
git tag -a v2 -m "Release artagon-parent version 2"
git push origin v2
```

### Step 3: Trigger Deployment

**Option A: Automatic (recommended)**

The tag push automatically triggers the GitHub Packages deployment workflow.

**Option B: Manual**

1. Go to **Actions** → **Deploy to GitHub Packages**
2. Click **Run workflow**
3. Select the tag you just created
4. Choose deployment type: `release`
5. Click **Run workflow**

### Step 4: Verify Deployment

1. Go to the repository's **Packages** tab
2. You should see your package listed
3. Click on the package to see versions
4. Verify the version number matches your release

**Package URLs:**
- artagon-bom: https://github.com/orgs/artagon/packages?repo_name=artagon-bom
- artagon-parent: https://github.com/orgs/artagon/packages?repo_name=artagon-parent

### Step 5: Prepare for Next Development Iteration

#### artagon-bom (bump to next SNAPSHOT)
```bash
cd artagon-bom
mvn versions:set -DnewVersion=1.1.0-SNAPSHOT
git add pom.xml
git commit -m "chore: prepare for next development iteration"
git push origin main
```

#### artagon-parent (stay at current version until next release)
```bash
# artagon-parent uses integer versioning, so no SNAPSHOT needed
# Leave at version 2 until next release
```

---

## Release to Maven Central

### Option 1: Using GitHub Actions (Recommended)

1. Ensure all OSSRH secrets are configured (see Prerequisites)
2. Go to **Actions** → **Release** workflow
3. Click **Run workflow**
4. Enter:
   - **release-version**: e.g., `1.0.0` for BOM or `2` for parent
   - **next-snapshot-version**: (optional) e.g., `1.1.0-SNAPSHOT`
   - **auto-release-nexus**: `false` (manual review recommended)
5. Click **Run workflow**

The workflow will:
- ✅ Set the release version
- ✅ Build and sign artifacts with GPG
- ✅ Deploy to OSSRH Nexus staging repository
- ✅ Create git tag
- ✅ Set next SNAPSHOT version
- ✅ Create GitHub release

### Option 2: Using Maven Release Plugin

```bash
# One-command release
mvn release:prepare release:perform -P ossrh-deploy,artagon-oss-release

# Manual staging release from Nexus
# Go to https://s01.oss.sonatype.org/
# Login and manually release from staging
```

### Option 3: Manual Deploy to OSSRH

```bash
# Deploy to OSSRH
mvn clean deploy -P ossrh-deploy,artagon-oss-release

# Then manually release from Nexus staging:
# 1. Go to https://s01.oss.sonatype.org/
# 2. Login with OSSRH credentials
# 3. Click "Staging Repositories"
# 4. Find your repository
# 5. Click "Close" then "Release"
```

---

## Version Management

### artagon-bom Versioning (Semantic Versioning)

```
MAJOR.MINOR.PATCH
  |     |     |
  |     |     └─ Bug fixes, security patches
  |     └─────── New dependencies, non-breaking updates
  └───────────── Breaking changes, major dependency updates
```

**Examples:**
- `1.0.0` → `1.0.1` - Security patch for a dependency
- `1.0.1` → `1.1.0` - Added new dependencies (Quarkus BOM)
- `1.1.0` → `2.0.0` - Breaking change (Java 25 → 26)

### artagon-parent Versioning (Integer)

```
1, 2, 3, 4, ...
```

**When to bump:**
- Plugin version changes
- Compiler configuration changes
- New profiles
- Build infrastructure changes

---

## Troubleshooting

### Workflow Fails: "No such file or directory"

**Problem**: Workflow can't find pom.xml

**Solution**: Ensure workflow triggers on correct branch
```yaml
on:
  push:
    branches: [ main ]  # Check this matches your default branch
```

### Deployment Fails: "401 Unauthorized"

**Problem**: GitHub token doesn't have package write permissions

**Solution**:
1. Go to Settings → Actions → General → Workflow permissions
2. Select "Read and write permissions"
3. Re-run the workflow

### Package Not Visible After Deployment

**Problem**: Package deployed but not showing in UI

**Solution**:
1. Wait a few minutes (GitHub can be slow to index)
2. Check Actions workflow logs for actual deployment
3. Verify package visibility settings:
   - Repository Settings → Packages → Package Visibility
   - Ensure it's set to Public (for public repos)

### GPG Signing Fails

**Problem**: `gpg: signing failed: No such file or directory`

**Solution**: GPG signing is optional for GitHub Packages
1. Remove GPG plugin from `github-deploy` profile, OR
2. Ensure GPG secrets are properly set:
   ```bash
   # Export your GPG key
   gpg --armor --export-secret-keys YOUR_KEY_ID
   # Copy entire output including BEGIN/END lines
   ```

### Version Already Exists

**Problem**: `409 Conflict - version already exists`

**Solution**:
1. For snapshots: This is normal, Maven overwrites
2. For releases: You cannot overwrite releases
   - Bump the version number
   - Deploy with new version

---

## Release Checklist

### Pre-Release
- [ ] All tests pass (`mvn clean verify`)
- [ ] Security scans pass (`mvn -P artagon-oss-security verify`)
- [ ] CHANGELOG.md updated with release notes
- [ ] Version bumped in pom.xml
- [ ] Checksums updated (for artagon-bom)
- [ ] Git status clean (`git status`)

### Release
- [ ] Committed version bump
- [ ] Created and pushed git tag
- [ ] Triggered deployment workflow
- [ ] Verified workflow completed successfully
- [ ] Checked package appears in GitHub Packages

### Post-Release
- [ ] Bumped to next SNAPSHOT version (for BOM)
- [ ] Created GitHub release with release notes
- [ ] Announced release (if major)
- [ ] Updated documentation referencing new version

---

## GitHub Actions Workflow Details

### github-packages-deploy.yml

**Triggers:**
- Push to `main` branch
- Push of tags matching `bom-v*` or `v*`
- Manual workflow dispatch

**Steps:**
1. Checkout code
2. Set up Java 25 with Maven cache
3. Configure Maven settings.xml with GitHub token
4. Deploy with `mvn deploy -P github-deploy -DskipTests`
5. Display deployment summary

**Environment:**
- `GITHUB_TOKEN` - Auto-provided by GitHub Actions
- `GITHUB_ACTOR` - Current user triggering workflow

### release.yml (Maven Central)

**Triggers:**
- Manual workflow dispatch only

**Required Inputs:**
- `release-version` - Version to release (e.g., `1.0.0`)

**Optional Inputs:**
- `next-snapshot-version` - Next dev version
- `auto-release-nexus` - Auto-release from staging

**Steps:**
1. Checkout code
2. Set up Java 25
3. Import GPG key
4. Set release version
5. Build and deploy to OSSRH
6. Create git tag
7. Set next SNAPSHOT version
8. Create GitHub release

---

## Quick Command Reference

```bash
# Check current version
mvn help:evaluate -Dexpression=project.version -q -DforceStdout

# Set version
mvn versions:set -DnewVersion=1.0.1

# Deploy to GitHub Packages
mvn clean deploy -P github-deploy

# Deploy to Maven Central
mvn clean deploy -P ossrh-deploy,artagon-oss-release

# Full release with Maven Release Plugin
mvn release:prepare release:perform -P ossrh-deploy,artagon-oss-release

# Create and push tag
git tag -a bom-v1.0.1 -m "Release 1.0.1"
git push origin bom-v1.0.1

# Update checksums
shasum -a 256 pom.xml
shasum -a 512 pom.xml
```

---

## See Also

- [DEPLOYMENT.md](DEPLOYMENT.md) - Full deployment guide for Maven Central
- [QUICKSTART-DEPLOY.md](QUICKSTART-DEPLOY.md) - Quick deployment reference
- [GITHUB-PACKAGES.md](GITHUB-PACKAGES.md) - Using packages from GitHub
- [CHANGELOG.md](CHANGELOG.md) - Version history

---

## Support

For issues:
- **GitHub Actions**: Check workflow logs in Actions tab
- **GitHub Packages**: https://docs.github.com/en/packages
- **Maven Central**: https://central.sonatype.org/publish/
- **Project Issues**: Open issue in respective repository
