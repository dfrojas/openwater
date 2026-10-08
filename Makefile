GREEN=\033[0;32m
RED=\033[0;31m
NC=\033[0m

.PHONY: help test fmt

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

test: ## Run the tests
	zig build test

fmt: ## Format the code
	zig fmt build.zig build.zig.zon src
