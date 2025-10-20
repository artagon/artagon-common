# Nix Shell Template for Artagon Parent POM (legacy)
#
# This is a traditional shell.nix for compatibility with older Nix versions.
# For modern Nix with flakes support, use flake.nix instead.
#
# Usage:
#   nix-shell                    # JDK 25 (default)
#   nix-shell --argstr jdk 17    # JDK 17
#   nix-shell --argstr jdk 21    # JDK 21
#   nix-shell --argstr jdk 25    # JDK 25 (explicit)

{ pkgs ? import <nixpkgs> {}
, jdk ? "25"
}:

let
  # Select JDK version
  javaPackage = if jdk == "25" then pkgs.jdk
                else if jdk == "21" then pkgs.jdk21
                else if jdk == "17" then pkgs.jdk17
                else pkgs.jdk;

in pkgs.mkShell {
  name = "artagon-parent-shell";

  buildInputs = with pkgs; [
    # Java and Maven
    javaPackage
    maven

    # Security tools
    gnupg
    openssl

    # Documentation
    pandoc

    # Version control
    git
    git-lfs

    # Utilities
    curl
    jq
    yq-go
  ];

  JAVA_HOME = "${javaPackage}/lib/openjdk";

  shellHook = ''
    echo "☕ Artagon Parent POM Development Shell"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Java: $(java -version 2>&1 | head -n 1)"
    echo "Maven: $(mvn -version | head -n 1)"
    echo ""
    echo "Build commands:"
    echo "  mvn verify                              # Default build"
    echo "  mvn -P artagon-oss-security verify      # With security checks"
    echo "  mvn -P artagon-oss-release verify       # Release build"
    echo ""
    echo "Security baseline:"
    echo "  ./scripts/update-dependency-security.sh -u"
    echo "  ./scripts/update-dependency-security.sh -v"
    echo ""
    echo "JAVA_HOME=$JAVA_HOME"
    echo ""
  '';
}
