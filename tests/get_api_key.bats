#!/usr/bin/env bats
# get_api_key.bats - Unit tests for get-api-key script

load test_helper

GET_API_KEY_SCRIPT="${PROJECT_ROOT}/get-api-key"

@test "get-api-key script exists and is executable" {
  assert_script_exists "$GET_API_KEY_SCRIPT"
}

@test "get-api-key script has valid bash syntax" {
  check_script_syntax "$GET_API_KEY_SCRIPT"
}

@test "get-api-key script passes shellcheck" {
  check_script_shellcheck "$GET_API_KEY_SCRIPT"
}

@test "get-api-key shows usage when no arguments provided" {
  run "$GET_API_KEY_SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "get-api-key shows usage with --help flag" {
  run "$GET_API_KEY_SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "get-api-key shows usage with -h flag" {
  run "$GET_API_KEY_SCRIPT" -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "get-api-key shows usage with multiple arguments" {
  run "$GET_API_KEY_SCRIPT" arg1 arg2
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "get-api-key rejects empty service name" {
  run "$GET_API_KEY_SCRIPT" ""
  [ "$status" -eq 3 ]
  [[ "$output" =~ "Service name cannot be empty" ]]
}

@test "get-api-key rejects invalid service name with special characters" {
  run "$GET_API_KEY_SCRIPT" "INVALID@SERVICE"
  [ "$status" -eq 3 ]
  [[ "$output" =~ "Service name must contain only letters, numbers, underscores, and dashes" ]]
}

@test "get-api-key rejects invalid service name with spaces" {
  run "$GET_API_KEY_SCRIPT" "INVALID SERVICE"
  [ "$status" -eq 3 ]
  [[ "$output" =~ "Service name must contain only letters, numbers, underscores, and dashes" ]]
}

@test "get-api-key accepts valid service name with underscores" {
  run "$GET_API_KEY_SCRIPT" "TEST_API_KEY"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "test-api-key-12345" ]]
}

@test "get-api-key accepts valid service name with dashes" {
  run "$GET_API_KEY_SCRIPT" "TEST-API-KEY"
  [ "$status" -eq 4 ]  # Not found in mock
}

@test "get-api-key retrieves existing API key" {
  run "$GET_API_KEY_SCRIPT" "TEST_API_KEY"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "test-api-key-12345" ]]
  [[ "$output" =~ "Security reminder" ]]
}

@test "get-api-key handles non-existent API key" {
  run "$GET_API_KEY_SCRIPT" "NONEXISTENT_KEY"
  [ "$status" -eq 4 ]
  [[ "$output" =~ "API key for 'NONEXISTENT_KEY' not found in keychain" ]]
}

@test "get-api-key retrieves SERVICEA_API_KEY" {
  run "$GET_API_KEY_SCRIPT" "SERVICEA_API_KEY"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "servicea-key-67890" ]]
}

@test "get-api-key retrieves AWS_API_KEY" {
  run "$GET_API_KEY_SCRIPT" "AWS_API_KEY"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "aws-key-abcdef" ]]
}

@test "get-api-key shows security warning" {
  run_with_stderr "$GET_API_KEY_SCRIPT" "TEST_API_KEY"
  [ "$status" -eq 0 ]
  [[ "$stderr" =~ "SECURITY WARNING" ]]
  [[ "$stderr" =~ "sensitive API key" ]]
}

@test "get-api-key shows security recommendations" {
  run_with_stderr "$GET_API_KEY_SCRIPT" "TEST_API_KEY"
  [ "$status" -eq 0 ]
  [[ "$stderr" =~ "terminal session is private" ]]
  [[ "$stderr" =~ "copying/pasting" ]]
}

@test "get-api-key outputs only the key value to stdout" {
  run_with_stderr "$GET_API_KEY_SCRIPT" "TEST_API_KEY"
  [ "$status" -eq 0 ]
  # Check that stdout contains only the key (first line)
  first_line=$(echo "$output" | head -n1)
  [[ "$first_line" == "test-api-key-12345" ]]
}

@test "get-api-key security warnings go to stderr" {
  run_with_stderr "$GET_API_KEY_SCRIPT" "TEST_API_KEY"
  [ "$status" -eq 0 ]
  # Security messages should be in stderr, not stdout
  [[ "$stderr" =~ "SECURITY WARNING" ]]
  [[ ! "$output" =~ "SECURITY WARNING" ]]
}
