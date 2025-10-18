# Using Artagon Packages from GitHub Packages

This guide explains how to consume Artagon Maven artifacts from GitHub Packages.

## Overview

Artagon packages are published to two Maven repositories:
1. **Maven Central (OSSRH)** - Public, no authentication required
2. **GitHub Packages** - Requires GitHub authentication

## Why GitHub Packages?

- **Snapshot Builds**: Get the latest development snapshots
- **Pre-release Versions**: Access beta/RC versions before Maven Central
- **Private Packages**: Can host private forks or extensions
- **GitHub Integration**: Seamless integration with GitHub workflows

## Prerequisites

### 1. Generate a GitHub Personal Access Token (PAT)

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "Maven GitHub Packages")
4. Select scopes:
   - `read:packages` - To download packages
   - `write:packages` - To publish packages (if needed)
5. Click "Generate token" and **copy the token** (you won't see it again)

### 2. Configure Maven Settings

Add the following to your `~/.m2/settings.xml`:

```xml
<settings>
  <servers>
    <server>
      <id>github</id>
      <username>YOUR_GITHUB_USERNAME</username>
      <password>YOUR_GITHUB_PAT</password>
    </server>
  </servers>

  <profiles>
    <profile>
      <id>github</id>
      <repositories>
        <repository>
          <id>github</id>
          <url>https://maven.pkg.github.com/artagon/*</url>
          <snapshots>
            <enabled>true</enabled>
          </snapshots>
          <releases>
            <enabled>true</enabled>
          </releases>
        </repository>
      </repositories>
    </profile>
  </profiles>

  <activeProfiles>
    <activeProfile>github</activeProfile>
  </activeProfiles>
</settings>
```

Replace:
- `YOUR_GITHUB_USERNAME` with your GitHub username
- `YOUR_GITHUB_PAT` with your Personal Access Token

## Using Artagon Packages

### Option 1: Using artagon-parent (Recommended)

Simply reference artagon-parent in your project:

```xml
<project>
    <parent>
        <groupId>org.artagon</groupId>
        <artifactId>artagon-parent</artifactId>
        <version>1</version>
    </parent>

    <!-- Your project configuration -->
</project>
```

The parent POM already imports artagon-bom, so all dependency versions are managed.

### Option 2: Using artagon-bom Directly

Import the BOM in your dependencyManagement:

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.artagon</groupId>
            <artifactId>artagon-bom</artifactId>
            <version>1.0.0</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

### Option 3: Add GitHub Repository to Your POM

If you don't want to use `settings.xml`, add the repository to your `pom.xml`:

```xml
<repositories>
    <repository>
        <id>github-artagon-bom</id>
        <url>https://maven.pkg.github.com/artagon/artagon-bom</url>
        <snapshots>
            <enabled>true</enabled>
        </snapshots>
    </repository>
    <repository>
        <id>github-artagon-parent</id>
        <url>https://maven.pkg.github.com/artagon/artagon-parent</url>
        <snapshots>
            <enabled>true</enabled>
        </snapshots>
    </repository>
</repositories>
```

**Note**: You still need GitHub authentication in `settings.xml` even with this approach.

## Using Snapshot Versions

To use the latest snapshot builds:

```xml
<parent>
    <groupId>org.artagon</groupId>
    <artifactId>artagon-parent</artifactId>
    <version>2-SNAPSHOT</version>
</parent>
```

Maven will automatically fetch the latest snapshot from GitHub Packages.

## CI/CD Integration

### GitHub Actions

GitHub Actions automatically have access to GitHub Packages:

```yaml
- name: Build with Maven
  run: mvn clean install
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

The `GITHUB_TOKEN` is automatically provided by GitHub Actions.

### Other CI Systems

For other CI systems (Jenkins, GitLab CI, etc.):

1. Store your GitHub PAT as a secret environment variable
2. Configure Maven settings.xml dynamically:

```bash
cat > ~/.m2/settings.xml <<EOF
<settings>
  <servers>
    <server>
      <id>github</id>
      <username>\${env.GITHUB_USERNAME}</username>
      <password>\${env.GITHUB_TOKEN}</password>
    </server>
  </servers>
</settings>
EOF

mvn clean install
```

## Troubleshooting

### 401 Unauthorized

**Cause**: Invalid or missing GitHub token

**Solution**:
- Verify your GitHub PAT has `read:packages` scope
- Check that the token hasn't expired
- Ensure `settings.xml` has correct credentials

### 404 Not Found

**Cause**: Package doesn't exist or you don't have access

**Solution**:
- Verify the package version exists: https://github.com/artagon/artagon-bom/packages
- Check if it's a private package and you have access
- Ensure you're using the correct groupId and artifactId

### Connection Timeout

**Cause**: Network issues or proxy blocking GitHub

**Solution**:
- Check your network connection
- Configure Maven proxy settings if behind a corporate firewall
- Try accessing https://maven.pkg.github.com in your browser

## Package URLs

- **artagon-bom**: https://github.com/artagon/artagon-bom/packages
- **artagon-parent**: https://github.com/artagon/artagon-parent/packages

## Deployment (For Maintainers)

### Deploy to GitHub Packages

Deployment to GitHub Packages happens automatically via GitHub Actions:

**Automatic Deployment:**
- Pushes to `main` branch trigger snapshot deployment
- Git tags trigger release deployment

**Manual Deployment:**
- Go to Actions → "Deploy to GitHub Packages"
- Click "Run workflow"
- Select deployment type (snapshot/release)

**Manual Maven Deploy:**
```bash
# Deploy snapshot
mvn clean deploy -P github-deploy -DskipTests

# Deploy release (requires version without -SNAPSHOT)
mvn versions:set -DnewVersion=1.0.0
mvn clean deploy -P github-deploy
```

## Best Practices

1. **Use Released Versions in Production**: Avoid SNAPSHOT dependencies in production
2. **Pin Versions**: Specify exact versions instead of version ranges
3. **Regular Updates**: Keep dependencies up to date for security patches
4. **Token Security**: Never commit GitHub tokens to version control
5. **Fallback to Maven Central**: Configure Maven Central as fallback repository

## Comparison: GitHub Packages vs Maven Central

| Feature | GitHub Packages | Maven Central |
|---------|----------------|---------------|
| **Authentication** | Required (GitHub PAT) | Not required |
| **Snapshots** | Supported | Separate snapshot repo |
| **Publishing Speed** | Instant | Hours to days |
| **Availability** | GitHub uptime | High SLA |
| **Private Packages** | Supported | Not supported (OSS only) |
| **Cost** | Free for public repos | Free |
| **Discovery** | GitHub search | mvnrepository.com |

## Support

For issues related to:
- **Artagon packages**: Open an issue in the respective repository
- **GitHub Packages**: See [GitHub Packages documentation](https://docs.github.com/en/packages)
- **Maven configuration**: See [Maven documentation](https://maven.apache.org/guides/)

## See Also

- [DEPLOYMENT.md](DEPLOYMENT.md) - How to deploy to Maven Central (OSSRH)
- [QUICKSTART-DEPLOY.md](QUICKSTART-DEPLOY.md) - Quick deployment guide
- [GitHub Packages Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-apache-maven-registry)
