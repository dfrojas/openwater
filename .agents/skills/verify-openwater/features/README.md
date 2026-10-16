# OpenWater verification feature map

Primary surface: **CLI** (`zig-out/bin/openwater` or `zig build run -- …`).

| Feature ID | File | Summary |
|------------|------|---------|
| `uddf-to-json` | [uddf-to-json.md](uddf-to-json.md) | Convert UDDF XML on disk to `dive_json_v1` JSON |
| `cli-usage` | [cli-usage.md](cli-usage.md) | Usage text when required flags are missing |
| `unsupported-extension` | [unsupported-extension.md](unsupported-extension.md) | Reject unknown input/output extensions |

Drive with:

```sh
.agents/skills/verify-openwater/scripts/verify.sh drive <feature-id>
```
