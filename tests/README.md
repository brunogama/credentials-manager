# Test Suite for Credential Management Scripts

This directory contains comprehensive unit tests for all credential management scripts using the [bats-core](https://github.com/bats-core/bats-core) testing framework.

## Test Structure

### Test Files

- **`credmatch.bats`** - Basic tests for the credmatch script
- **`credmatch_basic.bats`** - Additional basic credmatch functionality tests
- **`credmatch_advanced.bats`** - Advanced credmatch functionality tests
- **`store_api_key.bats`** - Basic tests for the store-api-key script
- **`store_api_key_advanced.bats`** - Advanced store-api-key functionality tests
- **`get_api_key.bats`** - Tests for the get-api-key script
- **`dump_api_keys.bats`** - Tests for the dump-api-keys script
- **`test_all_scripts.bats`** - Tests for the test-all-scripts.sh script
- **`test_config_manager.bats`** - Tests for the test-config-manager.sh script

### Support Files

- **`test_helper.bash`** - Common test utilities and setup functions
- **`fixtures/security`** - Mock security command for testing macOS keychain operations
- **`run_all_tests.sh`** - Script to run all test files with summary reporting

## Running Tests

### Prerequisites

Install bats-core:
```bash
brew install bats-core
```

### Run All Tests

```bash
# Run all test files
./tests/run_all_tests.sh

# Or run all tests with bats directly
bats tests/
```

### Run Individual Test Files

```bash
# Run specific test file
bats tests/credmatch.bats

# Run with verbose output
bats --verbose-run tests/get_api_key.bats

# Run specific test
bats tests/store_api_key.bats --filter "validates service name"
```

## Test Coverage

### Script Validation Tests
- ✅ Script existence and executability
- ✅ Bash syntax validation
- ✅ Shellcheck compliance
- ✅ Help/usage output validation

### Functionality Tests

#### credmatch
- ✅ Command line argument validation
- ✅ Git repository initialization
- ✅ Current directory mode detection
- ✅ Security warnings and recommendations
- ✅ Dependency checking (git, openssl)
- ✅ Error handling for uninitialized stores

#### store-api-key
- ✅ Service name format validation
- ✅ API key validation
- ✅ macOS/security command requirements
- ✅ Force flag handling
- ✅ Security warnings and history prevention
- ✅ Special character handling

#### get-api-key
- ✅ Service name validation
- ✅ API key retrieval from mock keychain
- ✅ Error handling for missing keys
- ✅ Security warnings and output separation
- ✅ Help and usage validation

#### dump-api-keys
- ✅ Pattern filtering functionality
- ✅ Safe mode script generation
- ✅ Export format validation
- ✅ Security warnings
- ✅ Multiple key handling

#### Test Scripts
- ✅ test-all-scripts.sh execution and output
- ✅ test-config-manager.sh execution and validation
- ✅ Timeout handling and error recovery

## Mock Testing

The test suite uses mock implementations to avoid modifying the actual macOS keychain:

### Mock Security Command
- Located at `fixtures/security`
- Simulates macOS security command behavior
- Provides test data for API keys:
  - `TEST_API_KEY` → `test-api-key-12345`
  - `SERVICEA_API_KEY` → `servicea-key-67890`
  - `AWS_API_KEY` → `aws-key-abcdef`

### Test Environment
- Uses temporary directories for git operations
- Isolated from actual credential stores
- Automatic cleanup after each test

## Security Testing

The test suite validates security features:

- ✅ History prevention mechanisms
- ✅ Security warning displays
- ✅ Sensitive data handling in command line arguments
- ✅ File permission validation
- ✅ Input validation and sanitization

## Test Helpers

### Common Functions
- `assert_script_exists()` - Verify script existence and executability
- `check_script_syntax()` - Validate bash syntax
- `check_script_shellcheck()` - Run shellcheck validation
- `create_mock_security()` - Set up mock security command
- `create_test_git_repo()` - Create temporary git repositories

### Environment Setup
- Automatic temporary directory creation
- Mock command path setup
- Test data initialization
- Cleanup on test completion

## Continuous Integration

The test suite is designed to run in CI environments:

- No external dependencies beyond bats-core
- Mock implementations for system commands
- Timeout protection for long-running tests
- Clear exit codes and error reporting

## Adding New Tests

When adding new tests:

1. Follow the existing naming convention: `script_name.bats`
2. Use the test helper functions for common operations
3. Include both positive and negative test cases
4. Test error conditions and edge cases
5. Add security-related tests for sensitive operations
6. Update `run_all_tests.sh` to include new test files

### Test Template

```bash
#!/usr/bin/env bats
# script_name.bats - Unit tests for script-name script

load test_helper

SCRIPT_PATH="${PROJECT_ROOT}/script-name"

setup() {
  # Test-specific setup
}

@test "script-name script exists and is executable" {
  assert_script_exists "$SCRIPT_PATH"
}

@test "script-name script has valid bash syntax" {
  check_script_syntax "$SCRIPT_PATH"
}

@test "script-name script passes shellcheck" {
  check_script_shellcheck "$SCRIPT_PATH"
}

# Add more specific tests...
```

## Troubleshooting

### Common Issues

1. **Tests fail with "command not found"**
   - Ensure bats-core is installed: `brew install bats-core`

2. **Mock security command not working**
   - Check that `fixtures/security` is executable: `chmod +x tests/fixtures/security`

3. **Git-related test failures**
   - Ensure git is installed and configured
   - Check that test directories are writable

4. **Timeout errors**
   - Some tests use 30-second timeouts to prevent hanging
   - Increase timeout values if needed for slower systems

### Debug Mode

Run tests with debug output:
```bash
bats --verbose-run --show-output-of-passing-tests tests/script_name.bats
```
