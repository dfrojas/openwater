{ lib
, runCommand
, xmlreadSrc
, libdivecomputerSrc
}:

runCommand "openwater-zig-pkg" { } ''
  pkg=$out
  mkdir -p "$pkg/xmlread-0.2.0-Ha9x8T_hAQBf-Rnje0_qsLCQBFzzJdB21YEB3-WPFY5-"
  cp -r ${xmlreadSrc}/. "$pkg/xmlread-0.2.0-Ha9x8T_hAQBf-Rnje0_qsLCQBFzzJdB21YEB3-WPFY5-/"
  mkdir -p "$pkg/N-V-__8AAIdAPQD2vH57gKwM7XCcZ70azBTp75nCZzf20Ed_"
  cp -r ${libdivecomputerSrc}/. "$pkg/N-V-__8AAIdAPQD2vH57gKwM7XCcZ70azBTp75nCZzf20Ed_/"
''
