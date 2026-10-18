# Zig format check

Ensures `build.zig`, `build.zig.zon`, and `src/` match `zig fmt` (CI `fmt` step).

## Sub-features

- Uses Zig **0.17.0** from the flake dev shell (same pin as CI)

## How to get to it (user POV)

CI runs format check after flake check, before unit tests.

## Driving it with Lima harness

Preconditions: `doctor` OK.

```sh
.agents/skills/verify-ci/scripts/verify.sh drive zig-fmt-check
```

Observable proof: exit `0`; stderr empty on success.

## Gotchas

- Fix formatting on the host (`nix develop -c zig fmt …`); the guest reads the mounted working tree.
