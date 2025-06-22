{
  inputs.nixpkgs.url = "nixpkgs-unstable";

  outputs = { self, nixpkgs }: let
    lib = nixpkgs.lib;
    systems = [ "aarch64-linux" "x86_64-linux" ];
    eachSystem = f: lib.foldAttrs lib.mergeAttrs { } (map (s: lib.mapAttrs (_: v: { ${s} = v; }) (f s)) systems);
  in
    eachSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      packages = rec {
        default = pkgs.stdenv.mkDerivation {
          pname = "saka";
          version = "0.0.1";

          src = ./.;

          nativeBuildInputs = with pkgs; [ zig.hook ];
          buildInputs = with pkgs; [ openpam libxcrypt libbsd ];

          meta = {
            maintainers = ["Evan Stokdyk <evan.stokdyk@gmail.com>"];
            description = "Simple Configurable User Authenticator";
          };
        };
      };
    });
}
