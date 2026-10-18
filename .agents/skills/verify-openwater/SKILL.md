---
name: verify-openwater
description: Drive the openwater CLI to prove UDDF and vendor-dump conversion plus error handling. Use when you need end-to-end verification beyond zig build test, or before claiming a user-visible CLI change works.
---

# Verify OpenWater

OpenWater is a **CLI + Zig library** for UDDF dive plans and vendor dive dumps (libdivecomputer). Users interact with the **CLI** (`openwater --input … --output …` plus `--family` for `.dlf`/`.bin`/`.raw`). The library is the engine; prove CLI behavior with this skill.

There is **no server**, port, or auth. Each drive is a **short-lived subprocess** with file I/O. Multiple drives are safe if each uses its own run scratch dir (default).

## Launch

Build the CLI once per workspace (or when sources change):

```sh
cd /path/to/openwater
zig build
```

Ready when `zig-out/bin/openwater` exists and is executable. Zig **0.17.0** is required (`zig version`).

Optional env:

- `OPENWATER_BIN` — override binary path (default: `zig-out/bin/openwater`).

There is nothing to keep running between drives. **Teardown** after a session is `cleanup` (below); it does not stop a daemon.

## Doctor

Read-only gate before driving:

```sh
.agents/skills/verify-openwater/scripts/verify.sh doctor
```

Expect `doctor: OK` with zig version, binary path, and fixture path. If doctor fails, fix the build or toolchain before driving.

## Drive

Harness: **subprocess CLI** via the helper script (repo root as cwd).

```sh
.agents/skills/verify-openwater/scripts/verify.sh drive <feature-id>
```

Feature IDs and journeys live in [`features/README.md`](features/README.md). Prefer stable paths and stderr strings from this repo:

| Handle | Meaning |
|--------|---------|
| `--input` / `--output` | Required flags |
| `--family` / `--model` | Required `--family` for vendor dumps; optional model override |
| `fixtures/logbook_v01.uddf` | Canonical UDDF sample (README’s `plan.uddf.xml` is not in the tree) |
| `fixtures/freedom_mix2_v2_00000007.dlf` | Divesoft Freedom dump for LDC import drives |
| `.uddf`, `.xml` | Input/output → UDDF XML |
| `.json` | Output → `dive_json_v1` |
| `.dlf`, `.bin`, `.raw` | Input → dive-computer dump (needs `--family`) |
| `usage: openwater --input` | Parse failure (missing flags, unknown ext, dump without `--family`, …) |
| `error: UnsupportedFormat` | Known extension but conversion not supported (e.g. JSON input, dump output) |

Do **not** rely on internal test modules or `@import("fixtures")` for proof; copy the on-disk fixture into an isolated run dir like the script does.

## Evidence

Proof standard: run the **real CLI**, capture **exit code + stderr/stdout + output files**, and check **side effects** (file created or deliberately absent).

Each drive writes to:

`.verify-openwater/evidence/<run_id>/`

Typical artifacts:

- `transcript.txt` — exit code and captured streams
- `dive.json` — for `uddf-to-json` (full converted output)

Evidence **persists** across cleanup. Do not delete `.verify-openwater/evidence/` during cleanup.

## Cleanup

Removes **scratch only** (inputs/outputs under active runs), never evidence:

```sh
# All run scratch dirs
.agents/skills/verify-openwater/scripts/verify.sh cleanup

# One run
.agents/skills/verify-openwater/scripts/verify.sh cleanup --run-id <run_id>
```

Never kill by process name; the CLI exits on its own.

## Helpers

All commands assume **repository root** as the current working directory.

```sh
chmod +x .agents/skills/verify-openwater/scripts/verify.sh   # once if needed

.agents/skills/verify-openwater/scripts/verify.sh doctor
.agents/skills/verify-openwater/scripts/verify.sh drive uddf-to-json
.agents/skills/verify-openwater/scripts/verify.sh cleanup
```

Maintenance: use `/maintain-verification-skill` when CLI flags, formats, or fixtures change.
