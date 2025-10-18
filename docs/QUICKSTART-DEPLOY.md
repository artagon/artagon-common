# Quick Start: Deploying to Maven Central

A condensed guide for deploying artagon-bom and artagon-parent.

## Prerequisites (One-Time Setup)

### 1. Create Sonatype Account

1. Sign up at https://issues.sonatype.org
2. Create ticket requesting `org.artagon` namespace
3. Wait for approval (usually 1-2 business days)

### 2. Generate GPG Key

```bash
# Generate key
gpg --gen-key

# Get key ID
gpg --list-keys --keyid-format LONG

# Publish to keyserver
gpg --keyserver keys.openpgp.org --send-keys YOUR_KEY_ID
```

### 3. Configure Maven Settings

Create/edit `~/.m2/settings.xml`:

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

### 4. Verify Setup

```bash
./artagon-common/scripts/check-deploy-ready.sh
```

---

## Snapshot Deployment (Development)

Deploy SNAPSHOT versions for testing:

```bash
./artagon-common/scripts/deploy-snapshot.sh
```

**Or manually**:
```bash
mvn clean deploy -Possrh-deploy,artagon-oss-release
```

**Usage in projects**:
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

---

## Release to Maven Central (Production)

### Automated Release

```bash
# Run the release script
./artagon-common/scripts/release.sh 1.0.0

# Push to GitHub
git push origin main --tags

# Release from staging
./artagon-common/scripts/nexus-release.sh

# Create GitHub release
gh release create v1.0.0 --title "Release 1.0.0" --notes "Release notes..."
```

### Manual Release

```bash
# 1. Update versions
cd artagon-bom
mvn versions:set -DnewVersion=1.0.0
mvn versions:commit

cd ../artagon-parent
mvn versions:set -DnewVersion=1.0.0
mvn versions:commit

# 2. Update BOM reference in parent pom.xml
# Change: <version>1.0.0-SNAPSHOT</version>
# To:     <version>1.0.0</version>

# 3. Update checksums
cd ../artagon-bom
mvn clean verify
cp security/artagon-bom-checksums.csv ../artagon-parent/security/bom-checksums.csv

# 4. Commit and tag
cd ..
git add .
git commit -m "Release version 1.0.0"
git tag -a v1.0.0 -m "Release 1.0.0"

# 5. Deploy to staging
mvn clean deploy -Possrh-deploy,artagon-oss-release

# 6. Release from staging
mvn nexus-staging:release -Possrh-deploy
# OR use Nexus UI: https://s01.oss.sonatype.org/

# 7. Update to next SNAPSHOT
cd artagon-bom
mvn versions:set -DnewVersion=1.0.1-SNAPSHOT
mvn versions:commit

cd ../artagon-parent
mvn versions:set -DnewVersion=1.0.1-SNAPSHOT
mvn versions:commit

git add .
git commit -m "Prepare for next development iteration"

# 8. Push
git push origin main --tags
```

---

## Common Commands

```bash
# Check deployment readiness
./artagon-common/scripts/check-deploy-ready.sh

# Deploy snapshot
./artagon-common/scripts/deploy-snapshot.sh

# Release
./artagon-common/scripts/release.sh 1.0.0

# List staging repositories
mvn nexus-staging:rc-list -Possrh-deploy

# Drop failed staging
mvn nexus-staging:drop -Possrh-deploy

# Release staging
./artagon-common/scripts/nexus-release.sh
```

---

## Verification

### After Snapshot Deployment

```bash
# Check OSSRH snapshots
curl -I https://s01.oss.sonatype.org/content/repositories/snapshots/org/artagon/artagon-bom/1.0.0-SNAPSHOT/
```

### After Release

Wait 2-4 hours for Maven Central sync:

```bash
# Check Maven Central
curl -I https://repo1.maven.org/maven2/org/artagon/artagon-bom/1.0.0/

# Search Maven Central
open https://search.maven.org/search?q=g:org.artagon
```

---

## Troubleshooting

**"401 Unauthorized"**
- Check credentials in `~/.m2/settings.xml`
- Verify Sonatype account access

**"GPG signing failed"**
```bash
export GPG_TTY=$(tty)
echo "use-agent" >> ~/.gnupg/gpg.conf
```

**"Artifacts missing signatures"**
- Ensure GPG plugin is activated with `-Possrh-deploy`
- Check GPG key: `gpg --list-secret-keys`

**"POM incomplete metadata"**
- Run: `./artagon-common/scripts/check-deploy-ready.sh`
- Verify all required fields present

---

## Files Structure

```
artagon/
├── DEPLOYMENT.md              # Full deployment guide
├── QUICKSTART-DEPLOY.md       # This file
├── artagon-bom/
│   └── pom.xml               # BOM with ossrh-deploy profile
├── artagon-parent/
│   ├── pom.xml               # Parent with artagon-oss-release profile
│   └── security/
│       ├── bom-checksums.csv
│       └── pgp-trusted-keys.list
└── artagon-common/scripts/
    ├── check-deploy-ready.sh # Verify prerequisites
    ├── deploy-snapshot.sh    # Deploy SNAPSHOT
    ├── release.sh            # Full release process
    └── nexus-release.sh      # Release from Nexus staging
```

---

## Resources

- **Full Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Scripts README**: [artagon-common/scripts/README.md](artagon-common/scripts/README.md)
- **Sonatype Guide**: https://central.sonatype.org/publish/publish-guide/
- **Nexus Repository Manager**: https://s01.oss.sonatype.org/
