# Nix flake check

Validates the flake evaluates on a Linux runner with Nix sandbox enabled (same as the CI `test` job’s first step).

## Sub-features

- Flake inputs lock and dev shell evaluate
- `--accept-flake-config` matches workflow flags

## How to get to it (user POV)

After CI would checkout the repo and install Nix, the first command is flake check. Locally, that means the Lima guest at your repo path.

## Driving it with Lima harness

Preconditions:

- `.agents/skills/verify-ci/scripts/verify.sh doctor` passes
- Repo includes `flake.nix` and `flake.lock`

```sh
.agents/skills/verify-ci/scripts/verify.sh drive nix-flake-check
```

Observable proof: exit `0`, transcript under `.verify-ci/evidence/<run_id>/`.

## Gotchas

- Running `nix flake check` on macOS host does **not** prove CI; use this drive in Lima.
- First Nix command in a fresh VM may download heavily; later drives reuse the store.
