# Vendor dive dump to UDDF (CLI)

Convert a libdivecomputer-supported vendor dump (`.dlf`, `.bin`, or `.raw`) into UDDF XML on disk.

## Sub-features

- Extension detection: `.dlf`, `.bin`, `.raw` → dive-computer dump input
- Required `--family` (dctool-style name, e.g. `freedom` for Divesoft Freedom)
- Optional `--model` (defaults per family in `src/ldc/family.zig`)
- Parsed via bundled libdivecomputer 0.9.0 (file-only; no USB/BLE)

## How to get to it (user POV)

1. Build `openwater` (`zig build`).
2. Point `--input` at a vendor dump and `--output` at a path ending in `.uddf` or `.xml`.
3. Pass `--family` matching the dive computer that produced the dump.

Example (repo fixture):

```sh
zig-out/bin/openwater \
  --input fixtures/freedom_mix2_v2_00000007.dlf \
  --output /tmp/freedom.uddf \
  --family freedom
```

## Driving it with CLI subprocess

```sh
.agents/skills/verify-openwater/scripts/verify.sh drive vendor-dump-to-uddf
```

The script copies `fixtures/freedom_mix2_v2_00000007.dlf` into an isolated run dir, invokes the CLI with `--family freedom`, and checks:

- Exit code `0`
- Output contains `<uddf version="3.2.3">`
- Output contains `<greatestdepth>18.98</greatestdepth>`

Evidence: `.verify-openwater/evidence/<run_id>/freedom.uddf` and `transcript.txt`.

## Gotchas

- Without `--family`, parse fails and the CLI prints **usage** on stderr (not `error: MissingDiveComputerFamily`). See `vendor-dump-missing-family`.
- Unknown `--family` strings fail during conversion with `error: UnknownDiveComputerFamily`.
