# OpenWater CI verification map

Primary surface: **GitHub Actions** [`.github/workflows/ci.yml`](../../../../.github/workflows/ci.yml), reproduced in the **`openwater` Lima** guest via [`.agents/skills/verify-ci/scripts/verify.sh`](../scripts/verify.sh).

| Feature ID | File | Summary |
|------------|------|---------|
| `nix-flake-check` | [nix-flake-check.md](nix-flake-check.md) | `nix flake check --accept-flake-config` |
| `zig-fmt-check` | [zig-fmt-check.md](zig-fmt-check.md) | `zig fmt --check` via `nix develop` |
| `zig-unit-test` | [zig-unit-test.md](zig-unit-test.md) | `zig build test` via `nix develop` |
| `cross-compile-matrix` | [cross-compile-matrix.md](cross-compile-matrix.md) | Four `-Dtarget=` builds from the `build` job |

Drive with:

```sh
.agents/skills/verify-ci/scripts/verify.sh drive <feature-id>
```

Baseline: run `doctor` first; Lima instance must be **Running** and Nix **sandbox true**.
