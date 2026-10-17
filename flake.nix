{
  description = "openwater";

  nixConfig = {
    warn-dirty = false;
  };

  inputs = {
    nixpkgs.follows = "zig/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    zig.url = "github:mitchellh/zig-overlay";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, zig, ... }@inputs:
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
            (import ./nix/overlay.nix)
            (final: prev: {
              zig = zig.packages.${system}."0.17.0";
            })
          ];
        };
      in rec {
        devShells.default = pkgs.devShell;
        devShell = pkgs.devShell;

        packages.openwater = pkgs.openwater;
        packages.default = pkgs.openwater;
        defaultPackage = pkgs.openwater;

        checks.default = pkgs.openwater;
      });
}
