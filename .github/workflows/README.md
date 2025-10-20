# Artagon Reusable GitHub Actions Workflows

Reusable GitHub Actions workflows for Java/Maven projects deploying to Maven Central (Sonatype OSSRH).

## Table of Contents

- [Overview](#overview)
- [Available Workflows](#available-workflows)
- [Quick Start](#quick-start)
- [Workflow Reference](#workflow-reference)
- [Setup Instructions](#setup-instructions)
- [Examples](#examples)

---

## Overview

These reusable workflows provide standardized CI/CD pipelines for Java projects:

- **maven_build.yml** - Build and test Java projects with Maven
- **maven_deploy.yml** - Deploy artifacts to Maven Central (Sonatype OSSRH)
- **maven_release.yml** - Automated release process with versioning
- **maven_release_branch.yml** - Validate release branches and optionally deploy to staging
- **maven_release_tag.yml** - Publish tagged releases after validation
- **maven_security_scan.yml** - Comprehensive security scanning

### Benefits

✅ **Standardized** - Consistent build/deploy process across projects
✅ **Reusable** - Define once, use everywhere
✅ **Maintainable** - Update workflows in one place
✅ **Secure** - Built-in security scanning and GPG signing
✅ **Flexible** - Configurable inputs for different use cases

---

## Available Workflows

### 1. Maven Build (maven_build.yml)

Builds and tests Java projects with customizable options.

**Inputs:**
- `java-version` - Java version (default: '25')
- `java-distribution` - Java distribution (default: 'temurin')
- `maven-args` - Additional Maven arguments
- `run-tests` - Whether to run tests (default: true)
- `run-integration-tests` - Whether to run integration tests (default: false)
- `cache-key-prefix` - Cache key prefix (default: 'maven')

**Outputs:**
- `build-version` - The project version that was built

### 2. Maven Deploy (maven_deploy.yml)

Deploys artifacts to Maven Central (Sonatype OSSRH).

**Inputs:**
- `java-version` - Java version (default: '25')
- `java-distribution` - Java distribution (default: 'temurin')
- `deploy-profile` - Maven profile for deployment (default: 'ossrh-deploy,artagon-oss-release')
- `skip-tests` - Skip tests during deployment (default: true)
- `maven-args` - Additional Maven arguments

**Required Secrets:**
- `OSSRH_USERNAME` - Sonatype OSSRH username
- `OSSRH_PASSWORD` - Sonatype OSSRH password
- `GPG_PRIVATE_KEY` - GPG private key for signing
- `GPG_PASSPHRASE` - GPG passphrase

### 3. Maven Release (maven_release.yml)

Automated release process with versioning and tagging.

**Inputs:**
- `java-version` - Java version (default: '25')
- `java-distribution` - Java distribution (default: 'temurin')
- `release-version` - Release version (e.g., '1.0.0') **[REQUIRED]**
- `next-snapshot-version` - Next snapshot version (auto-increments if empty)
- `deploy-profile` - Maven profile (default: 'ossrh-deploy,artagon-oss-release')
- `auto-release-nexus` - Automatically release from Nexus staging (default: false)
- `create-github-release` - Create GitHub release (default: true)

**Required Secrets:**
- `OSSRH_USERNAME`
- `OSSRH_PASSWORD`
- `GPG_PRIVATE_KEY`
- `GPG_PASSPHRASE`
- `GITHUB_TOKEN` (optional, uses default if not provided)

**Outputs:**
- `release-tag` - The git tag created for the release

### 4. Maven Security Scan (maven_security_scan.yml)

Comprehensive security scanning with multiple tools.

**Inputs:**
- `java-version` - Java version (default: '25')
- `run-dependency-check` - Run OWASP Dependency Check (default: true)
- `run-ossindex-audit` - Run Sonatype OSS Index audit (default: true)
- `run-trivy-scan` - Run Trivy vulnerability scanner (default: true)
- `fail-on-severity` - Fail on vulnerability severity (default: 'HIGH')

**Scans performed:**
- ✅ Sonatype OSS Index audit
- ✅ OWASP Dependency Check
- ✅ Trivy vulnerability scanner
- ✅ SpotBugs security analysis

### 5. Maven Release Branch (maven_release_branch.yml)

Validates `release-*` branches, runs build and security baselines, enforces version naming rules, and can optionally push artifacts to staging repositories.

**Inputs:**
- `deploy-to-staging` - Deploy to staging repositories after validation (default: false)
- `run-tests`, `run-integration-tests`, `maven-args` - Forwarded to the build workflow
- `run-dependency-check`, `run-ossindex-audit`, `run-trivy-scan`, `fail-on-severity` - Forwarded to the security workflow
- `deploy-profile`, `deploy-skip-tests`, `deploy-args` - Passed to the deploy workflow when staging is enabled

**Secrets:**
- `OSSRH_USERNAME`, `OSSRH_PASSWORD`, `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE` are required when `deploy-to-staging` is `true`

### 6. Maven Release Tag (maven_release_tag.yml)

Verifies the pushed Git tag against the Maven project version and publishes artifacts using the shared deploy workflow.

**Inputs:**
- `tag` - The git tag to publish (defaults to the caller workflow ref)
- `deploy-profile` - Maven profile to use when deploying (default: 'ossrh-deploy,artagon-oss-release')
- `skip-tests` - Skip tests during deployment (default: false)
- `maven-args` - Additional Maven arguments passed to `mvn`

**Secrets:**
- `OSSRH_USERNAME`
- `OSSRH_PASSWORD`
- `GPG_PRIVATE_KEY`
- `GPG_PASSPHRASE`

---

## Quick Start

### 1. Create Workflow File

Create `.github/workflows/ci.yml` in your repository:

```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    uses: artagon/artagon-common/.github/workflows/maven_build.yml@main
    with:
      java-version: '25'
      run-tests: true
```

### 2. Add Repository Secrets

Go to **Settings > Secrets and variables > Actions** and add:

- `OSSRH_USERNAME` - Your Sonatype OSSRH username
- `OSSRH_PASSWORD` - Your Sonatype OSSRH password
- `GPG_PRIVATE_KEY` - Your GPG private key
- `GPG_PASSPHRASE` - Your GPG passphrase

### 3. Use the Workflow

Push to your repository or create a pull request to trigger the workflow.

### 4. Wire Up Release Automation

- Copy `.github/workflows/examples/release-branch.yml` to orchestrate builds and security checks on `release-*` branches. The optional manual input stages a build to OSSRH once QA signs off.
- Copy `.github/workflows/examples/release-tag.yml` to publish whenever a `v*` tag is pushed. The workflow verifies that the Maven version matches the tag before calling the reusable deploy pipeline.
- Keep `.github/workflows/examples/release.yml` as a manual fallback. Run it from the relevant `release-*` branch if you need a fully managed release (version bump → deploy → retag).

---

## Setup Instructions

### Prerequisites

1. **Sonatype OSSRH Account**
   - Create account at https://issues.sonatype.org
   - Request namespace for your groupId

2. **GPG Key**
   ```bash
   # Generate GPG key
   gpg --gen-key

   # Export private key
   gpg --armor --export-secret-keys YOUR_KEY_ID

   # Publish public key
   gpg --keyserver keys.openpgp.org --send-keys YOUR_KEY_ID
   ```

3. **GitHub Repository Secrets**

   Add the following secrets to your repository:

   **For Deployment:**
   - `OSSRH_USERNAME` - Sonatype username
   - `OSSRH_PASSWORD` - Sonatype password
   - `GPG_PRIVATE_KEY` - Full GPG private key (including `-----BEGIN PGP PRIVATE KEY BLOCK-----`)
   - `GPG_PASSPHRASE` - GPG key passphrase

   **Optional:**
   - `GITHUB_TOKEN` - Auto-provided by GitHub Actions (for releases)

### Getting Your GPG Private Key

```bash
# List your keys
gpg --list-secret-keys --keyid-format LONG

# Export the private key
gpg --armor --export-secret-keys YOUR_KEY_ID
```

Copy the entire output (including the BEGIN and END lines) and paste it into the `GPG_PRIVATE_KEY` secret.

---

## Examples

### Example 1: CI Pipeline

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    name: Build and Test
    uses: artagon/artagon-common/.github/workflows/maven_build.yml@main
    with:
      java-version: '25'
      run-tests: true
      run-integration-tests: false

  security:
    name: Security Scan
    needs: build
    uses: artagon/artagon-common/.github/workflows/maven_security_scan.yml@main
    with:
      run-dependency-check: true
      run-ossindex-audit: true
      run-trivy-scan: true
```

### Example 2: Snapshot Deployment

```yaml
name: Deploy Snapshot

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    uses: artagon/artagon-common/.github/workflows/maven_deploy.yml@main
    with:
      java-version: '25'
      deploy-profile: 'ossrh-deploy'
      skip-tests: true
    secrets:
      OSSRH_USERNAME: ${{ secrets.OSSRH_USERNAME }}
      OSSRH_PASSWORD: ${{ secrets.OSSRH_PASSWORD }}
      GPG_PRIVATE_KEY: ${{ secrets.GPG_PRIVATE_KEY }}
      GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
```

### Example 3: Release Workflow

```yaml
name: Release

on:
  workflow_dispatch:
    inputs:
      release-version:
        description: 'Release version (e.g., 1.0.0)'
        required: true
      auto-release:
        description: 'Auto-release from Nexus staging'
        type: boolean
        default: false

jobs:
  release:
    uses: artagon/artagon-common/.github/workflows/maven_release.yml@main
    with:
      release-version: ${{ inputs.release-version }}
      auto-release-nexus: ${{ inputs.auto-release }}
      create-github-release: true
    secrets:
      OSSRH_USERNAME: ${{ secrets.OSSRH_USERNAME }}
      OSSRH_PASSWORD: ${{ secrets.OSSRH_PASSWORD }}
      GPG_PRIVATE_KEY: ${{ secrets.GPG_PRIVATE_KEY }}
      GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Example 4: Matrix Build (Multiple Java Versions)

```yaml
name: Matrix CI

on: [push, pull_request]

jobs:
  build:
    strategy:
      matrix:
        java: ['21', '25']
    uses: artagon/artagon-common/.github/workflows/maven_build.yml@main
    with:
      java-version: ${{ matrix.java }}
      run-tests: true
```

---

## Workflow Versioning

You can reference workflows by:

- **Latest**: `@main` - Always uses the latest version
- **Tag**: `@v1.0.0` - Uses a specific version
- **Commit**: `@abc123` - Uses a specific commit

**Recommended**: Use tags for production workflows:

```yaml
uses: artagon/artagon-common/.github/workflows/maven_build.yml@v1.0.0
```

---

## Customization

### Using Your Own Maven Profiles

```yaml
jobs:
  deploy:
    uses: artagon/artagon-common/.github/workflows/maven_deploy.yml@main
    with:
      deploy-profile: 'my-custom-profile,another-profile'
    secrets:
      OSSRH_USERNAME: ${{ secrets.OSSRH_USERNAME }}
      # ... other secrets
```

### Adding Custom Maven Arguments

```yaml
jobs:
  build:
    uses: artagon/artagon-common/.github/workflows/maven_build.yml@main
    with:
      maven-args: '-Dmy.property=value -X'
```

### Conditional Execution

```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main'
    uses: artagon/artagon-common/.github/workflows/maven_deploy.yml@main
    # ...
```

---

## Troubleshooting

### GPG Signing Fails

**Error**: `gpg: signing failed: Inappropriate ioctl for device`

**Solution**: The workflow already sets `GPG_TTY` and uses `--batch` mode. Ensure your `GPG_PRIVATE_KEY` secret contains the complete private key.

### Maven Deployment Fails with 401

**Error**: `Failed to deploy: 401 Unauthorized`

**Solution**:
- Verify `OSSRH_USERNAME` and `OSSRH_PASSWORD` secrets are correct
- Check that your Sonatype account has access to the groupId

### Release Workflow Can't Push

**Error**: `Permission denied`

**Solution**: Ensure the workflow has write permissions. Add to your workflow:

```yaml
permissions:
  contents: write
  packages: write
```

### Security Scan Takes Too Long

**Solution**: Disable slower scans:

```yaml
jobs:
  security:
    uses: artagon/artagon-common/.github/workflows/security-scan.yml@main
    with:
      run-dependency-check: false  # Skip OWASP check
      run-trivy-scan: true
```

---

## Best Practices

1. **Use Version Tags** - Reference workflows by version tag, not `@main`
2. **Separate Environments** - Use different workflows for dev/staging/prod
3. **Manual Releases** - Use `workflow_dispatch` for release workflows
4. **Secret Rotation** - Regularly rotate GPG keys and passwords
5. **Security Scans** - Run security scans on every PR
6. **Cache Dependencies** - The workflows automatically cache Maven dependencies

---

## Contributing

To improve these workflows:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with example workflows
5. Submit a pull request

---

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Reusable Workflows Guide](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [Maven Central Publishing Guide](https://central.sonatype.org/publish/publish-guide/)
- [Artagon Deployment Guide](../../DEPLOYMENT.md)

---

## Support

For issues or questions:
- Open an issue in the repository
- Check existing documentation in `DEPLOYMENT.md`
- Review example workflows in `examples/`
