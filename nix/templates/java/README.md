# Nix Patterns for Artagon Parent POM (Maven/Java Projects)

## Overview

This guide provides Nix patterns and templates for creating reproducible development environments for Maven/Java projects like artagon-parent.

## Java Development Environment

### Basic Maven/Java Flake

```nix
{
  description = "Maven project with Java";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            jdk              # Latest JDK (25)
            maven
          ];

          JAVA_HOME = "${pkgs.jdk}/lib/openjdk";
        };
      }
    );
}
```

## JDK Version Selection

### Multiple JDK Shells

```nix
devShells = {
  # Default (JDK 25)
  default = pkgs.mkShell {
    buildInputs = [ pkgs.jdk pkgs.maven ];
    JAVA_HOME = "${pkgs.jdk}/lib/openjdk";
  };

  # JDK 17 (LTS)
  jdk17 = pkgs.mkShell {
    buildInputs = [ pkgs.jdk17 pkgs.maven ];
    JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
  };

  # JDK 21 (LTS)
  jdk21 = pkgs.mkShell {
    buildInputs = [ pkgs.jdk21 pkgs.maven ];
    JAVA_HOME = "${pkgs.jdk21}/lib/openjdk";
  };

  # JDK 25 (explicit)
  jdk25 = pkgs.mkShell {
    buildInputs = [ pkgs.jdk pkgs.maven ];
    JAVA_HOME = "${pkgs.jdk}/lib/openjdk";
  };
};
```

### Parametric JDK Selection

```nix
# shell.nix
{ pkgs ? import <nixpkgs> {}
, jdkVersion ? "25"
}:

let
  jdk = {
    "17" = pkgs.jdk17;
    "21" = pkgs.jdk21;
    "25" = pkgs.jdk;
  }.${jdkVersion} or pkgs.jdk;  # Default to latest if not found

in pkgs.mkShell {
  buildInputs = [ jdk pkgs.maven ];
  JAVA_HOME = "${jdk}/lib/openjdk";
}
```

## Maven Configuration

### Common Maven Packages

```nix
buildInputs = with pkgs; [
  maven              # Maven build tool
  maven-language-server  # LSP for Maven
];
```

### Maven Wrapper Support

```nix
let
  mvnw = pkgs.writeShellScriptBin "mvnw" ''
    if [ -f ./mvnw ]; then
      ./mvnw "$@"
    else
      ${pkgs.maven}/bin/mvn "$@"
    fi
  '';
in
pkgs.mkShell {
  buildInputs = [ pkgs.jdk17 mvnw ];
}
```

### Maven Settings Template

```nix
shellHook = ''
  # Create Maven settings if not exists
  mkdir -p $HOME/.m2

  if [ ! -f $HOME/.m2/settings.xml ]; then
    cat > $HOME/.m2/settings.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                              http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <localRepository>''${HOME}/.m2/repository</localRepository>
</settings>
EOF
  fi
'';
```

## Security Tools Integration

### PGP and Checksum Tools

```nix
buildInputs = with pkgs; [
  jdk17
  maven

  # Security verification tools
  gnupg            # PGP signature verification
  openssl          # SHA checksum generation
  curl             # Download artifacts
];

shellHook = ''
  # Configure GPG for Maven GPG plugin
  export GPG_TTY=$(tty)

  # Ensure GPG home exists
  mkdir -p $HOME/.gnupg
  chmod 700 $HOME/.gnupg
'';
```

### Security Script Integration

```nix
shellHook = ''
  # Make security scripts executable
  if [ -d scripts ]; then
    chmod +x scripts/*.sh
  fi

  # Initialize artagon-common submodule if needed
  if [ -d .common/artagon-common ] && [ ! -f .common/artagon-common/README.md ]; then
    echo "Initializing artagon-common submodule..."
    git submodule update --init --recursive
  fi
'';
```

## Development Tools

### Java Development Tools

```nix
buildInputs = with pkgs; [
  # Core Java tools
  jdk17
  maven

  # Code formatting
  google-java-format    # Java formatter
  checkstyle           # Java linter

  # Build tools
  gradle               # Alternative to Maven
  ant                  # Legacy build tool

  # Testing
  junit                # Unit testing
];
```

### IDE Support

```nix
buildInputs = with pkgs; [
  # Language servers
  jdt-language-server  # Eclipse JDT LS
  maven-language-server

  # Editors
  jetbrains.idea-community
  vscode
];
```

## Maven Profiles and Properties

### Environment Variables for Maven

