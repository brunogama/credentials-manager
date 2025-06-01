#!/bin/bash
# test-config-manager.sh
# Test script for the security configuration management system

# Source the configuration manager
# shellcheck source=lib/config-manager.sh
source "lib/config-manager.sh"

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Test function helper
run_test() {
  local test_name="$1"
  local test_command="$2"

  echo "Running test: $test_name"

  if eval "$test_command"; then
    echo "✅ PASS: $test_name"
    ((TESTS_PASSED++))
  else
    echo "❌ FAIL: $test_name"
    ((TESTS_FAILED++))
  fi
  echo ""
}

# Test 1: Configuration file creation and permissions
test_config_file_creation() {
  local config_file="$HOME/.credmatch/security.conf"

  # Remove existing config for clean test
  rm -f "$config_file"

  # Load configuration (should create default)
  load_security_config

  # Check if file exists
  [[ -f "$config_file" ]] || return 1

  # Check file permissions
  local perms
  perms=$(stat -f "%A" "$config_file" 2>/dev/null || stat -c "%a" "$config_file" 2>/dev/null)
  [[ "$perms" == "600" ]] || return 1

  return 0
}

# Test 2: Configuration loading
test_config_loading() {
  # Load configuration
  load_security_config

  # Check if key variables are set
  [[ -n "$UMASK" ]] || return 1
  [[ -n "$SESSION_TIMEOUT" ]] || return 1
  [[ -n "$AUDIT_LOGGING" ]] || return 1

  return 0
}

# Test 3: Configuration validation
test_config_validation() {
  # Test with valid configuration
  UMASK=077
  SESSION_TIMEOUT=1800
  AUDIT_LOGGING=true

  validate_config_values || return 1

  # Test with invalid UMASK
  UMASK=999
  if validate_config_values; then
    return 1  # Should fail validation
  fi

  # Reset to valid value
  UMASK=077

  return 0
}

# Test 4: Permission validation
test_permission_validation() {
  local test_file
  test_file=$(mktemp)

  # Set correct permissions
  chmod 600 "$test_file"
  validate_config_permissions "$test_file" || return 1

  # Set incorrect permissions
  chmod 644 "$test_file"
  if validate_config_permissions "$test_file"; then
    rm -f "$test_file"
    return 1  # Should fail validation
  fi

  rm -f "$test_file"
  return 0
}

# Test 5: Configuration value getter
test_config_getter() {
  UMASK=077
  local value
  value=$(get_config_value "UMASK" "022")
  [[ "$value" == "077" ]] || return 1

  # Test with non-existent variable
  unset NONEXISTENT_VAR
  value=$(get_config_value "NONEXISTENT_VAR" "default")
  [[ "$value" == "default" ]] || return 1

  return 0
}

# Test 6: Show configuration function
test_show_config() {
  # This should not fail
  show_config > /dev/null 2>&1
  return $?
}

# Run all tests
echo "🧪 Testing Security Configuration Management System"
echo "=================================================="
echo ""

run_test "Configuration file creation and permissions" "test_config_file_creation"
run_test "Configuration loading" "test_config_loading"
run_test "Configuration validation" "test_config_validation"
run_test "Permission validation" "test_permission_validation"
run_test "Configuration value getter" "test_config_getter"
run_test "Show configuration function" "test_show_config"

# Summary
echo "Test Results:"
echo "============="
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "🎉 All tests passed! Configuration management system is working correctly."
  exit 0
else
  echo "⚠️  Some tests failed. Please review the implementation."
  exit 1
fi
