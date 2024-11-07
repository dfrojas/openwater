.PHONY: run-lib
run-lib: ## Compile and run the library with its examples
	@echo "Running library with examples..."
	cargo build --lib
	cargo run --example dev

.PHONY: format
format: ## Format the code
	@echo "Formatting code..."
	rustfmt src/lib/*.rs
