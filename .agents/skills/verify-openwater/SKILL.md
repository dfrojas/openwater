---
name: verify-openwater
description: Drive the openwater CLI to prove UDDF-to-JSON conversion and error handling. Use when you need end-to-end verification beyond zig build test, or before claiming a user-visible CLI change works.
---

# Verify OpenWater

OpenWater is a **CLI + Zig library** for UDDF dive plans. Users interact with the **CLI** (`openwater --input … --output …`). The library is the engine; prove CLI behavior with this skill.

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
| `fixtures/logbook_v01.uddf` | Canonical UDDF sample (README’s `plan.uddf.xml` is not in the tree) |
| `.uddf`, `.xml` | Input format → UDDF XML |
| `.json` | Output format → `dive_json_v1` |
| `usage: openwater --input` | Printed on stderr when args are missing |
| `error: UnsupportedFormat` | Unknown file extension |

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
