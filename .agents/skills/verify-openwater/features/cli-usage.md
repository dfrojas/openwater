# CLI usage on invalid invocation

When the user omits required flags, the CLI prints usage and exits non-zero.

## Sub-features

- Missing both `--input` and `--output`
- Usage line on stderr (stdout stays empty for this case)

## How to get to it (user POV)

Run the binary with no arguments (or any argv that fails `args.parse` before conversion).

```sh
openwater
```

## Driving it with CLI subprocess

```sh
.agents/skills/verify-openwater/scripts/verify.sh drive cli-usage
```

Checks:

- Exit code `1`
- Stderr contains `usage: openwater --input <path> --output <path>`

Evidence: `.verify-openwater/evidence/<run_id>/transcript.txt`.

## Gotchas

- Partial flags (only `--input` or only `--output`) also fail parse with exit `1` and print the same usage line; this map entry is verified via the **no-args** drive only.
- Vendor dump input without `--family` also prints usage (see `vendor-dump-missing-family`).
