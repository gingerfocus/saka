{
  description = "Rust environment for fish game";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    utils,
  }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      packages = with pkgs; [
        yacc
        libxcrypt
      ];

      version = "0.0.1";
    in {
      # Build the package
      packages = rec {
        default = pkgs.stdenv.mkDerivation {
          pname = "saka";
          version = "0.0.1";
          src = ./.;

          buildInputs = packages;
          buildPhase = "${pkgs.zig}/bin/zig build --prefix $out --cache-dir /build/zig-cache --global-cache-dir /build/global-cache";
          # installPhase = ''
          #   mkdir -p $out/bin
          #   cp doas $out/bin
          # '';

          meta = {
            maintainers = ["Evan Stokdyk <evan.stokdyk@gmail.com>"];
            description = "Tree Sitter Pre-Processor for Shards";
          };

          # Hack to get nix develop to work correct
          # LD_LIBRARY_PATH = nixpkgs.lib.makeLibraryPath packages;
        };
      };
    });
}
