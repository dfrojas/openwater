# UDDF to dive JSON (CLI)

Convert a UDDF XML dive log/plan file into OpenWater’s `dive_json_v1` JSON file.

## Sub-features

- Extension detection: `.uddf`, `.xml` → UDDF XML input; `.json` → JSON output
- Reference validation runs during conversion (`checkReferences` in the library path)
- Fixture content includes generator metadata and two dives in one repetition group

## How to get to it (user POV)

1. Install or build the `openwater` binary (`zig build`).
2. Point `--input` at a UDDF XML file and `--output` at a path ending in `.json`.
3. Run from any directory; paths are relative to the current working directory.

Example (from repo root):

```sh
zig-out/bin/openwater --input fixtures/logbook_v01.uddf --output /tmp/dive.json
```

## Driving it with CLI subprocess

```sh
.agents/skills/verify-openwater/scripts/verify.sh drive uddf-to-json
```

The script copies `fixtures/logbook_v01.uddf` into an isolated run dir, invokes the CLI, and checks:

- Exit code `0`
- Output contains `"schema": "dive_json_v1"`
- Output contains `"name": "OpenWater spike"`

Evidence: `.verify-openwater/evidence/<run_id>/dive.json` and `transcript.txt`.

## Gotchas

- README quickstart mentions `plan.uddf.xml`; the repo ships `fixtures/logbook_v01.uddf` instead. Use the fixture path or your own UDDF file.
- JSON **input** is not supported (`read` returns `UnsupportedFormat`); only UDDF → JSON is a supported user conversion today.
- Output overwrites `--output` if it already exists (normal file write).
