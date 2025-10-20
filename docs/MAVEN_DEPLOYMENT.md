# Artagon OSS Deployment Guide

This guide covers deploying artagon-bom and artagon-parent to Maven Central via Sonatype OSSRH.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Deployment Process](#deployment-process)
4. [Release Workflow](#release-workflow)
5. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### 1. Sonatype OSSRH Account

- Create account at https://issues.sonatype.org
- Request access for `org.artagon` groupId
- Follow: https://central.sonatype.org/publish/publish-guide/

### 2. GPG Key Setup

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

### 3. Maven Settings Configuration

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

## Initial Setup

### 1. Verify POM Completeness

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

### 2. Check Current Status

```bash
cd /Users/gtrump001c@cable.comcast.com/Projects/Artagon

# Verify build works
mvn clean verify

# Check for SNAPSHOT dependencies (releases can't have them)
mvn dependency:tree | grep SNAPSHOT
```

---

## Deployment Process

### Snapshot Deployment

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

### Release Deployment

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

## Release Workflow

### Using Maven Release Plugin

```bash
cd /Users/gtrump001c@cable.comcast.com/Projects/Artagon

# Prepare release (updates versions, creates tag)
mvn release:prepare -Possrh-deploy

# Perform release (builds and deploys)
mvn release:perform -Possrh-deploy

# If something goes wrong, rollback
mvn release:rollback
```

### Manual Release Checklist

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

## Deployment Profiles

### artagon-bom Profiles

**`ossrh-deploy`** - Deploy to OSSRH
- GPG signing
- Nexus staging

```bash
mvn clean deploy -Possrh-deploy
```

### artagon-parent Profiles

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

## Verification

### After Snapshot Deployment

```bash
# Check if artifacts are available
curl -I https://s01.oss.sonatype.org/content/repositories/snapshots/org/artagon/artagon-bom/1.0.0-SNAPSHOT/

# Test using snapshot
mvn dependency:get \
  -DremoteRepositories=https://s01.oss.sonatype.org/content/repositories/snapshots \
  -Dartifact=org.artagon:artagon-bom:1.0.0-SNAPSHOT:pom
```

### After Release

Wait 2-4 hours for sync to Maven Central:

```bash
# Check Maven Central
curl -I https://repo1.maven.org/maven2/org/artagon/artagon-bom/1.0.0/

# Verify in search
# https://search.maven.org/artifact/org.artagon/artagon-bom/1.0.0/pom
```

---

## Troubleshooting

### GPG Signing Issues

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

### Nexus Staging Issues

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

### Common Errors

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

## Environment Variables

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

## CI/CD Integration

### GitHub Actions Example

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

## Resources

- [Sonatype OSSRH Guide](https://central.sonatype.org/publish/publish-guide/)
- [Maven GPG Plugin](https://maven.apache.org/plugins/maven-gpg-plugin/)
- [Nexus Staging Plugin](https://github.com/sonatype/nexus-maven-plugins)
- [Maven Central Requirements](https://central.sonatype.org/publish/requirements/)

---

## Quick Reference

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
