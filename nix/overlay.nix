final: prev:
let
  inherit (final) zig xmlreadSrc libdivecomputerSrc;
  zigPkg = prev.callPackage ./zig-pkg.nix {
    inherit xmlreadSrc libdivecomputerSrc;
  };
in rec {
  inherit zigPkg;
  devShell = prev.callPackage ./devshell.nix { inherit zig; };
  openwater = prev.callPackage ./package.nix { inherit zig zigPkg; };
}
