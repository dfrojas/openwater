final: prev: rec {
  devShell = prev.callPackage ./devshell.nix { zig = final.zig; };
  openwater = prev.callPackage ./package.nix { zig = final.zig; };
}
