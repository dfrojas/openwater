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
      # The libc file supplies headers and crt objects. -Ddynamic-linker supplies the Nix interpreter. Without it, the sandbox has no /lib64/ld-linux and Zig reports FileNotFound.
      cat > "$TMPDIR/libc.txt" <<EOF
      include_dir=${lib.getDev stdenv.cc.libc}/include
      sys_include_dir=${lib.getDev stdenv.cc.libc}/include
      cc_dir=${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.config}/${stdenv.cc.cc.version}
      crt_dir=${lib.getLib stdenv.cc.libc}/lib
      msvc_lib_dir=
      kernel32_lib_dir=
      darwin_sdk_dir=
      EOF
    ''}
  '';

  checkPhase = ''
    runHook preCheck
    zig fmt --check build.zig build.zig.zon src
    zig build test ${lib.optionalString stdenv.hostPlatform.isLinux "--libc $TMPDIR/libc.txt -Ddynamic-linker=${stdenv.cc.bintools.dynamicLinker}"}
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    zig build --prefix $out install ${lib.optionalString stdenv.hostPlatform.isLinux "--libc $TMPDIR/libc.txt -Ddynamic-linker=${stdenv.cc.bintools.dynamicLinker}"}
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
