{
  description = "openwater";

  nixConfig = {
    warn-dirty = false;
  };

  inputs = {
    nixpkgs.follows = "zig/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    zig.url = "github:mitchellh/zig-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, zig, ... }:
    let
      inherit (nixpkgs) lib;

      systems = lib.filter (system:
        zig.packages ? ${system} && zig.packages.${system} ? "0.17.0"
      ) lib.systems.flakeExposed;
    in
    flake-utils.lib.eachSystem systems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              zig = zig.packages.${system}."0.17.0";
            })
          ];
        };
      in {
        devShells.default = pkgs.callPackage ./nix/devshell.nix { inherit (pkgs) zig; };
      });
}
