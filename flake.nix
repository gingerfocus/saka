{
  description = "Rust environment for fish game";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    zig-pkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    zig-pkgs
  }: let
    lib = nixpkgs.lib;
    systems = [ "aarch64-linux" "x86_64-linux" ];
    eachSystem = f: lib.foldAttrs lib.mergeAttrs { } (map (s: lib.mapAttrs (_: v: { ${s} = v; }) (f s)) systems);
  in
    eachSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      # zig = (import zig-pkgs {inherit system;}).zig;
      zig = pkgs.zig;
    in {
      # Build the package
      packages = rec {
        default = pkgs.stdenv.mkDerivation {
          pname = "saka";
          version = "0.0.1";

          src = ./.;

          nativeBuildInputs = [ zig ];

          buildInputs = with pkgs; [
            # openpam
            # shadow
            libxcrypt
            libbsd
          ];

          buildPhase = "${zig}/bin/zig build --prefix $out --cache-dir /build/zig-cache --global-cache-dir /build/global-cache";
          installPhase = ''
            # chown root:root $out/bin/saka
            # sudo chmod u+s $out/bin/saka
            # chmod 4755 $out/bin/saka
          '';

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
