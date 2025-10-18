{
  description = "Artagon Rust Project - Reproducible Build Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        # Rust toolchain (stable, nightly, or specific version)
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
          targets = [ "x86_64-unknown-linux-gnu" "wasm32-unknown-unknown" ];
        };

        # Alternative: specific Rust version
        # rustToolchain = pkgs.rust-bin.stable."1.75.0".default;

        # Alternative: nightly
        # rustToolchain = pkgs.rust-bin.nightly.latest.default;

        buildInputs = with pkgs; [
          # Rust toolchain
          rustToolchain

          # Build tools
          cargo-watch        # Auto-rebuild on file changes
          cargo-edit         # cargo add/rm/upgrade commands
          cargo-outdated     # Check for outdated dependencies
          cargo-audit        # Security vulnerability scanning
          cargo-deny         # Linting for dependencies
          cargo-expand       # Expand macros
          cargo-flamegraph   # Profiling

          # Development tools
          git
          gh                 # GitHub CLI

          # Additional tools (uncomment as needed)
          # cargo-criterion  # Benchmarking
          # cargo-fuzz       # Fuzzing
          # mold             # Fast linker

          # System dependencies (add as needed for crates)
          pkg-config
          openssl
          # sqlite
          # postgresql
        ];

        # Rust library path for linking
        libPath = pkgs.lib.makeLibraryPath [
          pkgs.openssl
          pkgs.stdenv.cc.cc
        ];

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          inherit buildInputs;

          # Environment variables
          RUST_BACKTRACE = "1";
          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
          LD_LIBRARY_PATH = libPath;

          # Cargo configuration
          CARGO_HOME = "${toString ./.}/.cargo";

          shellHook = ''
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🦀 Artagon Rust Development Environment"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Rust:   $(rustc --version)"
            echo "Cargo:  $(cargo --version)"
            echo "Clippy: $(cargo clippy --version)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Quick commands:"
            echo "  cargo build              # Build project"
            echo "  cargo build --release    # Release build"
            echo "  cargo test               # Run tests"
            echo "  cargo run                # Run binary"
            echo ""
            echo "Development:"
            echo "  cargo watch -x check     # Auto-check on changes"
            echo "  cargo watch -x test      # Auto-test on changes"
            echo "  cargo watch -x run       # Auto-run on changes"
            echo ""
            echo "Code quality:"
            echo "  cargo clippy             # Linting"
            echo "  cargo fmt                # Format code"
            echo "  cargo audit              # Security audit"
            echo "  cargo outdated           # Check dependencies"
            echo ""
            echo "Documentation:"
            echo "  cargo doc --open         # Build and open docs"
            echo ""
          '';
        };

        # Build derivation
        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "artagon-rust-project";
          version = "0.1.0";
          src = ./.;

          # Cargo.lock hash - update after dependencies change
          # Run `nix build` and it will tell you the correct hash
          cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

          # Optional: additional build inputs
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl ];
        };
      }
    );
}
