# Artagon Deployment Scripts

Helper scripts for deploying artagon-bom and artagon-parent to Maven Central.

## Scripts

### check-deploy-ready.sh

Validates deployment prerequisites and configuration.

**Usage**:
```bash
./scripts/check-deploy-ready.sh
```

**Checks**:
- GPG key availability
- Maven settings configuration
- POM metadata completeness
- Build status
- SNAPSHOT dependencies
- Git working directory status
- Security files

### deploy-snapshot.sh

Deploys SNAPSHOT versions to Sonatype OSSRH snapshots repository.

**Usage**:
```bash
./scripts/deploy-snapshot.sh
```

**Requirements**:
- Version must end with `-SNAPSHOT`
- All tests must pass
- GPG key configured
- OSSRH credentials in `~/.m2/settings.xml`

### release.sh

Creates and deploys a release version to Maven Central.

**Usage**:
```bash
./scripts/release.sh <version>
```

**Example**:
```bash
./scripts/release.sh 1.0.0
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

# Release from staging (see nexus-release.sh)
./scripts/nexus-release.sh

# Create GitHub release
gh release create v1.0.0 --title "Release 1.0.0" --notes "..."
```

### nexus-release.sh

Releases staged artifacts from Nexus to Maven Central.

**Usage**:
```bash
./scripts/nexus-release.sh
```

**When to use**:
- After running `release.sh` or `deploy-snapshot.sh -Possrh-deploy`
- When you want to promote staged artifacts to Maven Central

**Alternative**:
Use the Nexus UI: https://s01.oss.sonatype.org/

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
   ./scripts/check-deploy-ready.sh
   ```

### Deploy Snapshot

```bash
# Check readiness
./scripts/check-deploy-ready.sh

# Deploy
./scripts/deploy-snapshot.sh
```

### Release to Maven Central

```bash
# Check readiness
./scripts/check-deploy-ready.sh

# Release
./scripts/release.sh 1.0.0

# Push to GitHub
git push origin main --tags

# Release from Nexus staging
./scripts/nexus-release.sh

# Create GitHub release
gh release create v1.0.0 --title "Release 1.0.0"
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

- [Full Deployment Guide](../DEPLOYMENT.md)
- [Sonatype OSSRH](https://central.sonatype.org/publish/publish-guide/)
- [Maven GPG Plugin](https://maven.apache.org/plugins/maven-gpg-plugin/)
