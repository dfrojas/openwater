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
      # Sandbox has no /lib64/ld-linux. Point Zig at Nix glibc or test spawn returns FileNotFound.
      cat > "$TMPDIR/libc.txt" <<EOF
      include_dir=${lib.getDev stdenv.cc.libc}/include
      sys_include_dir=${lib.getDev stdenv.cc.libc}/include
      crt_dir=${lib.getLib stdenv.cc.libc}/lib
      msvc_lib_dir=
      kernel_include_dir=${linuxHeaders}/include
      gcc_dir=${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.config}/${stdenv.cc.cc.version}
      EOF
    ''}
  '';

  checkPhase = ''
    runHook preCheck
    zig fmt --check build.zig build.zig.zon src
    zig build test ${lib.optionalString stdenv.hostPlatform.isLinux "--libc $TMPDIR/libc.txt"}
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    zig build --prefix $out install ${lib.optionalString stdenv.hostPlatform.isLinux "--libc $TMPDIR/libc.txt"}
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
