# Cross-compile matrix

Builds all four CI `build` job targets via `zig build -Dtarget=…` in the dev shell.

## Sub-features

- `x86-linux-gnu`
- `x86_64-linux-gnu`
- `aarch64-macos`
- `x86_64-windows-gnu` (libdivecomputer Windows compile path)

## How to get to it (user POV)

CI `build` job after `test` succeeds; each matrix cell is one target flag.

## Driving it with Lima harness

Preconditions: `doctor` OK; `test` job drives should pass first for fastest feedback.

```sh
.agents/skills/verify-ci/scripts/verify.sh drive cross-compile-matrix
```

Observable proof: exit `0`; transcript contains `=== <target> ===` for each of the four targets.

## Gotchas

- Slowest drive; Windows gnu target was a past CI failure mode — keep transcript on failure.
- Matrix runs on `ubuntu-latest` in CI; Lima guest is Linux, matching that runner OS.
