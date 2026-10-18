# Zig unit tests

Runs `zig build test` inside the Nix dev shell (CI `test` step).

## Sub-features

- Exercises libdivecomputer linkage and UDDF/JSON paths in-process
- Uses Nix sandbox like GitHub Actions

## How to get to it (user POV)

Third step of the CI `test` job after fmt.

## Driving it with Lima harness

Preconditions: `doctor` OK.

```sh
.agents/skills/verify-ci/scripts/verify.sh drive zig-unit-test
```

Observable proof: exit `0`; test summary on stdout.

## Gotchas

- Longer than flake check; run after fmt passes.
- Host `zig build test` without Nix sandbox is a weaker signal than this drive.
