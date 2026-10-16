# OpenWater

Zig library to read and write dive plans in [UDDF](https://www.streit.cc/extern/uddf_v321/en/index.html) format 

> [!NOTE]
> As with most things built in 2026, OpenWater's code was generated with AI tools under close human supervision.

# Usage

### As a library

```zig
const std = @import("std");
const openwater = @import("openwater");

const input = // ... UDDF XML bytes ...

var out = std.Io.Writer.Allocating.init(allocator);
defer out.deinit();
try openwater.convert(allocator, .uddf_xml, input, .dive_json_v1, &out.writer);
```

### From the CLI

```sh
openwater --input plan.uddf.xml --output dive.json
```

The CLI calls the library. The library is the engine. The library can also be used in other external Zig packages.

Input and output formats are chosen from the file extensions (`.uddf`, `.xml`, `.json`). Vendor dive dumps (`.dlf`, `.bin`, `.raw`) require `--family` (and optionally `--model`), parsed via libdivecomputer:

```sh
openwater --input dive.dlf --output dive.uddf --family freedom
```

# Why

I like to learn by working on real projects. I'm using my passion for diving to learn a new programming language.

## Test and run

Requires Zig 0.17.0.

```sh
zig build test
zig build run -- --input plan.uddf.xml --output dive.json
```
