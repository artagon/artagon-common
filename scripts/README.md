# Artagon Scripts

Automation scripts for deployment, CI/CD, and repository management.

## Release Strategy

Artagon projects use a **release branch strategy**:

- **`main` branch**: Always has SNAPSHOT versions (e.g., `1.0.9-SNAPSHOT`)
- **`release-X.Y.Z` branches**: Have release versions without SNAPSHOT (e.g., `1.0.8`)
- **Tags**: Created on release branches (e.g., `v1.0.8`)

**Key principle**: Main branch versions MUST end with `-SNAPSHOT`. Release branches remove the suffix to create release versions.

For complete documentation, see [artagon-workflows/RELEASE.md](https://github.com/artagon/artagon-workflows/blob/main/RELEASE.md).

## Artagon CLI

The preferred entry point is the Python CLI located at `scripts/artagon`.
It orchestrates releases, snapshot deployments, security baseline updates,
and GitHub administration through a single interface.

### Available commands

```bash
# Display available commands
scripts/artagon --help

# Release workflows
scripts/artagon java release run --version 1.2.3
# Running from a non release-* branch
scripts/artagon java release run --version 1.2.3 --allow-branch-mismatch
scripts/artagon java release tag 1.2.3
scripts/artagon java release branch cut 1.2.3
scripts/artagon java release branch stage [--deploy]

# Snapshot deployment
scripts/artagon java snapshot publish

# Dependency security
scripts/artagon java security update
scripts/artagon java security verify

# GitHub branch protection
scripts/artagon java gh protect --branch main
```

Add `--dry-run` (or `-n`) before the command to log actions without
executing them.

### Configuration

Defaults are loaded from `.artagonrc`. Example:

```toml
[defaults]
language = "java"
owner = "your-github-org"
repo = "your-repo"
```

Override via environment variable `ARTAGON_CONFIG=/path/to/config` to
point at a different file.

## Legacy Structure

```
scripts/
├── gh_auto_create_and_push.sh      # GitHub repository creation
├── repo_add_artagon_common.sh      # Submodule setup
├── gh_sync_agents.sh               # Unified agent configuration sync (Claude, Codex, etc.)
├── deploy/                      # Deployment automation
│   ├── check-deploy-ready.sh    # Pre-deployment validation
│   ├── mvn_deploy_snapshot.sh       # Deploy snapshot to OSSRH
│   ├── nexus-mvn_release.sh         # Release from Nexus staging
│   └── mvn_release.sh               # Full release automation
├── ci/                          # CI/CD and branch protection
│   ├── gh_branch_protection_common.sh
│   ├── gh_check_branch_protection.sh
│   ├── gh_protect_main.sh
│   ├── gh_protect_main_strict.sh
│   ├── gh_protect_main_team.sh
│   └── gh_remove_branch_protection.sh
├── build/                       # Build-related scripts (future use)
└── dev/                         # Development tools (future use)
```

## Deployment Scripts

### deploy/mvn_check_ready.sh *(invoked via `artagon java release branch stage`)*

Validates deployment prerequisites and configuration.

**Usage**:
```bash
./scripts/deploy/mvn_check_ready.sh
```

**Checks**:
- GPG key availability
- Maven settings configuration
- POM metadata completeness
- Build status
- SNAPSHOT dependencies
- Git working directory status
- Security files

### deploy/mvn_deploy_snapshot.sh *(invoked via `artagon java snapshot publish`)*

Deploys SNAPSHOT versions to Sonatype OSSRH snapshots repository.

**Usage**:
```bash
./scripts/deploy/mvn_deploy_snapshot.sh
```

**Requirements**:
- Version must end with `-SNAPSHOT`
- All tests must pass
- GPG key configured
- OSSRH credentials in `~/.m2/settings.xml`

### deploy/mvn_release.sh *(invoked via `artagon java release run`)*

Creates and deploys a release version to Maven Central using the **release branch strategy**.

**IMPORTANT**: This script must be run from a `release-*` branch that has a SNAPSHOT version.

**Usage**:
```bash
./scripts/deploy/mvn_release.sh
```

**Prerequisites**:
1. Main branch is at next SNAPSHOT version (e.g., `1.0.9-SNAPSHOT`)
2. Create release branch from commit at desired SNAPSHOT:
   ```bash
   git checkout -b release-1.0.8 <commit-at-1.0.8-SNAPSHOT>
   ```
3. Run script from release branch

**Process**:
1. Validates you're on a `release-*` branch
2. Validates version is SNAPSHOT
3. Removes `-SNAPSHOT` suffix (e.g., `1.0.8-SNAPSHOT` → `1.0.8`)
4. Updates BOM checksums
5. Commits and tags release (`v1.0.8`)
6. Deploys to OSSRH staging

**Post-release steps**:
```bash
# Push release branch and tag
git push origin release-1.0.8 --tags

# Release from staging
./scripts/deploy/mvn_release_nexus.sh

# Create GitHub release
gh release create v1.0.8 --generate-notes
```

**Release Branch Strategy**:
- Main branch: Always SNAPSHOT (e.g., `1.0.9-SNAPSHOT`)
- Release branch: Release version without SNAPSHOT (e.g., `1.0.8`)
- Release branches are kept for hotfixes (not deleted)

See [artagon-workflows/RELEASE.md](https://github.com/artagon/artagon-workflows/blob/main/RELEASE.md) for complete documentation.

### deploy/mvn_release_nexus.sh

Releases staged artifacts from Nexus to Maven Central.

**Usage**:
```bash
./scripts/deploy/mvn_release_nexus.sh
```

**When to use**:
- After running `mvn_release.sh` or `mvn_deploy_snapshot.sh -Possrh-deploy`
- When you want to promote staged artifacts to Maven Central

**Alternative**:
Use the Nexus UI: https://s01.oss.sonatype.org/

## CI/CD Scripts

For branch protection and CI/CD automation, see the `ci/` directory and the main [README](../README.md#branch-protection) for full documentation.

## Repository Tooling

### gh_sync_agents.sh

Unified script that manages AI agent configurations (Claude, Codex, etc.) with shared guidance from artagon-common. The script:
- Copies agent directories from `.common/artagon-common`
- Creates root-level symlinks (`.agents`, `.claude`, `.codex`)
- Generates project.md files with YAML pointers to shared content
- Creates project-specific overlay files with references to shared preferences

**Usage**:
```bash
./scripts/gh_sync_agents.sh --ensure     # Create/update all agents (default)
./scripts/gh_sync_agents.sh --check      # Verify structure only
./scripts/gh_sync_agents.sh --models claude  # Sync only Claude
./scripts/gh_sync_agents.sh --dry-run    # Preview changes
```

**Options:**
- `--ensure` - Create/update directories, files, and symlinks (default)
- `--check` - Verify structure only; fail if invariants are broken
- `--dry-run` - Preview changes without making modifications
- `--models <models>` - Sync specific models (default: "claude codex")
- `-q, --quiet` - Suppress informational output
- `-h, --help` - Show help

The git hooks (`pre-commit`, `post-checkout`, `post-merge`) invoke the script automatically so agent configurations stay synchronized after branch switches or merges.

## Quick Start

### First Time Setup

1. **Install Prerequisites**:
   ```bash
   # Install GPG (if needed)
   brew install gnupg  # macOS
   # or
   apt-get install gnupg  # Ubuntu

   # Generate GPG key
   gpg --gen-key
   gpg --keyserver keys.openpgp.org --send-keys YOUR_KEY_ID
   ```

2. **Configure Maven**:
   
   Edit `~/.m2/settings.xml`:
   ```xml
   <settings>
       <servers>
           <server>
               <id>ossrh</id>
               <username>YOUR_USERNAME</username>
               <password>YOUR_PASSWORD</password>
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

3. **Verify Setup**:
   ```bash
   scripts/artagon java release branch stage --dry-run
   ```

### Deploy Snapshot

```bash
scripts/artagon java snapshot publish
```

### Release to Maven Central

**Using Release Branch Strategy:**

```bash
# 1. Ensure main is at next SNAPSHOT version
# artagon-bom should be at 1.0.9-SNAPSHOT
# artagon-parent should be at next SNAPSHOT

# 2. Create release branch from commit at desired SNAPSHOT
git checkout -b release-1.0.8 <commit-at-1.0.8-SNAPSHOT>

# 3. Run release script from release branch
./scripts/deploy/mvn_release.sh

# 4. Push release branch and tags
git push origin release-1.0.8 --tags

# 5. Release from Nexus staging
./scripts/deploy/mvn_release_nexus.sh

# 6. Create GitHub release
gh release create v1.0.8 --generate-notes
```

**Key Points:**
- Main branch stays at SNAPSHOT version (unchanged)
- Release branch has release version without SNAPSHOT
- Release branches are kept for hotfixes

## Troubleshooting

### GPG Issues

```bash
# Test GPG signing
echo "test" | gpg --clear-sign

# If you get "Inappropriate ioctl for device"
export GPG_TTY=$(tty)
```

### Maven Settings

```bash
# Encrypt passwords (recommended)
mvn --encrypt-master-password YOUR_MASTER_PASSWORD
mvn --encrypt-password YOUR_SONATYPE_PASSWORD
```

### Nexus Staging

```bash
# List all staging repositories
mvn nexus-staging:rc-list -Possrh-deploy

# Drop a failed staging repository
mvn nexus-staging:drop -Possrh-deploy

# Close staging repository
mvn nexus-staging:close -Possrh-deploy
```

## Environment Variables

Alternative to `~/.m2/settings.xml`:

```bash
export SONATYPE_USERNAME="your-username"
export SONATYPE_PASSWORD="your-password"
export GPG_PASSPHRASE="your-passphrase"

# Then deploy
mvn clean deploy -Possrh-deploy \
  -Dusername=$SONATYPE_USERNAME \
  -Dpassword=$SONATYPE_PASSWORD \
  -Dgpg.passphrase=$GPG_PASSPHRASE
```

## Manual Commands

If you prefer not to use scripts:

```bash
# Snapshot deployment
mvn clean deploy -Possrh-deploy,artagon-oss-release

# Release deployment
mvn versions:set -DnewVersion=1.0.0
mvn clean deploy -Possrh-deploy,artagon-oss-release
mvn nexus-staging:release -Possrh-deploy
```

## Resources

- [Full Deployment Guide](../docs/java/MAVEN_RELEASE_GUIDE.md#deployment-reference)
- [Sonatype OSSRH](https://central.sonatype.org/publish/publish-guide/)
- [Maven GPG Plugin](https://maven.apache.org/plugins/maven-gpg-plugin/)
