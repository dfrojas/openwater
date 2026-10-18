---
name: verify-ci
description: Reproduce GitHub CI on a local Lima Ubuntu VM with Nix sandbox enabled. Use before pushing CI or Nix changes, or when debugging linux-only failures.
---

# Verify OpenWater CI

Primary surface: **GitHub Actions workflow** [`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml) — same commands run inside a **Lima** guest that mirrors `ubuntu-latest` + `install-nix-action` (Nix with **sandbox true**).

This is not the app CLI; see [`verify-openwater`](../verify-openwater/SKILL.md) for `openwater` binary checks.

## Launch

One long-lived VM per machine. Default instance name: **`openwater`**.

From repo root:

```sh
.agents/skills/verify-ci/scripts/verify.sh launch
```

First start uses [`.agents/skills/verify-ci/scripts/openwater.yaml`](scripts/openwater.yaml) (Ubuntu 24.04, virtiofs home mount, Nix daemon, sandbox enabled). Ready when `launch: OK` and probes pass (Nix installed, `sandbox = true`).

Optional env:

- `OPENWATER_LIMA_INSTANCE` — override instance name (default: `openwater`)
- `OPENWATER_LIMA_YAML` — override config path (default: skill `scripts/openwater.yaml`)

The guest sees the host home tree at the **same paths** (e.g. this repo at your normal `$PWD`). No separate checkout inside the VM.

**Teardown:** `limactl stop openwater` when you are done with the VM. Do **not** stop the VM between drives in one verification session. Do not run concurrent `drive` commands against the same instance (shared Nix store and Zig cache).

## Doctor

Read-only gate before driving:

```sh
.agents/skills/verify-ci/scripts/verify.sh doctor
```

Expect `doctor: OK` with instance name, repo path, and `sandbox=true`.

## Drive

Harness: **Lima shell** running the same `nix` / `zig` commands as CI.

```sh
.agents/skills/verify-ci/scripts/verify.sh drive <feature-id>
```

Feature IDs match [`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml) steps — see [`features/README.md`](features/README.md).

| Handle | CI meaning |
|--------|------------|
| `nix flake check --accept-flake-config` | `test` job, flake validity |
| `nix develop … -c zig fmt --check …` | `test` job `fmt` step |
| `nix develop … -c zig build test` | `test` job `test` step |
| `nix develop … -c zig build -Dtarget=…` | `build` job matrix (four targets) |

Always pass `--accept-flake-config` in the guest (matches workflow).

## Evidence

Proof standard: run commands **inside the Lima guest**, capture **exit code + stdout/stderr**, and treat CI green as all steps exit `0`.

Each drive writes to:

`.verify-ci/evidence/<run_id>/transcript.txt`

Evidence **persists** across cleanup. Do not delete `.verify-ci/evidence/` during cleanup.

## Cleanup

Removes **scratch only** under `.verify-ci/runs/`, never evidence and never the Lima VM:

```sh
.agents/skills/verify-ci/scripts/verify.sh cleanup
.agents/skills/verify-ci/scripts/verify.sh cleanup --run-id <run_id>
```

Never `killall` / `pkill` by name; stop only via `limactl stop <instance>` when tearing down the VM.

## Helpers

All commands assume **repository root** as cwd on the host.

```sh
chmod +x .agents/skills/verify-ci/scripts/verify.sh   # once if needed

.agents/skills/verify-ci/scripts/verify.sh launch
.agents/skills/verify-ci/scripts/verify.sh doctor
.agents/skills/verify-ci/scripts/verify.sh drive nix-flake-check
.agents/skills/verify-ci/scripts/verify.sh cleanup
```

Maintenance: `/maintain-verification-skill` when workflow steps, Nix inputs, or Lima provisioning change.

## Stand-in vs GitHub

| GitHub | Local Lima |
|--------|------------|
| `ubuntu-latest` runner | Ubuntu 24.04 template |
| `cachix/install-nix-action` | Provision script in `openwater.yaml` |
| `actions/cache` for `~/.cache/zig` | Guest uses host home mount (cache may persist on host) |
| macOS/Windows matrix rows on `ubuntu-latest` | All four `-Dtarget=` builds run **inside Linux guest** (same as workflow) |

Unverified on Lima until driven: Actions cache restore keys, checkout `fetch-depth: 0` semantics (git history must exist in mounted repo).
