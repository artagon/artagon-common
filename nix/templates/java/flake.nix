{
  description = "Artagon Java Project - Reproducible Build Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # JDK 25 from unstable channel
        jdk = pkgs.jdk25;

        # Maven with specific version
        maven = pkgs.maven;

        # Build tools and utilities
        buildInputs = with pkgs; [
          jdk
          maven
          git
          gh              # GitHub CLI
          gnupg           # GPG for artifact signing

          # Optional: helpful development tools
          jq              # JSON processing
          yq              # YAML processing

          # Code quality tools
          # checkstyle    # Uncomment if needed
          # spotbugs      # Uncomment if needed
        ];

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          inherit buildInputs;

          # Environment variables
          JAVA_HOME = "${jdk}";
          MAVEN_OPTS = "-Xmx2g -XX:+UseG1GC";

          # GitHub Packages authentication (from environment)
          GITHUB_USERNAME = builtins.getEnv "GITHUB_USERNAME";
          GITHUB_TOKEN = builtins.getEnv "GITHUB_TOKEN";

          # OSSRH credentials (from environment)
          OSSRH_USERNAME = builtins.getEnv "OSSRH_USERNAME";
          OSSRH_PASSWORD = builtins.getEnv "OSSRH_PASSWORD";

          # GPG configuration (from environment)
          GPG_PASSPHRASE = builtins.getEnv "GPG_PASSPHRASE";
          GPG_KEYNAME = builtins.getEnv "GPG_KEYNAME";

          shellHook = ''
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🚀 Artagon Java Development Environment"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Java:  $(java -version 2>&1 | head -n 1)"
            echo "Maven: $(mvn --version | head -n 1)"
            echo "JAVA_HOME: $JAVA_HOME"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Quick commands:"
            echo "  mvn clean install      # Build project"
            echo "  mvn test              # Run tests"
            echo "  mvn clean deploy      # Deploy to repository"
            echo ""

            # Warn if credentials not set
            if [ -z "$GITHUB_TOKEN" ]; then
              echo "⚠️  GITHUB_TOKEN not set - set for GitHub Packages access"
            fi
          '';
        };

        # Build derivation (for CI/CD)
        packages.default = pkgs.stdenv.mkDerivation {
          name = "artagon-java-project";
          src = ./.;

          buildInputs = [ jdk maven ];

          buildPhase = ''
            export JAVA_HOME=${jdk}
            mvn clean package -DskipTests
          '';

          installPhase = ''
            mkdir -p $out
            cp -r target/* $out/
          '';
        };
      }
    );
}
