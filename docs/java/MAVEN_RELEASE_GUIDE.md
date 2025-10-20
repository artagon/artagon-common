# Maven Release Guide - Artagon BOM & Parent

Complete guide for releasing artagon-bom and artagon-parent to GitHub Packages and Maven Central.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Release (GitHub Packages)](#quick-release-github-packages)
- [Quick Start Checklist](#quick-start-checklist)
- [Full Release Process](#full-release-process)
- [Deployment Reference](#deployment-reference)
- [Security Automation](#security-automation)
- [Release to Maven Central](#release-to-maven-central)
- [Version Management](#version-management)
- [Troubleshooting](#troubleshooting)

---

## Branch Model & Automation Overview

- **`main`** always carries the next stable development snapshot. Keep it green by gating merges with the CI workflow from `.github/workflows/examples/ci.yml` (push/PR on `main` and `release-*`).
- **`release-x.y.z` branches** are cut from `main` when you freeze a version. Run `.github/workflows/examples/release-branch.yml` to enforce build, test, and security baselines and to optionally stage artifacts to OSSRH.
- **`v*` tags** mark the immutable release. Pushing a tag triggers `.github/workflows/examples/release-tag.yml`, which verifies the Maven version and publishes via the shared `maven_deploy` reusable workflow.
- Manual fallbacks remain available via `.github/workflows/examples/release.yml`, but always invoke them from the matching `release-x.y.z` branch to keep `main` untouched until you open a back-merge PR.

> Tip: Protect `main` (and each `release-*` branch once created) with `scripts/artagon java gh protect` so only fast-forward merges from reviewed PRs land, and require the CI + security checks introduced above.

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

Push to your `release-x.y.z` branch (cut from `main` after you freeze the version):

```bash
# The GitHub Actions workflow will automatically:
# 1. Build the project
# 2. Deploy to GitHub Packages or OSSRH staging (if configured)

git push origin release-1.2.3
```

**What happens:**
- Workflow: `.github/workflows/examples/release-branch.yml` triggers
- Builds the project and runs security checks
- Optionally deploys current version to GitHub Packages or OSSRH staging when the dispatch input `deploy-to-staging` is enabled
- Packages become available at: `https://github.com/artagon/artagon-bom/packages`

### Option 2: Manual Workflow Dispatch

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **"Deploy to GitHub Packages"** workflow (left sidebar)
4. Click **"Run workflow"** button (right side)
5. Select:
   - **Branch**: your `release-x.y.z` branch
   - **Deploy type**: `snapshot` or `release`
6. Choose whether to enable `deploy-to-staging`
7. Click **"Run workflow"** (green button)

**Screenshots walkthrough:**

```
Actions → Deploy to GitHub Packages → Run workflow
   ↓
[Use workflow from: main ▼]
[Use branch: release-1.2.3 ▼]
[Deployment type: snapshot ▼]
[Deploy to staging: true/false]
   ↓
[Run workflow]
```

The workflow will:
- ✅ Checkout code from the selected release branch
- ✅ Set up Java 25
- ✅ Configure Maven for GitHub authentication
- ✅ Build and, if requested, deploy to GitHub Packages or OSSRH staging
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

The workflow `.github/workflows/examples/release-tag.yml` automatically triggers on tag push, validates that the project version matches the tag, and deploys to GitHub Packages / Maven Central using the shared `maven_deploy` pipeline.

## Quick Start Checklist

> **Configuration:** The CLI reads defaults from `.artagonrc`. Set `owner` and `repo` under `[defaults]` to match your GitHub organisation/project, or point `ARTAGON_CONFIG` to an alternative file.

### One-Time Setup

1. **Create a Sonatype account**
   - Sign up at https://issues.sonatype.org
   - File a ticket requesting the `org.artagon` namespace (or your project groupId)
   - Approval usually arrives within 1–2 business days

2. **Generate a GPG key**
   ```bash
   # Generate key
   gpg --gen-key

   # List keys with long IDs
   gpg --list-keys --keyid-format LONG

   # Publish so Sonatype can fetch it
   gpg --keyserver keys.openpgp.org --send-keys YOUR_KEY_ID
   ```

3. **Configure Maven settings**
   Create or edit `~/.m2/settings.xml` so Maven can authenticate with Sonatype and use your GPG key:
   ```xml
   <settings>
       <servers>
           <server>
               <id>ossrh</id>
               <username>YOUR_SONATYPE_USERNAME</username>
               <password>YOUR_SONATYPE_PASSWORD</password>
           </server>
       </servers>
       <profiles>
           <profile>
               <id>ossrh</id>
               <activation>
                   <activeByDefault>true</activeByDefault>
               </activation>
               <properties>
                   <gpg.passphrase>YOUR_GPG_PASSPHRASE</gpg.passphrase>
               </properties>
           </profile>
       </profiles>
   </settings>
   ```

   > 💡 **Tip:** use `mvn --encrypt-master-password` and `mvn --encrypt-password` to avoid storing clear-text credentials.

4. **Verify your setup**
   ```bash
   scripts/artagon java release branch stage
   ```

### Snapshot Deployment (Development)

Deploy SNAPSHOT builds while iterating:

```bash
scripts/artagon java snapshot publish
```

_Manual equivalent_
```bash
mvn clean deploy -Possrh-deploy,artagon-oss-release
```

Usage in downstream projects:
```xml
<repositories>
    <repository>
        <id>ossrh-snapshots</id>
        <url>https://s01.oss.sonatype.org/content/repositories/snapshots</url>
        <snapshots><enabled>true</enabled></snapshots>
    </repository>
</repositories>

<parent>
    <groupId>org.artagon</groupId>
    <artifactId>artagon-parent</artifactId>
    <version>1.0.0-SNAPSHOT</version>
</parent>
```

### Release to Maven Central (Production)

_One-liner:_
```bash
scripts/artagon java release run --version 1.0.0
```

_Manual flow:_
```bash
# 1. Update versions
cd artagon-bom
mvn versions:set -DnewVersion=1.0.0
mvn versions:commit

cd ../artagon-parent
mvn versions:set -DnewVersion=1.0.0
mvn versions:commit

# 2. Update BOM reference in parent pom.xml

# 3. Refresh security baselines
cd ../artagon-bom
mvn clean verify
cp security/artagon-bom-checksums.csv ../artagon-parent/security/bom-checksums.csv

# 4. Commit + tag
cd ..
git add .
git commit -m "Release version 1.0.0"
git tag -a v1.0.0 -m "Release 1.0.0"

# 5. Deploy to staging
mvn clean deploy -Possrh-deploy,artagon-oss-release

# 6. Release from staging
mvn nexus-staging:release -Possrh-deploy
# or use https://s01.oss.sonatype.org/

# 7. Bump to next SNAPSHOT
cd artagon-bom
mvn versions:set -DnewVersion=1.0.1-SNAPSHOT
mvn versions:commit

cd ../artagon-parent
mvn versions:set -DnewVersion=1.0.1-SNAPSHOT
mvn versions:commit

# 8. Push
cd ..
git add .
git commit -m "Prepare for next development iteration"
git push origin main --tags
```


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

## Deployment Reference

This guide covers deploying artagon-bom and artagon-parent to Maven Central via Sonatype OSSRH.

### Table of Contents

1. [Deployment Prerequisites](#deployment-prerequisites)
2. [Deployment Initial Setup](#deployment-initial-setup)
3. [Deployment Process](#deployment-process)
4. [Release Workflow](#release-workflow)
5. [Deployment Troubleshooting](#deployment-troubleshooting)

---

### Deployment Prerequisites

#### 1. Sonatype OSSRH Account

- Create account at https://issues.sonatype.org
- Request access for `org.artagon` groupId
- Follow: https://central.sonatype.org/publish/publish-guide/

#### 2. GPG Key Setup

```bash
# Generate GPG key (if you don't have one)
gpg --gen-key

# List keys
gpg --list-keys

# Get key fingerprint
gpg --list-keys --keyid-format LONG

# Publish to key server
gpg --keyserver keys.openpgp.org --send-keys YOUR_KEY_ID
```

#### 3. Maven Settings Configuration

Add credentials to `~/.m2/settings.xml`:

```xml
<settings>
    <servers>
        <server>
            <id>ossrh</id>
            <username>YOUR_SONATYPE_USERNAME</username>
            <password>YOUR_SONATYPE_PASSWORD</password>
        </server>
    </servers>

    <profiles>
        <profile>
            <id>ossrh</id>
            <activation>
                <activeByDefault>true</activeByDefault>
            </activation>
            <properties>
                <gpg.executable>gpg</gpg.executable>
                <gpg.passphrase>YOUR_GPG_PASSPHRASE</gpg.passphrase>
            </properties>
        </profile>
    </profiles>
</settings>
```

**Security Best Practice**: Use encrypted passwords:
```bash
# Encrypt master password
mvn --encrypt-master-password YOUR_MASTER_PASSWORD

# Encrypt server password
mvn --encrypt-password YOUR_SONATYPE_PASSWORD
```

---

### Deployment Initial Setup

#### 1. Verify POM Completeness

Both POMs must have:
- ✅ groupId
- ✅ artifactId
- ✅ version
- ✅ name
- ✅ description
- ✅ url
- ✅ licenses
- ✅ developers
- ✅ scm
- ✅ distributionManagement

#### 2. Check Current Status

```bash
cd /Users/gtrump001c@cable.comcast.com/Projects/Artagon

# Verify build works
mvn clean verify

# Check for SNAPSHOT dependencies (releases can't have them)
mvn dependency:tree | grep SNAPSHOT
```

---

### Deployment Process

#### Snapshot Deployment

Deploy development snapshots to Sonatype snapshots repository:

```bash
# Deploy artagon-bom
cd artagon-bom
mvn clean deploy -Possrh-deploy

# Deploy artagon-parent
cd ../artagon-parent
mvn clean deploy -Partagon-oss-release

# Or deploy both at once from root
cd ..
mvn clean deploy -Possrh-deploy,artagon-oss-release
```

**Snapshot Usage**:
```xml
<repositories>
    <repository>
        <id>ossrh-snapshots</id>
        <url>https://s01.oss.sonatype.org/content/repositories/snapshots</url>
        <snapshots>
            <enabled>true</enabled>
        </snapshots>
    </repository>
</repositories>
```

#### Release Deployment

For official releases to Maven Central:

```bash
# 1. Update versions to release (remove -SNAPSHOT)
cd artagon-bom
mvn versions:set -DnewVersion=1.0.0
mvn versions:commit

cd ../artagon-parent
mvn versions:set -DnewVersion=1.0.0
mvn versions:commit

# 2. Update BOM version in parent
# Edit artagon-parent/pom.xml:
#   <artifactId>artagon-bom</artifactId>
#   <version>1.0.0</version>  <!-- Updated -->

# 3. Update checksums
cd ../artagon-bom
mvn clean verify
cp security/artagon-bom-checksums.csv ../artagon-parent/security/bom-checksums.csv

# 4. Commit release
git add .
git commit -m "Release version 1.0.0"
git tag -a v1.0.0 -m "Release 1.0.0"

# 5. Deploy to OSSRH staging
mvn clean deploy -Possrh-deploy

# 6. Release through Nexus UI or CLI
# UI: https://s01.oss.sonatype.org/
# OR use Maven:
mvn nexus-staging:release -Possrh-deploy

# 7. Update to next development version
mvn versions:set -DnewVersion=1.0.1-SNAPSHOT
mvn versions:commit

git add .
git commit -m "Prepare for next development iteration"
git push origin main --tags
```

---

### Release Workflow

#### Using Maven Release Plugin

```bash
cd /Users/gtrump001c@cable.comcast.com/Projects/Artagon

# Prepare release (updates versions, creates tag)
mvn release:prepare -Possrh-deploy

# Perform release (builds and deploys)
mvn release:perform -Possrh-deploy

# If something goes wrong, rollback
mvn release:rollback
```

#### Manual Release Checklist

- [ ] All tests pass: `mvn clean verify`
- [ ] No SNAPSHOT dependencies
- [ ] Update version numbers
- [ ] Update BOM checksums
- [ ] Update CHANGELOG.md
- [ ] Commit and tag release
- [ ] Deploy to staging
- [ ] Test staged artifacts
- [ ] Release to Maven Central
- [ ] Push commits and tags
- [ ] Create GitHub release
- [ ] Update to next SNAPSHOT version

---

### Deployment Profiles

#### artagon-bom Profiles

**`ossrh-deploy`** - Deploy to OSSRH
- GPG signing
- Nexus staging

```bash
mvn clean deploy -Possrh-deploy
```

#### artagon-parent Profiles

**`artagon-oss-release`** - Full release build
- GPG signing
- Source attachment
- Javadoc generation
- Checksum verification
- PGP verification
- Nexus staging

```bash
mvn clean deploy -Partagon-oss-release
```

---

### Verification

#### After Snapshot Deployment

```bash
# Check if artifacts are available
curl -I https://s01.oss.sonatype.org/content/repositories/snapshots/org/artagon/artagon-bom/1.0.0-SNAPSHOT/

# Test using snapshot
mvn dependency:get \
  -DremoteRepositories=https://s01.oss.sonatype.org/content/repositories/snapshots \
  -Dartifact=org.artagon:artagon-bom:1.0.0-SNAPSHOT:pom
```

#### After Release

Wait 2-4 hours for sync to Maven Central:

```bash
# Check Maven Central
curl -I https://repo1.maven.org/maven2/org/artagon/artagon-bom/1.0.0/

# Verify in search
# https://search.maven.org/artifact/org.artagon/artagon-bom/1.0.0/pom
```

---

### Deployment Troubleshooting

#### GPG Signing Issues

```bash
# Issue: "gpg: signing failed: No such file or directory"
# Solution: Ensure GPG is in PATH
export GPG_TTY=$(tty)

# Issue: "gpg: signing failed: Inappropriate ioctl for device"
# Solution: Add to ~/.gnupg/gpg.conf
echo "use-agent" >> ~/.gnupg/gpg.conf
echo "pinentry-mode loopback" >> ~/.gnupg/gpg.conf

# Test signing
echo "test" | gpg --clear-sign
```

#### Nexus Staging Issues

```bash
# List staging repositories
mvn nexus-staging:rc-list -Possrh-deploy

# Drop failed staging repository
mvn nexus-staging:drop -Possrh-deploy

# Close staging repository
mvn nexus-staging:close -Possrh-deploy

# Release staging repository
mvn nexus-staging:release -Possrh-deploy
```

#### Common Errors

**"Failed to deploy: 401 Unauthorized"**
- Check credentials in `~/.m2/settings.xml`
- Verify Sonatype account is active

**"Failed to deploy: Artifacts missing signatures"**
- Ensure GPG plugin is activated
- Check GPG key is available: `gpg --list-keys`

**"Failed to deploy: POM file has incomplete metadata"**
- Verify all required fields present (see Initial Setup)

**"Cannot deploy SNAPSHOT to release repository"**
- Check version doesn't contain `-SNAPSHOT`
- Update version: `mvn versions:set -DnewVersion=1.0.0`

---

### Environment Variables

Optionally use environment variables instead of `settings.xml`:

```bash
export SONATYPE_USERNAME="your-username"
export SONATYPE_PASSWORD="your-password"
export GPG_PASSPHRASE="your-gpg-passphrase"
export GPG_KEYNAME="your-key-id"

# Deploy
mvn clean deploy -Possrh-deploy \
  -Dusername=$SONATYPE_USERNAME \
  -Dpassword=$SONATYPE_PASSWORD \
  -Dgpg.passphrase=$GPG_PASSPHRASE
```

---

### CI/CD Integration

#### GitHub Actions Example

```yaml
name: Deploy to OSSRH

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up JDK 25
        uses: actions/setup-java@v3
        with:
          java-version: '25'
          distribution: 'temurin'

      - name: Import GPG key
        run: |
          echo "${{ secrets.GPG_PRIVATE_KEY }}" | gpg --import

      - name: Deploy to OSSRH
        env:
          SONATYPE_USERNAME: ${{ secrets.SONATYPE_USERNAME }}
          SONATYPE_PASSWORD: ${{ secrets.SONATYPE_PASSWORD }}
          GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
        run: |
          mvn clean deploy -Possrh-deploy \
            --settings .github/maven-settings.xml \
            -Dgpg.passphrase=$GPG_PASSPHRASE
```

---

### Resources

- [Sonatype OSSRH Guide](https://central.sonatype.org/publish/publish-guide/)
- [Maven GPG Plugin](https://maven.apache.org/plugins/maven-gpg-plugin/)
- [Nexus Staging Plugin](https://github.com/sonatype/nexus-maven-plugins)
- [Maven Central Requirements](https://central.sonatype.org/publish/requirements/)

---

### Quick Reference

```bash
# Snapshot deployment
mvn clean deploy -Possrh-deploy,artagon-oss-release

# Release deployment
mvn versions:set -DnewVersion=1.0.0 && \
mvn clean deploy -Possrh-deploy,artagon-oss-release && \
mvn nexus-staging:release -Possrh-deploy

# Rollback release
mvn versions:revert
mvn nexus-staging:drop -Possrh-deploy
```

## Security Automation

Prefer the CLI commands (`scripts/artagon java security update|verify`) for everyday workflows; the underlying scripts remain documented here for troubleshooting and advanced automation.

This document describes the security scripts available in artagon-common for managing dependency integrity and verification.

### Overview

Artagon projects use multiple security scripts to ensure dependency integrity through checksum verification and PGP signature validation. These scripts are located in `scripts/security/` and are shared across all Artagon projects via the artagon-common submodule.

**Key Features:**
- Portable argument parsing (works on macOS, Linux, BSD, and other Unix systems)
- Support for both short (`-o`) and long (`--option`) command-line arguments
- Consistent color-coded output (red for errors, green for success, blue for info, yellow for warnings)
- Comprehensive help messages with examples
- Exit code standards (0 for success, 1 for errors)

### Scripts

#### 1. mvn-update-dep-security.sh

**Purpose**: Generates or updates security baseline files for Maven dependencies.

**Location**: `scripts/security/mvn-update-dep-security.sh`

**What it does**:
- Resolves all compile-scope dependencies (including transitives) from Maven
- Downloads artifacts and their PGP signatures from Maven Central
- Computes SHA-256 checksums for each artifact
- Extracts PGP fingerprints from signatures
- Generates security baseline files with Maven coordinate-based naming
- Auto-generates SHA-256 and SHA-512 checksums for the baseline files themselves

**Usage**:
```bash
# Update baselines (long form)
scripts/artagon java security update

# Update baselines (short form)
scripts/artagon java security update

# Verify baselines are current
scripts/artagon java security verify
scripts/artagon java security verify

# Show all options
./scripts/mvn-update-dep-security.sh --help
```

**Options**:
- `-p, --project-root PATH` - Path to Maven project root (default: current directory)
- `-s, --security-dir PATH` - Path to security directory (default: <project-root>/security)
- `-f, --checksum-format FMT` - Format for checksums: 'csv' or 'properties' (default: csv)
- `-S, --scopes SCOPES` - Maven scopes to include, comma-separated (default: compile)
- `-t, --transitive BOOL` - Include transitive dependencies: true or false (default: true)
- `-u, --update` - Update mode: regenerate baseline files (default)
- `-v, --verify` - Verify mode: check existing baselines are current
- `-m, --maven-cmd CMD` - Maven command to use (default: mvn)
- `-h, --help` - Show help message

**Generated Files**:

The script auto-detects the project's Maven coordinates (`groupId` and `artifactId`) and generates files with the naming pattern:

- `{groupId}-{artifactId}-dependency-checksums.csv` - SHA-256 checksums (CSV format)
- `{groupId}-{artifactId}-dependency-checksums.properties` - SHA-256 checksums (properties format)
- `{groupId}-{artifactId}-pgp-trusted-keys.list` - Trusted PGP fingerprints
- `*.sha256` - SHA-256 checksum of each baseline file
- `*.sha512` - SHA-512 checksum of each baseline file

Example for `com.artagon:artagon-parent`:
- `com.artagon-artagon-parent-dependency-checksums.csv`
- `com.artagon-artagon-parent-dependency-checksums.csv.sha256`
- `com.artagon-artagon-parent-dependency-checksums.csv.sha512`
- `com.artagon-artagon-parent-pgp-trusted-keys.list`
- `com.artagon-artagon-parent-pgp-trusted-keys.list.sha256`
- `com.artagon-artagon-parent-pgp-trusted-keys.list.sha512`

**When to Run**:
- After adding, removing, or updating dependencies in `pom.xml`
- Before creating a release to ensure baselines are current
- When PGP keys change for existing dependencies

**Exit Codes**:
- `0` - Success
- `1` - Error occurred

#### 2. verify-checksums.sh

**Purpose**: Verifies SHA-256 and SHA-512 checksums for security baseline files.

**Location**: `scripts/security/verify-checksums.sh`

**What it does**:
- Reads expected checksums from `.sha256` and `.sha512` files
- Computes actual checksums for the security baseline files
- Compares expected vs actual checksums
- Fails if any checksum doesn't match
- Provides colored output showing verification status

**Usage**:
```bash
# Verify files in current directory
./verify-checksums.sh file1.csv file2.list

# Verify files in specific directory
./verify-checksums.sh --security-dir /path/to/security file1.csv file2.list

# Short option form
./verify-checksums.sh -d /path/to/security file1.csv
```

**Options**:
- `-d, --security-dir PATH` - Path to security directory (default: current directory)
- `-h, --help` - Show help message

**Arguments**:
- One or more filenames to verify (without path, names only)

**Example Output**:
```
Verifying com.artagon-artagon-parent-dependency-checksums.csv checksums...
  SHA-256: OK
  SHA-512: OK
Verifying com.artagon-artagon-parent-pgp-trusted-keys.list checksums...
  SHA-256: OK
  SHA-512: OK
SUCCESS: Verified 4 checksum(s) successfully
```

**When to Run**:
- Automatically during Maven build (via exec-maven-plugin)
- Before using security baseline files for dependency verification
- As part of CI/CD integrity checks

**Exit Codes**:
- `0` - All checksums verified successfully
- `1` - Checksum verification failed or error occurred

#### 3. generate-dependency-checksums.sh

**Purpose**: Standalone script to generate dependency checksums without PGP verification.

**Location**: `scripts/security/generate-dependency-checksums.sh`

**What it does**:
- Similar to `mvn-update-dep-security.sh` but focuses only on checksums
- Generates CSV files with SHA-256 checksums
- Lighter-weight alternative when PGP verification isn't needed

**Usage**:
```bash
# Generate checksums for direct compile dependencies
./scripts/generate-dependency-checksums.sh

# Include transitive dependencies
./scripts/generate-dependency-checksums.sh -t
./scripts/generate-dependency-checksums.sh --transitive

# Generate for test scope with custom output
./scripts/generate-dependency-checksums.sh -s test -o security/test-checksums.csv
./scripts/generate-dependency-checksums.sh --scope test --output security/test-checksums.csv

# See all options
./scripts/generate-dependency-checksums.sh -h
./scripts/generate-dependency-checksums.sh --help
```

**Options**:
- `-t, --transitive` - Include transitive dependencies (default: false)
- `-s, --scope SCOPE` - Dependency scope to include (default: compile)
- `-o, --output FILE` - Output CSV file (default: security/dependency-checksums.csv)
- `-h, --help` - Show help message

### Integration with Maven

#### In pom.xml

##### Dependency Checksum Verification

Uses `checksum-maven-plugin` to verify dependencies against baseline:

```xml
<plugin>
    <groupId>net.nicoulaj.maven.plugins</groupId>
    <artifactId>checksum-maven-plugin</artifactId>
    <executions>
        <execution>
            <id>verify-dependency-checksums</id>
            <phase>verify</phase>
            <goals>
                <goal>check</goal>
            </goals>
            <configuration>
                <csvSummaryFile>${project.basedir}/security/com.artagon-artagon-parent-dependency-checksums.csv</csvSummaryFile>
                <scopes>
                    <scope>compile</scope>
                </scopes>
                <transitive>true</transitive>
                <failOnError>true</failOnError>
            </configuration>
        </execution>
    </executions>
</plugin>
```

##### PGP Signature Verification

Uses `pgpverify-maven-plugin` to verify PGP signatures:

```xml
<plugin>
    <groupId>org.simplify4u.plugins</groupId>
    <artifactId>pgpverify-maven-plugin</artifactId>
    <executions>
        <execution>
            <goals>
                <goal>check</goal>
            </goals>
            <configuration>
                <keysMapLocation>${project.basedir}/security/com.artagon-artagon-parent-pgp-trusted-keys.list</keysMapLocation>
                <scope>compile</scope>
            </configuration>
        </execution>
    </executions>
</plugin>
```

##### Security File Checksum Verification

Uses `exec-maven-plugin` to verify the security baseline files themselves:

```xml
<plugin>
    <groupId>org.codehaus.mojo</groupId>
    <artifactId>exec-maven-plugin</artifactId>
    <executions>
        <execution>
            <id>verify-security-file-checksums</id>
            <phase>validate</phase>
            <goals>
                <goal>exec</goal>
            </goals>
            <configuration>
                <executable>${project.basedir}/.common/artagon-common/scripts/security/verify-checksums.sh</executable>
                <arguments>
                    <argument>--security-dir</argument>
                    <argument>${project.basedir}/security</argument>
                    <argument>com.artagon-artagon-parent-dependency-checksums.csv</argument>
                    <argument>com.artagon-artagon-parent-pgp-trusted-keys.list</argument>
                </arguments>
            </configuration>
        </execution>
    </executions>
</plugin>
```

#### Wrapper Scripts

Projects can create wrapper scripts to delegate to the shared scripts:

**Example**: `artagon-parent/scripts/mvn-update-dep-security.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMMON_SCRIPT="${PROJECT_ROOT}/.common/artagon-common/scripts/security/mvn-update-dep-security.sh"

if [[ ! -x "${COMMON_SCRIPT}" ]]; then
    echo "ERROR: Shared script not found at ${COMMON_SCRIPT}" >&2
    echo "Ensure artagon-common submodule is initialized:" >&2
    echo "  git submodule update --init --recursive" >&2
    exit 1
fi

# Forward all arguments to the shared script with project root
exec "${COMMON_SCRIPT}" --project-root "${PROJECT_ROOT}" "$@"
```

### Security Workflow

#### Deployment Initial Setup

1. **Initialize submodule**:
   ```bash
   git submodule update --init --recursive
   ```

2. **Generate initial security baselines**:
   ```bash
   scripts/artagon java security update
   ```

3. **Commit baseline files**:
   ```bash
   git add security/
   git commit -m "Add security baselines for dependencies"
   ```

#### Dependency Updates

When updating dependencies:

1. **Update pom.xml** with new dependencies or versions

2. **Regenerate baselines**:
   ```bash
   scripts/artagon java security update
   ```

3. **Review changes**:
   ```bash
   git diff security/
   ```

4. **Commit updates**:
   ```bash
   git add security/
   git commit -m "Update dependency security baselines"
   ```

#### Release Process

Before creating a release:

1. **Verify baselines are current**:
   ```bash
   scripts/artagon java security verify
   ```

2. **Run security profile**:
   ```bash
   mvn -P artagon-oss-security verify
   ```

3. **Run release build**:
   ```bash
   mvn -P artagon-oss-release,artagon-oss-security clean verify
   ```

The build will automatically:
- Verify security baseline files' checksums (validate phase)
- Verify all dependency checksums (verify phase)
- Verify all PGP signatures (verify phase)
- Fail if any verification fails

### File Naming Convention

All security baseline files use the pattern:
```
{groupId}-{artifactId}-{type}.{ext}
```

Where:
- `{groupId}` - Maven groupId (e.g., `com.artagon`)
- `{artifactId}` - Maven artifactId (e.g., `artagon-parent`)
- `{type}` - File type (`dependency-checksums`, `pgp-trusted-keys`)
- `{ext}` - File extension (`csv`, `list`, `properties`)

Examples:
- `com.artagon-artagon-parent-dependency-checksums.csv`
- `com.artagon-artagon-bom-dependency-checksums.csv`
- `com.artagon-artagon-parent-pgp-trusted-keys.list`

Checksum files add `.sha256` or `.sha512` extensions:
- `com.artagon-artagon-parent-dependency-checksums.csv.sha256`
- `com.artagon-artagon-parent-dependency-checksums.csv.sha512`

### Troubleshooting

#### Script Not Found

**Error**: `Shared script not found at .common/artagon-common/scripts/security/...`

**Solution**: Initialize the artagon-common submodule:
```bash
git submodule update --init --recursive
```

#### Permission Denied

**Error**: `Permission denied: ./scripts/mvn-update-dep-security.sh`

**Solution**: Make script executable:
```bash
chmod +x ./scripts/mvn-update-dep-security.sh
```

#### Checksum Mismatch

**Error**: `SHA-256 checksum mismatch for file.csv`

**Solution**: The file has been modified. Either:
1. Restore the original file from git
2. Regenerate baselines if the change was intentional

#### PGP Key Not Found

**Warning**: `Unable to extract fingerprint from ...`

**Solution**: The artifact's PGP signature is unavailable. This is marked as `noKey` in the trusted keys file and is acceptable for some dependencies.

#### Maven Plugin Version Warnings

**Warning**: `'build.plugins.plugin.version' for org.codehaus.mojo:exec-maven-plugin is missing`

**Solution**: Add version to pluginManagement in parent POM or specify directly in plugin configuration.

### Script Design and Portability

#### Argument Parsing

All security scripts use **portable manual argument parsing** that works across different Unix-like operating systems:

**Why not GNU getopt?**
- macOS and BSD systems ship with BSD `getopt` which doesn't support long options
- GNU `getopt` is not available by default on macOS
- Portable parsing ensures scripts work everywhere without additional dependencies

**Implementation:**
- Supports both short (`-o`) and long (`--option`) arguments
- Validates that options requiring arguments actually receive them
- Provides clear error messages for invalid arguments
- Works identically on Linux, macOS, BSD, and other Unix systems

**Example Pattern:**
```bash
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            if [[ -z "$2" || "$2" == -* ]]; then
                error "Option $1 requires an argument"
            fi
            OUTPUT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            # Handle positional arguments
            ;;
    esac
done
```

#### Color Output

All scripts use consistent ANSI color codes:
- **Red** (`\033[0;31m`): Errors
- **Green** (`\033[0;32m`): Success messages
- **Yellow** (`\033[1;33m`): Warnings
- **Blue** (`\033[0;34m`): Info messages

Color is automatically disabled when output is redirected to a file or pipe.

#### Helper Functions

Standard helper functions used across all scripts:
```bash
error()   # Prints red error message to stderr and exits with code 1
success() # Prints green success message
info()    # Prints blue info message
warn()    # Prints yellow warning message
```

### Best Practices

1. **Always verify before releasing**: Run `--verify` mode before creating releases
2. **Commit baseline changes separately**: Keep security baseline updates in separate commits from functional changes
3. **Review baseline diffs**: Carefully review any changes to security baselines before committing
4. **Use version control**: Never manually edit generated baseline files
5. **Keep submodules updated**: Regularly update artagon-common submodule to get script fixes
6. **Document exceptions**: If marking dependencies as `noKey`, document why in commit messages
7. **Run security profile in CI**: Include `-P artagon-oss-security` in CI builds
8. **Use long options in documentation**: While short options work, long options are more readable in docs and scripts

### See Also

- [Maven Checksum Plugin Documentation](https://github.com/nicoulaj/checksum-maven-plugin)
- [PGP Verify Plugin Documentation](https://github.com/s4u/pgpverify-maven-plugin)
- [MAVEN_RELEASE_GUIDE.md](MAVEN_RELEASE_GUIDE.md) - Complete release process guide
- [MAVEN_RELEASE_GUIDE.md#deployment-reference](MAVEN_RELEASE_GUIDE.md#deployment-reference) - Deployment to Maven Central


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

- [MAVEN_RELEASE_GUIDE.md#deployment-reference](MAVEN_RELEASE_GUIDE.md#deployment-reference) - Full deployment guide for Maven Central
- [Quick Start Checklist](#quick-start-checklist) - Quick deployment reference
- [MAVEN_GITHUB-PACKAGES.md](MAVEN_GITHUB-PACKAGES.md) - Using packages from GitHub
- [CHANGELOG.md](CHANGELOG.md) - Version history

---

## Support

For issues:
- **GitHub Actions**: Check workflow logs in Actions tab
- **GitHub Packages**: https://docs.github.com/en/packages
- **Maven Central**: https://central.sonatype.org/publish/
- **Project Issues**: Open issue in respective repository
