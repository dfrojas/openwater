# Unsupported format conversion

The CLI maps extensions in `src/cli/args.zig`: `.uddf`/`.xml`, `.json`, and vendor dumps `.dlf`/`.bin`/`.raw`. Some **combinations** are rejected during conversion with `error: UnsupportedFormat` on stderr.

## Sub-features

- JSON as **input** (extension is known but `read` rejects it)
- Dive-computer dump as **output** (extension is known but `write` rejects it)
- Unknown extensions (e.g. `.txt`) fail at parse time and print **usage** on stderr instead — not this feature

## How to get to it (user POV)

Use a valid UDDF input and an output extension that cannot be written (dump extension on `--output`):

```sh
openwater --input fixtures/logbook_v01.uddf --output out.dlf
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

- Do not use `.txt` input to test this feature; that path triggers usage text, not `UnsupportedFormat`.
- Malformed XML is a different error path; use a known-good UDDF file as input.
