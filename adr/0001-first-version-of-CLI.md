# 1. First version of the CLI

Date: 2023-10-22

## Status

Accepted

## Context

I want to learn Rust by doing a toy

## Decision

The CLI can receive three parameters:

* brand and model of the vendor
* output type (Json or Plot initially)
* Path of the input log file

__Use:__

```
cargo run -- -o json -i /Users/diegorojas/Documents/oss/openwater/src/sample_vendors/to_csv.csv
```

__Outputs:__

* Json: Generates a JSON file in the same folder where the binary is
* Plot: Generate graphics of depth, time, etc for the logs

## Consequences

None
