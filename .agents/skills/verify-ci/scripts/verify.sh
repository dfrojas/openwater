#!/usr/bin/env bash
# CI verification via Lima (Linux guest). Run from repo root.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$ROOT"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIMA_YAML="${OPENWATER_LIMA_YAML:-$SCRIPT_DIR/openwater.yaml}"
LIMA_INSTANCE="${OPENWATER_LIMA_INSTANCE:-openwater}"
RUNS_DIR="$ROOT/.verify-ci/runs"
EVIDENCE_DIR="$ROOT/.verify-ci/evidence"

CROSS_TARGETS=(
  x86-linux-gnu
  x86_64-linux-gnu
  aarch64-macos
  x86_64-windows-gnu
)

usage() {
  echo "usage: $0 launch | doctor | drive <feature-id> | cleanup [--run-id ID]" >&2
  exit 1
}

lima_status() {
  limactl list "$LIMA_INSTANCE" --format '{{.Status}}' 2>/dev/null || echo "Missing"
}

guest_bash() {
  local cmd="$1"
  limactl shell "$LIMA_INSTANCE" -- bash -lc "$cmd"
}

cmd_launch() {
  if ! command -v limactl >/dev/null 2>&1; then
    echo "launch: FAIL limactl not on PATH" >&2
    return 1
  fi
  if [[ ! -f "$LIMA_YAML" ]]; then
    echo "launch: FAIL missing $LIMA_YAML" >&2
    return 1
  fi
  local st
  st="$(lima_status)"
  if [[ "$st" == "Running" ]]; then
    echo "launch: OK instance=$LIMA_INSTANCE already running"
    return 0
  fi
  limactl start --name="$LIMA_INSTANCE" "$LIMA_YAML"
  echo "launch: OK instance=$LIMA_INSTANCE yaml=$LIMA_YAML"
}

cmd_doctor() {
  if ! command -v limactl >/dev/null 2>&1; then
    echo "doctor: FAIL limactl not on PATH (install Lima 2.x)" >&2
    return 1
  fi
  if [[ ! -f "$ROOT/flake.nix" ]]; then
    echo "doctor: FAIL not in openwater repo (missing flake.nix)" >&2
    return 1
  fi
  if [[ ! -f "$LIMA_YAML" ]]; then
    echo "doctor: FAIL missing Lima config $LIMA_YAML" >&2
    return 1
  fi
  local st
  st="$(lima_status)"
  if [[ "$st" != "Running" ]]; then
    echo "doctor: FAIL Lima instance '$LIMA_INSTANCE' status=$st (run: $0 launch)" >&2
    return 1
  fi
  guest_bash "test -d '$ROOT' && test -f '$ROOT/flake.nix'" || {
    echo "doctor: FAIL repo not visible in guest at $ROOT" >&2
    return 1
  }
  guest_bash "cd '$ROOT' && nix config show sandbox | grep -Eq '^(sandbox = )?true$'" || {
    echo "doctor: FAIL Nix sandbox is not true in guest" >&2
    return 1
  }
  echo "doctor: OK instance=$LIMA_INSTANCE repo=$ROOT sandbox=true"
}

new_run_id() {
  date -u +"%Y%m%dT%H%M%SZ-$$"
}

capture_run() {
  local run_id="$1"
  mkdir -p "$RUNS_DIR/$run_id" "$EVIDENCE_DIR/$run_id"
  echo "$run_id"
}

write_transcript() {
  local path="$1"
  local exit_code="$2"
  local stdout_file="$3"
  local stderr_file="$4"
  {
    echo "exit_code=$exit_code"
    echo "lima_instance=$LIMA_INSTANCE"
    echo "repo=$ROOT"
    echo "--- stdout ---"
    cat "$stdout_file"
    echo "--- stderr ---"
    cat "$stderr_file"
  } >"$path"
}

run_in_guest() {
  local run_dir="$1"
  local ev="$2"
  local label="$3"
  local guest_cmd="$4"

  local stdout="$run_dir/stdout.txt"
  local stderr="$run_dir/stderr.txt"
  set +e
  guest_bash "cd '$ROOT' && $guest_cmd" >"$stdout" 2>"$stderr"
  local code=$?
  set -e
  write_transcript "$ev/transcript.txt" "$code" "$stdout" "$stderr"
  if [[ "$code" -ne 0 ]]; then
    echo "drive $label: FAIL exit $code (evidence $ev)" >&2
    return 1
  fi
  echo "drive $label: OK run_id=$(basename "$run_dir") evidence=$ev"
}

drive_nix_flake_check() {
  local run_id
  run_id="$(capture_run "$(new_run_id)")"
  local run_dir="$RUNS_DIR/$run_id"
  local ev="$EVIDENCE_DIR/$run_id"
  run_in_guest "$run_dir" "$ev" "nix-flake-check" \
    "nix flake check --accept-flake-config"
}

drive_zig_fmt_check() {
  local run_id
  run_id="$(capture_run "$(new_run_id)")"
  local run_dir="$RUNS_DIR/$run_id"
  local ev="$EVIDENCE_DIR/$run_id"
  run_in_guest "$run_dir" "$ev" "zig-fmt-check" \
    "nix develop --accept-flake-config -c zig fmt --check build.zig build.zig.zon src"
}

drive_zig_unit_test() {
  local run_id
  run_id="$(capture_run "$(new_run_id)")"
  local run_dir="$RUNS_DIR/$run_id"
  local ev="$EVIDENCE_DIR/$run_id"
  run_in_guest "$run_dir" "$ev" "zig-unit-test" \
    "nix develop --accept-flake-config -c zig build test"
}

drive_cross_compile_matrix() {
  local run_id
  run_id="$(capture_run "$(new_run_id)")"
  local run_dir="$RUNS_DIR/$run_id"
  local ev="$EVIDENCE_DIR/$run_id"
  local stdout="$run_dir/stdout.txt"
  local stderr="$run_dir/stderr.txt"
  local guest_cmd="cd '$ROOT' && set -e"
  for t in "${CROSS_TARGETS[@]}"; do
    guest_cmd+=" && echo '=== $t ===' && nix develop --accept-flake-config -c zig build -Dtarget=$t"
  done
  set +e
  guest_bash "$guest_cmd" >"$stdout" 2>"$stderr"
  local code=$?
  set -e
  write_transcript "$ev/transcript.txt" "$code" "$stdout" "$stderr"
  if [[ "$code" -ne 0 ]]; then
    echo "drive cross-compile-matrix: FAIL exit $code (evidence $ev)" >&2
    return 1
  fi
  for t in "${CROSS_TARGETS[@]}"; do
    if ! grep -q "=== $t ===" "$stdout"; then
      echo "drive cross-compile-matrix: FAIL missing target $t in output (evidence $ev)" >&2
      return 1
    fi
  done
  echo "drive cross-compile-matrix: OK run_id=$run_id evidence=$ev"
}

cmd_drive() {
  local feature="${1:-}"
  cmd_doctor || return 1
  case "$feature" in
    nix-flake-check) drive_nix_flake_check ;;
    zig-fmt-check) drive_zig_fmt_check ;;
    zig-unit-test) drive_zig_unit_test ;;
    cross-compile-matrix) drive_cross_compile_matrix ;;
    *)
      echo "drive: unknown feature-id '$feature'" >&2
      echo "known: nix-flake-check zig-fmt-check zig-unit-test cross-compile-matrix" >&2
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
    launch) cmd_launch ;;
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
