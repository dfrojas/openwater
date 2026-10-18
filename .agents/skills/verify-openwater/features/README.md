# OpenWater verification feature map

Primary surface: **CLI** (`zig-out/bin/openwater` or `zig build run -- …`).

| Feature ID | File | Summary |
|------------|------|---------|
| `uddf-to-json` | [uddf-to-json.md](uddf-to-json.md) | Convert UDDF XML on disk to `dive_json_v1` JSON |
| `vendor-dump-to-uddf` | [vendor-dump-to-uddf.md](vendor-dump-to-uddf.md) | Import `.dlf`/`.bin`/`.raw` via libdivecomputer → UDDF XML |
| `vendor-dump-to-json` | [vendor-dump-to-json.md](vendor-dump-to-json.md) | Vendor dump → `dive_json_v1` JSON |
| `vendor-dump-missing-family` | [vendor-dump-missing-family.md](vendor-dump-missing-family.md) | Dump input without `--family` → usage on stderr |
| `cli-usage` | [cli-usage.md](cli-usage.md) | Usage text when required flags are missing |
| `unsupported-extension` | [unsupported-extension.md](unsupported-extension.md) | Reject unsupported conversion (e.g. UDDF → `.dlf` output) |

Drive with:

```sh
.agents/skills/verify-openwater/scripts/verify.sh drive <feature-id>
```
