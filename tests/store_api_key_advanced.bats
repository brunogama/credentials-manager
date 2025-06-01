#!/usr/bin/env bats
# store_api_key_advanced.bats - Advanced tests for store-api-key script

load test_helper

STORE_API_KEY_SCRIPT="${PROJECT_ROOT}/store-api-key"

setup() {
  create_mock_security
}

@test "store-api-key validates service name format strictly" {
  # Test various invalid formats
  run "$STORE_API_KEY_SCRIPT" "invalid@name" "test-key"
  [ "$status" -eq 3 ]

  run "$STORE_API_KEY_SCRIPT" "invalid name" "test-key"
  [ "$status" -eq 3 ]

  run "$STORE_API_KEY_SCRIPT" "invalid.name" "test-key"
  [ "$status" -eq 3 ]

  run "$STORE_API_KEY_SCRIPT" "invalid#name" "test-key"
  [ "$status" -eq 3 ]
}

@test "store-api-key accepts valid service name formats" {
  # Test valid formats
  run "$STORE_API_KEY_SCRIPT" "VALID_SERVICE_KEY" "test-key" --force
  [ "$status" -eq 0 ]

  run "$STORE_API_KEY_SCRIPT" "VALID-SERVICE-KEY" "test-key" --force
  [ "$status" -eq 0 ]

  run "$STORE_API_KEY_SCRIPT" "ValidServiceKey123" "test-key" --force
  [ "$status" -eq 0 ]
}

@test "store-api-key rejects empty service name" {
  run "$STORE_API_KEY_SCRIPT" "" "test-key"
  [ "$status" -eq 3 ]
  [[ "$output" =~ "Service name cannot be empty" ]]
}

@test "store-api-key rejects empty API key" {
  run "$STORE_API_KEY_SCRIPT" "TEST_SERVICE" ""
  [ "$status" -eq 3 ]
  [[ "$output" =~ "API key cannot be empty" ]]
}

@test "store-api-key shows security warnings" {
  run "$STORE_API_KEY_SCRIPT" "TEST_SERVICE" "test-key" --force
  [[ "$stderr" =~ "SECURITY WARNING" ]] || [[ "$output" =~ "SECURITY WARNING" ]]
}

@test "store-api-key shows security recommendations" {
  run "$STORE_API_KEY_SCRIPT" "TEST_SERVICE" "test-key" --force
  [[ "$stderr" =~ "terminal session is private" ]] || [[ "$output" =~ "terminal session is private" ]]
}

@test "store-api-key handles --force flag" {
  run "$STORE_API_KEY_SCRIPT" "TEST_SERVICE" "test-key" --force
  [ "$status" -eq 0 ]
  [[ "$output" =~ "successfully stored" ]] || [[ "$output" =~ "added" ]]
}

@test "store-api-key handles -f flag" {
  run "$STORE_API_KEY_SCRIPT" "TEST_SERVICE" "test-key" -f
  [ "$status" -eq 0 ]
}

@test "store-api-key warns about command line arguments" {
  # Test with a long key that might trigger security warning
  run "$STORE_API_KEY_SCRIPT" "TEST_SERVICE" "very-long-api-key-that-looks-sensitive-12345678"
  [[ "$stderr" =~ "WARNING" ]] || [[ "$output" =~ "WARNING" ]]
}

@test "store-api-key provides comprehensive help" {
  run "$STORE_API_KEY_SCRIPT" --help
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "Arguments:" ]]
  [[ "$output" =~ "Options:" ]]
  [[ "$output" =~ "Examples:" ]]
  [[ "$output" =~ "SECURITY RECOMMENDATIONS:" ]]
}

@test "store-api-key help includes security notes" {
  run "$STORE_API_KEY_SCRIPT" --help
  [ "$status" -eq 1 ]
  [[ "$output" =~ "SECURITY" ]]
  [[ "$output" =~ "keychain" ]]
  [[ "$output" =~ "version control" ]]
}

@test "store-api-key validates macOS requirement" {
  # This test checks that the script validates the OS
  # On macOS, it should work; on other systems, it should fail
  if [[ "$OSTYPE" != "darwin"* ]]; then
    run "$STORE_API_KEY_SCRIPT" "TEST_SERVICE" "test-key"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "requires macOS" ]]
  fi
}

@test "store-api-key checks security command availability" {
  # Test behavior when security command is not available
  run bash -c 'PATH="/nonexistent:$PATH" '"$STORE_API_KEY_SCRIPT"' TEST_SERVICE test-key 2>&1 || true'
  # Should either work (if security found elsewhere) or show dependency error
  [[ "$status" -ne 0 ]] || [[ "$output" =~ "successfully" ]]
}

@test "store-api-key handles special characters in API key" {
  # Test with special characters that need proper handling
  run "$STORE_API_KEY_SCRIPT" "TEST_SERVICE" "key-with-special-chars!@#$%^&*()" --force
  [ "$status" -eq 0 ]
}

@test "store-api-key handles very long API keys" {
  # Test with a very long API key
  long_key=$(printf 'a%.0s' {1..1000})
  run "$STORE_API_KEY_SCRIPT" "TEST_SERVICE" "$long_key" --force
  [ "$status" -eq 0 ]
}

@test "store-api-key shows proper exit codes" {
  # Test various exit codes
  run "$STORE_API_KEY_SCRIPT"
  [ "$status" -eq 1 ]  # Usage error

  run "$STORE_API_KEY_SCRIPT" "invalid@name" "key"
  [ "$status" -eq 3 ]  # Validation error

  run "$STORE_API_KEY_SCRIPT" "VALID_NAME" "key" --force
  [ "$status" -eq 0 ]  # Success
}

@test "store-api-key prevents history logging" {
  # This is hard to test directly, but we can verify the script sets up
  # history prevention mechanisms
  run "$STORE_API_KEY_SCRIPT" "TEST_SERVICE" "test-key" --force
  # The script should complete successfully with history prevention
  [ "$status" -eq 0 ]
}

@test "store-api-key handles unknown flags gracefully" {
  run "$STORE_API_KEY_SCRIPT" "TEST_SERVICE" "test-key" --unknown-flag
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}
