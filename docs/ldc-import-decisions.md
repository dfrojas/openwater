# libdivecomputer import (2026-10-16)

## Link strategy

Bundled **libdivecomputer 0.9.0** from the official release tarball (`build.zig.zon` dependency). Zig compiles the C sources into a static library via `libdivecomputer_build.zig` and a minimal `vendor/libdivecomputer/config.h` (no USB/BLE backends required for file parsing). C headers reach Zig through **`translate-c`** (`src/ldc/libdivecomputer.h`), not `@cImport` (removed in Zig 0.17).

## Ownership

Single-dive vendor files are parsed in-process. **`dc_parser_t` and `dc_context_t`** live for one import call. Parsed dives are copied into an **`OwnedDocument`** backed by an **arena** (same pattern as UDDF read). Sample callback data is allocated in that arena.

## CLI shape

- Input extensions `.dlf`, `.bin`, `.raw` map to `dive_computer_dump`.
- **`--family`** is required (dctool-style name, e.g. `freedom`). **`--model`** is optional (defaults match dctool for that family).
- Output remains extension-driven (`.uddf` / `.xml` → UDDF XML).

## Fixture

`fixtures/freedom_mix2_v2_00000007.dlf` is from [Subsurface test dives](https://github.com/subsurface/subsurface/tree/master/dives) (Divesoft Freedom, `--family freedom`).
