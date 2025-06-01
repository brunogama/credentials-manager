.PHONY: test lint setup-pre-commit run-pre-commit
test:
	./tests/run_all_tests.sh

lint:
	@echo "Running shellcheck on all scripts..."
	@find . -type f \( -name "*.sh" -o -name "*.bash" -o -name "credmatch" -o -name "store-api-key" -o -name "get-api-key" -o -name "dump-api-keys" -o -name "*.bats" \) -not -path "*/fixtures/*" -exec shellcheck {} +

setup-pre-commit:
	@command -v pre-commit >/dev/null 2>&1 || { echo "Installing pre-commit..."; pip install pre-commit; }
	@pre-commit install
	@echo "pre-commit hooks installed successfully!"

run-pre-commit:
	@pre-commit run --all-files
