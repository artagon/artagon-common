{
  description = "Artagon C Project - Reproducible Build Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # C toolchain
        buildInputs = with pkgs; [
          # Compiler and build tools
          gcc13               # GCC 13
          clang_18           # Clang 18 (alternative compiler)
          cmake              # Build system
          gnumake            # GNU Make
          ninja              # Fast build tool
          bazel_7            # Bazel build system
          bazelisk           # Bazel version manager

          # Development tools
          gdb                # Debugger
          valgrind           # Memory profiling
          git
          gh                 # GitHub CLI

          # Code quality
          clang-tools_18     # clang-format, clang-tidy, etc.
          cppcheck           # Static analysis

          # Documentation
          doxygen            # Documentation generator

          # Libraries (add as needed)
          # pkg-config
          # openssl
          # zlib
        ];

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          inherit buildInputs;

          # Environment variables
          CC = "${pkgs.gcc13}/bin/gcc";
          CXX = "${pkgs.gcc13}/bin/g++";

          # Enable compile_commands.json for LSP
          CMAKE_EXPORT_COMPILE_COMMANDS = "1";

          shellHook = ''
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🔧 Artagon C Development Environment"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "GCC:    $(gcc --version | head -n 1)"
            echo "Clang:  $(clang --version | head -n 1)"
            echo "CMake:  $(cmake --version | head -n 1)"
            echo "Bazel:  $(bazel --version)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Build with CMake:"
            echo "  mkdir build && cd build"
            echo "  cmake .."
            echo "  make"
            echo ""
            echo "Build with Bazel:"
            echo "  bazel build //..."
            echo "  bazel test //..."
            echo "  bazel run //:main"
            echo ""
            echo "Code quality:"
            echo "  clang-format -i **/*.c **/*.h"
            echo "  clang-tidy src/*.c"
            echo "  cppcheck --enable=all src/"
            echo ""
          '';
        };

        # Build derivation
        packages.default = pkgs.stdenv.mkDerivation {
          name = "artagon-c-project";
          src = ./.;

          nativeBuildInputs = [ pkgs.cmake pkgs.ninja ];
          buildInputs = [ pkgs.gcc13 ];

          buildPhase = ''
            cmake -GNinja -DCMAKE_BUILD_TYPE=Release .
            ninja
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp ./bin/* $out/bin/ || true
          '';
        };
      }
    );
}
