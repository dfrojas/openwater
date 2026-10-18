#!/usr/bin/env bash
# Verification harness for the openwater CLI. Run from repo root.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$ROOT"

BIN="${OPENWATER_BIN:-$ROOT/zig-out/bin/openwater}"
RUNS_DIR="$ROOT/.verify-openwater/runs"
EVIDENCE_DIR="$ROOT/.verify-openwater/evidence"
FIXTURE_UDDF="$ROOT/fixtures/logbook_v01.uddf"
FIXTURE_DLF="$ROOT/fixtures/freedom_mix2_v2_00000007.dlf"
REQUIRED_ZIG="0.17.0"

usage() {
  echo "usage: $0 doctor | drive <feature-id> | cleanup [--run-id ID]" >&2
  exit 1
}

ensure_build() {
  if [[ ! -x "$BIN" ]]; then
    zig build
  fi
}

cmd_doctor() {
  local zig_ver
  zig_ver="$(zig version)"
  if [[ "$zig_ver" != "$REQUIRED_ZIG" ]]; then
    echo "doctor: FAIL zig version is $zig_ver, need $REQUIRED_ZIG" >&2
    return 1
  fi
  if [[ ! -f "$ROOT/build.zig" ]]; then
    echo "doctor: FAIL not in openwater repo (missing build.zig)" >&2
    return 1
  fi
  if [[ ! -f "$FIXTURE_UDDF" ]]; then
    echo "doctor: FAIL missing fixture $FIXTURE_UDDF" >&2
    return 1
  fi
  if [[ ! -f "$FIXTURE_DLF" ]]; then
    echo "doctor: FAIL missing fixture $FIXTURE_DLF" >&2
    return 1
  fi
  ensure_build
  if [[ ! -x "$BIN" ]]; then
    echo "doctor: FAIL binary missing at $BIN" >&2
    return 1
  fi
  echo "doctor: OK zig=$zig_ver bin=$BIN uddf=$FIXTURE_UDDF dlf=$FIXTURE_DLF"
}

new_run_id() {
  date -u +"%Y%m%dT%H%M%SZ-$$"
}

capture_run() {
  local run_id="$1"
  local run_dir="$RUNS_DIR/$run_id"
  mkdir -p "$run_dir" "$EVIDENCE_DIR/$run_id"
  echo "$run_id"
}

write_transcript() {
  local path="$1"
  local exit_code="$2"
  local stdout_file="$3"
  local stderr_file="$4"
  {
    echo "exit_code=$exit_code"
    echo "--- stdout ---"
    cat "$stdout_file"
    echo "--- stderr ---"
    cat "$stderr_file"
  } >"$path"
}

drive_uddf_to_json() {
  local run_id
  run_id="$(capture_run "$(new_run_id)")"
  local run_dir="$RUNS_DIR/$run_id"
  local ev="$EVIDENCE_DIR/$run_id"
  local input="$run_dir/plan.uddf.xml"
  local output="$run_dir/dive.json"
  cp "$FIXTURE_UDDF" "$input"

  local stdout="$run_dir/stdout.txt"
  local stderr="$run_dir/stderr.txt"
  set +e
  "$BIN" --input "$input" --output "$output" >"$stdout" 2>"$stderr"
  local code=$?
  set -e

  write_transcript "$ev/transcript.txt" "$code" "$stdout" "$stderr"
  cp "$output" "$ev/dive.json" 2>/dev/null || true

  if [[ "$code" -ne 0 ]]; then
    echo "drive uddf-to-json: FAIL exit $code (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi
  if ! grep -q '"schema": "dive_json_v1"' "$output"; then
    echo "drive uddf-to-json: FAIL missing schema marker (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi
  if ! grep -q '"name": "OpenWater spike"' "$output"; then
    echo "drive uddf-to-json: FAIL missing generator name (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi

  echo "drive uddf-to-json: OK run_id=$run_id evidence=$ev"
  echo "$run_id" >"$run_dir/RUN_ID"
}

