# Nix Flake Template for Artagon Parent POM
#
# This template provides a reproducible development environment for working
# with the Artagon Parent POM Maven project, including security verification.
#
# Usage:
#   nix develop              # Enter development shell (JDK 25)
#   nix develop .#jdk17      # Use JDK 17
#   nix develop .#jdk21      # Use JDK 21
#   nix develop .#jdk25      # Use JDK 25 (explicit)
#   nix flake check          # Run checks

{
  description = "Artagon Java Project Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Common build inputs for all shells
        commonInputs = with pkgs; [
          # Security tools (for dependency verification)
          gnupg            # PGP signature verification
          openssl          # SHA checksum generation
          curl             # Downloading artifacts

          # Documentation
          pandoc           # Convert documentation

          # Version control
          git
          git-lfs

          # Utilities
          jq               # JSON processing
          yq-go            # YAML processing
        ];

        # Maven wrapper helper
        mvnw = pkgs.writeShellScriptBin "mvnw" ''
          if [ -f ./mvnw ]; then
            ./mvnw "$@"
          else
            ${pkgs.maven}/bin/mvn "$@"
          fi
        '';

      in
      {
        # Multiple development shells for different JDK versions
        devShells = {
          # Default shell with JDK 25
          default = pkgs.mkShell {
            name = "artagon-parent-jdk25";

            buildInputs = with pkgs; [
              jdk              # Java Development Kit (latest - 25)
              maven              # Maven build tool
            ] ++ commonInputs ++ [ mvnw ];

            JAVA_HOME = "${pkgs.jdk}/lib/openjdk";

            shellHook = ''
              echo "☕ Artagon Parent POM Development Environment"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo "Java version: $(java -version 2>&1 | head -n 1)"
              echo "Maven version: $(mvn -version | head -n 1)"
              echo ""
              echo "Available commands:"
              echo "  mvn verify                              # Developer build"
              echo "  mvn -P artagon-oss-security verify      # Security verification"
              echo "  mvn -P artagon-oss-release verify       # Release build"
              echo ""
              echo "Security scripts:"
              echo "  ./scripts/update-dependency-security.sh -u"
              echo "  ./scripts/update-dependency-security.sh -v"
              echo ""
              echo "Environment:"
              echo "  JAVA_HOME=$JAVA_HOME"
              echo "  Maven cache: $HOME/.m2/repository"
              echo ""
              echo "💡 Use 'nix develop .#jdk17' or 'nix develop .#jdk21' for other versions"
              echo ""
            '';
          };

          # JDK 17 shell (explicit)
          jdk17 = pkgs.mkShell {
            name = "artagon-parent-jdk17";

            buildInputs = with pkgs; [
              jdk17
              maven
            ] ++ commonInputs ++ [ mvnw ];

            JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";

            shellHook = ''
              echo "☕ Artagon Parent (JDK 17)"
              java -version
            '';
          };

          # JDK 21 shell for testing
          jdk21 = pkgs.mkShell {
            name = "artagon-parent-jdk21";

            buildInputs = with pkgs; [
              jdk21
              maven
            ] ++ commonInputs ++ [ mvnw ];

            JAVA_HOME = "${pkgs.jdk21}/lib/openjdk";

            shellHook = ''
              echo "☕ Artagon Parent (JDK 21)"
              java -version
            '';
          };

          # JDK 25 shell (explicit)
          jdk25 = pkgs.mkShell {
            name = "artagon-parent-jdk25";

            buildInputs = with pkgs; [
              jdk
              maven
            ] ++ commonInputs ++ [ mvnw ];

            JAVA_HOME = "${pkgs.jdk}/lib/openjdk";

            shellHook = ''
              echo "☕ Artagon Parent (JDK 25)"
              java -version
            '';
          };

          # CI shell - minimal dependencies for continuous integration
          ci = pkgs.mkShell {
            name = "artagon-parent-ci";

            buildInputs = with pkgs; [
              jdk
              maven
              gnupg
              openssl
              git
            ];

            JAVA_HOME = "${pkgs.jdk}/lib/openjdk";

            shellHook = ''
              echo "🤖 CI Environment (JDK 25)"
              echo "Running in minimal CI mode"
            '';
          };
        };

        # Checks
        checks = {
          # Verify Maven project compiles
          maven-compile = pkgs.stdenv.mkDerivation {
            name = "maven-compile-check";
            src = ./.;
            buildInputs = [ pkgs.maven pkgs.jdk ];
            buildPhase = ''
              export JAVA_HOME=${pkgs.jdk}/lib/openjdk
              mvn clean compile -DskipTests
            '';
            installPhase = "touch $out";
          };

          # Verify security scripts are executable
          scripts-executable = pkgs.runCommand "scripts-check" {} ''
            cd ${./.}
            if [ ! -x scripts/update-dependency-security.sh ]; then
              echo "Error: update-dependency-security.sh not executable"
              exit 1
            fi
            touch $out
          '';
        };

        # Formatter
        formatter = pkgs.writeShellScriptBin "format-all" ''
          # Format Java code with google-java-format
          ${pkgs.google-java-format}/bin/google-java-format \
            -i $(find . -name "*.java")

          # Format XML (pom.xml) with xmlformat
          ${pkgs.xmlformat}/bin/xmlformat -i pom.xml

          echo "✓ Formatting complete"
        '';
      }
    );
}
