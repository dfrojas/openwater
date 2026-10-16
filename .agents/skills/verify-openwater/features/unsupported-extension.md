# Unsupported file extension

The CLI picks input/output formats from path extensions. Unknown extensions fail before conversion.

## Sub-features

- `formatFromPath` in `src/cli/args.zig` maps `.json`, `.uddf`, `.xml` only
- Error surfaced as `error: UnsupportedFormat` on stderr

## How to get to it (user POV)

Pass `--input` or `--output` paths whose extension is not one of the supported set (e.g. `.txt`).

```sh
openwater --input notes.txt --output out.json
```

## Driving it with CLI subprocess

```sh
.agents/skills/verify-openwater/scripts/verify.sh drive unsupported-extension
```

Checks:

- Exit code `1`
- Stderr contains `error: UnsupportedFormat`
- Output file is **not** created

Evidence: `.verify-openwater/evidence/<run_id>/transcript.txt`.

## Gotchas

- Failure happens at argument parsing (extension check), not during XML parse—do not use malformed XML to test this feature.