drive_cli_usage() {
  local run_id
  run_id="$(capture_run "$(new_run_id)")"
  local run_dir="$RUNS_DIR/$run_id"
  local ev="$EVIDENCE_DIR/$run_id"
  local stdout="$run_dir/stdout.txt"
  local stderr="$run_dir/stderr.txt"

  set +e
  "$BIN" >"$stdout" 2>"$stderr"
  local code=$?
  set -e

  write_transcript "$ev/transcript.txt" "$code" "$stdout" "$stderr"

  if [[ "$code" -ne 1 ]]; then
    echo "drive cli-usage: FAIL expected exit 1, got $code (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi
  if ! grep -q 'usage: openwater --input' "$stderr"; then
    echo "drive cli-usage: FAIL missing usage line on stderr (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi

  echo "drive cli-usage: OK run_id=$run_id evidence=$ev"
  echo "$run_id" >"$run_dir/RUN_ID"
}

drive_unsupported_extension() {
  local run_id
  run_id="$(capture_run "$(new_run_id)")"
  local run_dir="$RUNS_DIR/$run_id"
  local ev="$EVIDENCE_DIR/$run_id"
  local input="$run_dir/plan.uddf"
  local output="$run_dir/out.dlf"
  cp "$FIXTURE_UDDF" "$input"
  local stdout="$run_dir/stdout.txt"
  local stderr="$run_dir/stderr.txt"

  set +e
  "$BIN" --input "$input" --output "$output" >"$stdout" 2>"$stderr"
  local code=$?
  set -e

  write_transcript "$ev/transcript.txt" "$code" "$stdout" "$stderr"

  if [[ "$code" -ne 1 ]]; then
    echo "drive unsupported-extension: FAIL expected exit 1, got $code (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi
  if ! grep -q 'error: UnsupportedFormat' "$stderr"; then
    echo "drive unsupported-extension: FAIL missing UnsupportedFormat on stderr (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi
  if [[ -f "$output" ]]; then
    echo "drive unsupported-extension: FAIL output file was created (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi

  echo "drive unsupported-extension: OK run_id=$run_id evidence=$ev"
  echo "$run_id" >"$run_dir/RUN_ID"
}

drive_vendor_dump_to_uddf() {
  local run_id
  run_id="$(capture_run "$(new_run_id)")"
  local run_dir="$RUNS_DIR/$run_id"
  local ev="$EVIDENCE_DIR/$run_id"
  local input="$run_dir/dive.dlf"
  local output="$run_dir/freedom.uddf"
  cp "$FIXTURE_DLF" "$input"

  local stdout="$run_dir/stdout.txt"
  local stderr="$run_dir/stderr.txt"
  set +e
  "$BIN" --input "$input" --output "$output" --family freedom >"$stdout" 2>"$stderr"
  local code=$?
  set -e

  write_transcript "$ev/transcript.txt" "$code" "$stdout" "$stderr"
  cp "$output" "$ev/freedom.uddf" 2>/dev/null || true

  if [[ "$code" -ne 0 ]]; then
    echo "drive vendor-dump-to-uddf: FAIL exit $code (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi
  if ! grep -q '<uddf version="3.2.3">' "$output"; then
    echo "drive vendor-dump-to-uddf: FAIL missing uddf version (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi
  if ! grep -q '<greatestdepth>18.98</greatestdepth>' "$output"; then
    echo "drive vendor-dump-to-uddf: FAIL missing greatest depth (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi

  echo "drive vendor-dump-to-uddf: OK run_id=$run_id evidence=$ev"
  echo "$run_id" >"$run_dir/RUN_ID"
}

