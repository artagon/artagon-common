# Artagon Scripts

Automation scripts for deployment, CI/CD, and repository management.

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
├── gh_sync_codex.sh                # Sync Codex overlays with shared guidance
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

### deploy/mvn_mvn_release.sh *(invoked via `artagon java release run`)*

Creates and deploys a release version to Maven Central.

**Usage**:
```bash
./scripts/deploy/mvn_mvn_release.sh <version>
```

**Example**:
```bash
./scripts/deploy/mvn_mvn_release.sh 1.0.0
```

**Process**:
1. Updates version numbers
2. Updates BOM checksums
3. Commits and tags release
4. Deploys to OSSRH staging
5. Updates to next SNAPSHOT version
6. Commits next development iteration

**Post-release steps**:
```bash
# Push to remote
git push origin main --tags

# Release from staging (see nexus-mvn_release.sh)
./scripts/deploy/mvn_release_nexus.sh

# Create GitHub release
gh release create v1.0.0 --title "Release 1.0.0" --notes "..."
```

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

### gh_sync_codex.sh

Keeps `codex/` and `.codex/` overlays aligned with the shared guidance shipped in `.common/artagon-common/.agents/codex`. The script creates symlinks, scaffolds project-specific overlays, and validates that local files still reference the shared defaults.

**Usage**:
```bash
./scripts/gh_sync_codex.sh --ensure   # repair links and stub overlays (default)
./scripts/gh_sync_codex.sh --check    # verify structure only
```

The git hooks (`pre-commit`, `post-checkout`, `post-merge`) invoke the script automatically so Codex preferences stay synchronized after branch switches or merges.

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

```bash
scripts/artagon java release run --version 1.0.0

# Push tags
git push origin main --tags

# Promote staging release if required
scripts/artagon java release branch stage --deploy
```

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
