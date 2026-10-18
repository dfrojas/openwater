# Vendor dive dump to dive JSON (CLI)

Convert a vendor dive dump into OpenWater’s `dive_json_v1` JSON file (dump → in-memory document → JSON).

## Sub-features

- Same input rules as `vendor-dump-to-uddf` (dump extension + `--family`)
- Output path ending in `.json` selects `dive_json_v1`

## How to get to it (user POV)

```sh
zig-out/bin/openwater \
  --input fixtures/freedom_mix2_v2_00000007.dlf \
  --output /tmp/freedom.json \
  --family freedom
```

## Driving it with CLI subprocess

```sh
.agents/skills/verify-openwater/scripts/verify.sh drive vendor-dump-to-json
```

Checks:

- Exit code `0`
- Output contains `"schema": "dive_json_v1"`

Evidence: `.verify-openwater/evidence/<run_id>/freedom.json` and `transcript.txt`.

## Gotchas

- JSON **input** is still unsupported; only dump → JSON is in scope here.
