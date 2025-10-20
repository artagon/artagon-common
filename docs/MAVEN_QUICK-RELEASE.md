# Quick Release - Right Now! 🚀

## Method 1: Release via GitHub Web Interface (Easiest)

### For artagon-bom:

1. **Go to**: https://github.com/artagon/artagon-bom/actions
2. **Click**: "Deploy to GitHub Packages" (in left sidebar)
3. **Click**: "Run workflow" button (right side)
4. **Select**:
   - Branch: `release-x.y.z`
   - Deployment type: `release`
5. **Click**: "Run workflow" (green button)

✅ **Done!** Package will be available at: https://github.com/artagon/artagon-bom/packages

### For artagon-parent:

1. **Go to**: https://github.com/artagon/artagon-parent/actions
2. **Click**: "Deploy to GitHub Packages" (in left sidebar)
3. **Click**: "Run workflow" button (right side)
4. **Select**:
   - Branch: `release-x.y.z`
   - Deployment type: `release`
5. **Click**: "Run workflow" (green button)

✅ **Done!** Package will be available at: https://github.com/artagon/artagon-parent/packages

---

## Method 2: Automatic Release on Push (Simplest)

Just push to your `release-x.y.z` branch - the workflow automatically deploys (or stages) the build!

```bash
# Already done! Your current push already triggered deployment
# Check: https://github.com/artagon/artagon-bom/actions
# Check: https://github.com/artagon/artagon-parent/actions
```

---

## Method 3: Release via Git Tag

### artagon-bom:
```bash
cd /Users/gtrump001c@cable.comcast.com/Projects/Artagon/artagon-bom
git tag bom-v1.0.0
git push origin bom-v1.0.0
```

### artagon-parent:
```bash
cd /Users/gtrump001c@cable.comcast.com/Projects/Artagon/artagon-parent
git tag v1
git push origin v1
```

✅ `.github/workflows/examples/release-tag.yml` validates the tag against the Maven version and auto-deploys to GitHub Packages / Maven Central!

---

## Verify Deployment

### Check GitHub Actions:
- artagon-bom: https://github.com/artagon/artagon-bom/actions
- artagon-parent: https://github.com/artagon/artagon-parent/actions

### Check Packages:
- artagon-bom: https://github.com/orgs/artagon/packages?repo_name=artagon-bom
- artagon-parent: https://github.com/orgs/artagon/packages?repo_name=artagon-parent

---

## Current Versions

- **artagon-bom**: `1.0.0`
- **artagon-parent**: `1`

---

## What Gets Deployed

✅ POM files
✅ Source JARs (for parent)
✅ Javadoc JARs (for parent)
✅ GPG signatures (if GPG secrets configured)
✅ Checksums (SHA-256, SHA-512)

---

## Consuming the Packages

After release, users can use your packages:

```xml
<parent>
    <groupId>org.artagon</groupId>
    <artifactId>artagon-parent</artifactId>
    <version>1</version>
</parent>
```

**See**: [MAVEN_GITHUB-PACKAGES.md](MAVEN_GITHUB-PACKAGES.md) for complete usage guide

---

## Need More Control?

See [MAVEN_RELEASE_GUIDE.md](MAVEN_RELEASE_GUIDE.md) for:
- Version management
- Maven Central releases
- Advanced workflows
- Troubleshooting

---

## That's It! 🎉

Your projects are configured and ready to release!
