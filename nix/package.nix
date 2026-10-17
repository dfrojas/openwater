{ stdenv
, lib
, zig
, zigPkg
, linuxHeaders
}:

stdenv.mkDerivation rec {
  pname = "openwater";
  version = "0.0.0";

  src = ../.;

  nativeBuildInputs = [ zig ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ linuxHeaders ];

  dontConfigure = true;

  preBuild = ''
    export HOME=$TMPDIR
    rm -rf zig-pkg
    ln -s ${zigPkg} zig-pkg
    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      export CPATH="${linuxHeaders}/include''${CPATH:+:$CPATH}"
    ''}
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

  meta = with lib; {
    description = "Read and write dive plans in UDDF format";
    homepage = "https://github.com/dfrojas/openwater";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
