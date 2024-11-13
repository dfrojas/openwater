.PHONY: compile-lib
compile-lib: ## Compile the library
	@echo "Compiling library..."
	cargo build --lib

.PHONY: run-lib
run-lib: ## Compile and run the library with its examples
	@echo "Running library with examples..."
	cargo build --lib
	cargo run --example dev

.PHONY: format
format: ## Format the code
	@echo "Formatting code..."
	rustfmt src/lib/*.rs
	rustfmt src/cli/*.rs
	rustfmt examples/*.rs

.PHONY: export-to-json
export-to-json: ## Export to JSON
	@echo "Exporting to JSON..."
	cargo run --bin cli -- -o json -i examples/uddf/log.uddf

.PHONY: export-to-plot
export-to-plot: ## Export to Plot
	@echo "Exporting to Plot..."
	cargo run --bin cli -- -o plot -i examples/uddf/log.uddf