drive_vendor_dump_to_json() {
  local run_id
  run_id="$(capture_run "$(new_run_id)")"
  local run_dir="$RUNS_DIR/$run_id"
  local ev="$EVIDENCE_DIR/$run_id"
  local input="$run_dir/dive.dlf"
  local output="$run_dir/freedom.json"
  cp "$FIXTURE_DLF" "$input"

  local stdout="$run_dir/stdout.txt"
  local stderr="$run_dir/stderr.txt"
  set +e
  "$BIN" --input "$input" --output "$output" --family freedom >"$stdout" 2>"$stderr"
  local code=$?
  set -e

  write_transcript "$ev/transcript.txt" "$code" "$stdout" "$stderr"
  cp "$output" "$ev/freedom.json" 2>/dev/null || true

  if [[ "$code" -ne 0 ]]; then
    echo "drive vendor-dump-to-json: FAIL exit $code (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi
  if ! grep -q '"schema": "dive_json_v1"' "$output"; then
    echo "drive vendor-dump-to-json: FAIL missing schema marker (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi

  echo "drive vendor-dump-to-json: OK run_id=$run_id evidence=$ev"
  echo "$run_id" >"$run_dir/RUN_ID"
}

drive_vendor_dump_missing_family() {
  local run_id
  run_id="$(capture_run "$(new_run_id)")"
  local run_dir="$RUNS_DIR/$run_id"
  local ev="$EVIDENCE_DIR/$run_id"
  local input="$run_dir/dive.dlf"
  local output="$run_dir/out.uddf"
  cp "$FIXTURE_DLF" "$input"

  local stdout="$run_dir/stdout.txt"
  local stderr="$run_dir/stderr.txt"
  set +e
  "$BIN" --input "$input" --output "$output" >"$stdout" 2>"$stderr"
  local code=$?
  set -e

  write_transcript "$ev/transcript.txt" "$code" "$stdout" "$stderr"

  if [[ "$code" -ne 1 ]]; then
    echo "drive vendor-dump-missing-family: FAIL expected exit 1, got $code (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi
  if ! grep -q 'usage: openwater --input' "$stderr"; then
    echo "drive vendor-dump-missing-family: FAIL missing usage on stderr (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi
  if [[ -f "$output" ]]; then
    echo "drive vendor-dump-missing-family: FAIL output file was created (evidence $ev)" >&2
    echo "$run_id" >"$run_dir/RUN_ID"
    return 1
  fi

  echo "drive vendor-dump-missing-family: OK run_id=$run_id evidence=$ev"
  echo "$run_id" >"$run_dir/RUN_ID"
}

cmd_drive() {
  local feature="${1:-}"
  ensure_build
  case "$feature" in
    uddf-to-json) drive_uddf_to_json ;;
    vendor-dump-to-uddf) drive_vendor_dump_to_uddf ;;
    vendor-dump-to-json) drive_vendor_dump_to_json ;;
    vendor-dump-missing-family) drive_vendor_dump_missing_family ;;
    cli-usage) drive_cli_usage ;;
    unsupported-extension) drive_unsupported_extension ;;
    *)
      echo "drive: unknown feature-id '$feature'" >&2
      echo "known: uddf-to-json vendor-dump-to-uddf vendor-dump-to-json vendor-dump-missing-family cli-usage unsupported-extension" >&2
      return 1
      ;;
  esac
}

cmd_cleanup() {
  local run_id="${1:-}"
  if [[ -n "$run_id" ]]; then
    rm -rf "$RUNS_DIR/$run_id"
    echo "cleanup: removed run scratch $RUNS_DIR/$run_id (evidence kept under $EVIDENCE_DIR/$run_id)"
    return 0
  fi
  if [[ -d "$RUNS_DIR" ]]; then
    rm -rf "$RUNS_DIR"
    echo "cleanup: removed all run scratch under $RUNS_DIR (evidence kept under $EVIDENCE_DIR)"
  else
    echo "cleanup: nothing to do"
  fi
}

main() {
  local cmd="${1:-}"
  shift || true
  case "$cmd" in
    doctor) cmd_doctor ;;
    drive) cmd_drive "${1:-}" ;;
    cleanup)
      if [[ "${1:-}" == "--run-id" ]]; then
        cmd_cleanup "${2:-}"
      else
        cmd_cleanup ""
      fi
      ;;
    *) usage ;;
  esac
}

main "$@"
