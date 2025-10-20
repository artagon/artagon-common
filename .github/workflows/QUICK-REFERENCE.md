# GitHub Actions Quick Reference

Quick reference for using Artagon reusable workflows.

## One-Line Setup

### Basic CI

```yaml
jobs:
  build:
    uses: artagon/artagon-common/.github/workflows/maven_build.yml@main
```

### Deploy Snapshot

```yaml
jobs:
  deploy:
    uses: artagon/artagon-common/.github/workflows/maven_deploy.yml@main
    secrets: inherit
```

### Release

```yaml
jobs:
  release:
    # Run this workflow from a release-* branch selected in the manual dispatch form
    uses: artagon/artagon-common/.github/workflows/maven_release.yml@main
    with:
      release-version: '1.0.0'
    secrets: inherit
```

### Security Scan

```yaml
jobs:
  security:
    uses: artagon/artagon-common/.github/workflows/maven_security_scan.yml@main
```

---

## Required Secrets

Add to **Settings > Secrets and variables > Actions**:

```
OSSRH_USERNAME     # Sonatype username
OSSRH_PASSWORD     # Sonatype password
GPG_PRIVATE_KEY    # GPG private key (full block)
GPG_PASSPHRASE     # GPG passphrase
```

---

## Complete Examples

### Minimal CI

```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    uses: artagon/artagon-common/.github/workflows/maven_build.yml@main
```

### CI + Security

```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    uses: artagon/artagon-common/.github/workflows/maven_build.yml@main
  security:
    needs: build
    uses: artagon/artagon-common/.github/workflows/maven_security_scan.yml@main
```

### Auto-Deploy Snapshots

```yaml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    uses: artagon/artagon-common/.github/workflows/maven_deploy.yml@main
    secrets:
      OSSRH_USERNAME: ${{ secrets.OSSRH_USERNAME }}
      OSSRH_PASSWORD: ${{ secrets.OSSRH_PASSWORD }}
      GPG_PRIVATE_KEY: ${{ secrets.GPG_PRIVATE_KEY }}
      GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
```

### Release Branch Checks

```yaml
name: Release Branch
on:
  push:
    branches: ['release-*']
jobs:
  release:
    uses: artagon/artagon-common/.github/workflows/maven_release_branch.yml@main
    with:
      deploy-to-staging: false
    secrets: inherit
```

### Publish on Release Tag

```yaml
name: Publish Release
on:
  push:
    tags: ['v*']
jobs:
  release:
    uses: artagon/artagon-common/.github/workflows/maven_release_tag.yml@main
    secrets: inherit
```

### Manual Release

```yaml
name: Release
on:
  workflow_dispatch:
    inputs:
      version:
        required: true
jobs:
  release:
    uses: artagon/artagon-common/.github/workflows/maven_release.yml@main
    with:
      release-version: ${{ inputs.version }}
    secrets:
      OSSRH_USERNAME: ${{ secrets.OSSRH_USERNAME }}
      OSSRH_PASSWORD: ${{ secrets.OSSRH_PASSWORD }}
      GPG_PRIVATE_KEY: ${{ secrets.GPG_PRIVATE_KEY }}
      GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
```

---

## Common Customizations

### Different Java Version

```yaml
with:
  java-version: '21'
```

### Skip Tests

```yaml
with:
  run-tests: false
```

### Custom Maven Profile

```yaml
with:
  deploy-profile: 'my-profile'
```

### Multiple Java Versions

```yaml
jobs:
  build:
    strategy:
      matrix:
        java: ['21', '25']
    uses: artagon/artagon-common/.github/workflows/java-build.yml@main
    with:
      java-version: ${{ matrix.java }}
```

---

## Troubleshooting

**Build fails**: Check Java version and Maven configuration
**Deployment fails**: Verify secrets are set correctly
**GPG signing fails**: Ensure GPG_PRIVATE_KEY includes BEGIN/END lines
**Tests fail**: Use `run-tests: false` to skip during deployment

---

## Getting GPG Private Key

```bash
gpg --armor --export-secret-keys YOUR_KEY_ID
```

Copy entire output including:
```
-----BEGIN PGP PRIVATE KEY BLOCK-----
...
-----END PGP PRIVATE KEY BLOCK-----
```

---

## File Structure

```
.github/workflows/
├── ci.yml              # CI pipeline
├── deploy.yml          # Snapshot deployment
└── release.yml         # Release workflow
```

---

## Full Documentation

See [README.md](README.md) for complete documentation.