```nix
shellHook = ''
  # Maven options
  export MAVEN_OPTS="-Xmx2g -XX:MaxMetaspaceSize=512m"

  # Skip tests for faster builds (override with -DskipTests=false)
  export MAVEN_ARGS="-DskipTests=false"

  # Enable Maven color output
  export MAVEN_COLOR=always
'';
```

### Profile Activation

```nix
shellHook = ''
  # Helper functions for common Maven commands
  mvn-dev() {
    mvn verify
  }

  mvn-security() {
    mvn -P artagon-oss-security verify
  }

  mvn-release() {
    mvn -P artagon-oss-release,artagon-oss-security clean verify
  }

  echo "Available functions:"
  echo "  mvn-dev       - Developer build"
  echo "  mvn-security  - With security checks"
  echo "  mvn-release   - Release build"
'';
```

## Dependency Management

### Maven Repository Cache

```nix
shellHook = ''
  # Use project-local Maven repository for isolation
  export MAVEN_REPO="$PWD/.nix-maven-repo"
  mkdir -p "$MAVEN_REPO"

  # Override in settings
  cat > .nix-maven-settings.xml << EOF
<settings>
  <localRepository>$MAVEN_REPO</localRepository>
</settings>
EOF

  export MAVEN_OPTS="$MAVEN_OPTS -s $PWD/.nix-maven-settings.xml"
'';
```

### Offline Mode

```nix
shellHook = ''
  # Helper for offline builds
  mvn-offline() {
    mvn --offline "$@"
  }

  # Download all dependencies for offline use
  mvn-download-deps() {
    mvn dependency:go-offline
  }
'';
```

## Build Reproducibility

### Fixed Maven Version

```nix
let
  maven-fixed = pkgs.maven.override {
    jdk = pkgs.jdk17;
  };
in
pkgs.mkShell {
  buildInputs = [ maven-fixed ];
}
```

### Locked Dependencies

```nix
# Use mvnix for truly reproducible Maven builds
let
  mvnix = pkgs.callPackage (pkgs.fetchFromGitHub {
    owner = "icetan";
    repo = "mvnix";
    rev = "master";
    sha256 = "...";
  }) {};
in
pkgs.mkShell {
  buildInputs = [ pkgs.jdk17 mvnix ];
}
```

## CI/CD Shell

### Minimal CI Environment

```nix
devShells.ci = pkgs.mkShell {
  name = "artagon-parent-ci";

  buildInputs = with pkgs; [
    jdk17
    maven
    gnupg
    openssl
    git
  ];

  JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";

  # Minimal shellHook for CI
  shellHook = ''
    export MAVEN_OPTS="-Xmx2g"
    mvn --version
    java -version
  '';
};
```

## Docker Integration

### Build Docker Image with Nix

```nix
packages.docker = pkgs.dockerTools.buildImage {
  name = "artagon-parent";
  tag = "latest";

  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = with pkgs; [
      jdk17
      maven
      gnupg
      openssl
      bash
      coreutils
    ];
  };

  config = {
    Cmd = [ "${pkgs.bash}/bin/bash" ];
    Env = [
      "JAVA_HOME=${pkgs.jdk17}/lib/openjdk"
      "PATH=/usr/bin:${pkgs.jdk17}/bin:${pkgs.maven}/bin"
    ];
  };
};
```

## Shell Hook Patterns

### Comprehensive Developer Shell Hook

```nix
shellHook = ''
  echo "☕ Artagon Parent POM Development"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Display versions
  echo "Versions:"
  echo "  Java:  $(java -version 2>&1 | head -n 1)"
  echo "  Maven: $(mvn -version | head -n 1)"
  echo ""

  # Project info
  echo "Project: $(mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout)"
  echo "Version: $(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)"
  echo ""

  # Environment
  echo "Environment:"
  echo "  JAVA_HOME:    $JAVA_HOME"
  echo "  Maven cache:  $HOME/.m2/repository"
  echo "  Security dir: ./security"
  echo ""

  # Common commands
  echo "Build commands:"
  echo "  mvn verify                              # Default build"
  echo "  mvn -P artagon-oss-security verify      # Security checks"
  echo "  mvn -P artagon-oss-release verify       # Release build"
  echo ""

  echo "Security:"
  echo "  ./scripts/security/mvn_update_security.sh -u  # Update baselines"
  echo "  ./scripts/security/mvn_update_security.sh -v  # Verify baselines"
  echo ""

  # Initialize submodules if needed
  if [ -d .common/artagon-common ]; then
    if [ ! -f .common/artagon-common/README.md ]; then
      echo "⚠️  Initializing artagon-common submodule..."
      git submodule update --init --recursive
    fi
  fi
'';
```

