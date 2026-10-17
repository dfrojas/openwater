{ stdenv
, lib
, zig
}:

stdenv.mkDerivation rec {
  pname = "openwater";
  version = "0.0.0";

  src = ../.;

  nativeBuildInputs = [ zig ];

  dontConfigure = true;

  preBuild = ''
    export HOME=$TMPDIR
  '';

  checkPhase = ''
    runHook preCheck
    zig fmt --check build.zig build.zig.zon src
    zig build test
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    zig build --prefix $out install
    runHook postInstall
  '';

  doCheck = true;

  # Zig fetches build.zig.zon dependencies; needs network outside the fixed-output sandbox.
  __noSandbox = true;

  meta = with lib; {
    description = "Read and write dive plans in UDDF format";
    homepage = "https://github.com/dfrojas/openwater";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
