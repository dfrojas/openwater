# Vendor dump without `--family`

When the input path is a dive-computer dump (`.dlf`, `.bin`, `.raw`) but `--family` is omitted, the CLI rejects the invocation before conversion.

## Sub-features

- `args.parse` returns `MissingDiveComputerFamily` internally
- `main` maps all parse errors to the usage line on stderr (same as missing `--input` / `--output`)

## How to get to it (user POV)

```sh
openwater --input dive.dlf --output out.uddf
```

## Driving it with CLI subprocess

```sh
.agents/skills/verify-openwater/scripts/verify.sh drive vendor-dump-missing-family
```

Checks:

- Exit code `1`
- Stderr contains `usage: openwater --input`
- Output file is **not** created

Evidence: `.verify-openwater/evidence/<run_id>/transcript.txt`.

## Gotchas

- This is not `error: UnsupportedFormat`; the extension is recognized as a vendor dump.
