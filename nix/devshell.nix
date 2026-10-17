{ mkShell, zig }:

mkShell rec {
  name = "openwater";
  nativeBuildInputs = [ zig ];
}