## Testing and Verification

### Maven Test Execution

```nix
checks = {
  # Unit tests
  maven-test = pkgs.stdenv.mkDerivation {
    name = "maven-test";
    src = ./.;
    buildInputs = [ pkgs.maven pkgs.jdk17 ];

    buildPhase = ''
      export JAVA_HOME=${pkgs.jdk17}/lib/openjdk
      mvn test
    '';

    installPhase = "touch $out";
  };

  # Security verification
  security-verify = pkgs.stdenv.mkDerivation {
    name = "security-verify";
    src = ./.;
    buildInputs = [ pkgs.maven pkgs.jdk17 pkgs.gnupg pkgs.openssl ];

    buildPhase = ''
      export JAVA_HOME=${pkgs.jdk17}/lib/openjdk
      mvn -P artagon-oss-security verify
    '';

    installPhase = "touch $out";
  };
};
```

## Common Commands

### Development Workflow

```bash
# Enter development shell
nix develop

# Use specific JDK version
nix develop .#jdk21

# Run Maven build in shell
nix develop -c mvn verify

# Run with security profile
nix develop -c mvn -P artagon-oss-security verify

# Update dependencies
nix develop -c ./scripts/security/mvn_update_security.sh -u
```

### CI/CD Workflow

```bash
# Use CI shell
nix develop .#ci

# Run all checks
nix flake check

# Build Docker image
nix build .#docker
```

> **Note:** Template checks are enabled only when your project includes
> supporting files (`pom.xml`, `scripts/security/mvn_update_security.sh`, etc.).
> When you reference the shared template directly (for example via a symlink),
> the checks remain disabled to avoid false failures. Copy the template into
> your repository if you want `nix flake check` to exercise your build.

## Direnv Integration

### .envrc for Maven Projects

```bash
# .envrc
use flake

# Maven configuration
export MAVEN_OPTS="-Xmx2g -XX:MaxMetaspaceSize=512m"
export MAVEN_COLOR=always

# Project paths
export PROJECT_ROOT="$(pwd)"
export SECURITY_DIR="$PROJECT_ROOT/security"

# Make scripts executable
chmod +x scripts/*.sh 2>/dev/null || true

# Load secrets if available
if [ -f .envrc.local ]; then
  source_env .envrc.local
fi
```

## Best Practices for Maven/Java Projects

1. **Pin JDK version**: Specify exact JDK version for reproducibility
2. **Maven wrapper**: Include `mvnw` for version consistency
3. **Offline builds**: Use `dependency:go-offline` for reproducible builds
4. **Security tools**: Include GPG and OpenSSL for artifact verification
5. **Multiple shells**: Provide different shells for dev, CI, different JDK versions
6. **Clear documentation**: Use informative shell hooks
7. **Submodule init**: Auto-initialize git submodules in shell hook
8. **Maven settings**: Generate or configure Maven settings.xml
9. **Cache management**: Be mindful of Maven local repository size
10. **CI optimization**: Use minimal dependencies in CI shells

## Troubleshooting

### Maven Not Finding JDK

```bash
# Verify JAVA_HOME is set
echo $JAVA_HOME

# Manually set if needed
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

# Test
mvn -version
```

### Dependency Download Issues

```bash
# Clear Maven cache
rm -rf ~/.m2/repository

# Rebuild dependency cache
nix develop -c mvn dependency:go-offline
```

### Submodule Not Initialized

```bash
# Initialize in shell
git submodule update --init --recursive

# Or add to shell hook
if [ -d .common/artagon-common ] && [ ! -f .common/artagon-common/README.md ]; then
  git submodule update --init --recursive
fi
```

## Integration with artagon-common Submodule

### Security Scripts Access

```nix
shellHook = ''
  # Ensure artagon-common is available
  if [ ! -f .common/artagon-common/README.md ]; then
    echo "Initializing artagon-common..."
    git submodule update --init --recursive
  fi

  # Make wrapper scripts executable
  chmod +x scripts/*.sh

  # Add common scripts to PATH
  export PATH="$PWD/.common/artagon-common/scripts/security:$PATH"
'';
```

## References

- [Nix Java documentation](https://nixos.wiki/wiki/Java)
- [Maven in Nix](https://nixos.wiki/wiki/Maven)
- [mvnix - Reproducible Maven builds](https://github.com/icetan/mvnix)
- [Nix flakes](https://nixos.wiki/wiki/Flakes)
