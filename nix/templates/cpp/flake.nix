{
  description = "Artagon C++ Project - Reproducible Build Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # C++ toolchain with C++23 support
        buildInputs = with pkgs; [
          # Compilers
          gcc13               # GCC 13 with C++23
          clang_18           # Clang 18 with C++23

          # Build systems
          cmake              # CMake build system
          ninja              # Fast build tool
          meson              # Alternative build system
          bazel_7            # Bazel build system
          bazelisk           # Bazel version manager

          # Development tools
          gdb                # Debugger
          lldb_18            # LLVM debugger
          valgrind           # Memory profiling
          git
          gh                 # GitHub CLI

          # Code quality and formatting
          clang-tools_18     # clang-format, clang-tidy, include-what-you-use
          cppcheck           # Static analysis

          # Testing frameworks (uncomment as needed)
          # gtest            # Google Test
          # catch2           # Catch2
          # boost            # Boost libraries

          # Documentation
          doxygen            # Documentation generator
          graphviz           # For Doxygen graphs

          # Package management
          pkg-config

          # Common libraries (uncomment as needed)
          # openssl
          # zlib
          # curl
          # sqlite
        ];

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          inherit buildInputs;

          # Environment variables
          CC = "${pkgs.gcc13}/bin/gcc";
          CXX = "${pkgs.gcc13}/bin/g++";

          # C++23 standard
          CXXFLAGS = "-std=c++23";

          # Enable compile_commands.json for LSP/clangd
          CMAKE_EXPORT_COMPILE_COMMANDS = "1";

          shellHook = ''
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "⚡ Artagon C++ Development Environment"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "GCC:    $(g++ --version | head -n 1)"
            echo "Clang:  $(clang++ --version | head -n 1)"
            echo "CMake:  $(cmake --version | head -n 1)"
            echo "Bazel:  $(bazel --version)"
            echo "Standard: C++23"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Build with CMake:"
            echo "  mkdir build && cd build"
            echo "  cmake -GNinja -DCMAKE_BUILD_TYPE=Release .."
            echo "  ninja"
            echo ""
            echo "Build with Bazel:"
            echo "  bazel build //..."
            echo "  bazel test //..."
            echo "  bazel run //:main"
            echo ""
            echo "Code quality:"
            echo "  clang-format -i src/**/*.cpp include/**/*.hpp"
            echo "  clang-tidy src/*.cpp"
            echo "  cppcheck --enable=all --std=c++23 src/"
            echo ""
            echo "Memory checking:"
            echo "  valgrind --leak-check=full ./bazel-bin/main"
            echo ""
          '';
        };

        # Build derivation
        packages.default = pkgs.stdenv.mkDerivation {
          name = "artagon-cpp-project";
          src = ./.;

          nativeBuildInputs = [ pkgs.cmake pkgs.ninja ];
          buildInputs = [ pkgs.gcc13 ];

          buildPhase = ''
            cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=23 .
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
