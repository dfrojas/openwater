# 1. First version of the CLI

Date: 2023-10-22

## Status

Accepted

## Context

I want to learn Rust by doing a toy

## Decision

The CLI will receive three parameters:

* brand and model of the vendor
* output type (Json or Plot initially)
* Path of the input log file

__Use:__

```
openwater -v cressi-leonardo -o json -p /Documents/my-dive-log
```

__Outputs:__

* Json: Generates a JSON file in the same folde where the binary is
* Plot: Generate graphics of depth, time, etc for the logs

## Consequences

None
