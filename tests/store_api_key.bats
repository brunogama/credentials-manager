#!/usr/bin/env bats
# store_api_key.bats - Unit tests for store-api-key script

load test_helper

STORE_API_KEY_SCRIPT="${PROJECT_ROOT}/store-api-key"

@test "store-api-key script exists and is executable" {
  assert_script_exists "$STORE_API_KEY_SCRIPT"
}

@test "store-api-key script has valid bash syntax" {
  check_script_syntax "$STORE_API_KEY_SCRIPT"
}

@test "store-api-key script passes shellcheck" {
  check_script_shellcheck "$STORE_API_KEY_SCRIPT"
}

@test "store-api-key shows usage when no arguments provided" {
  run "$STORE_API_KEY_SCRIPT"
  [ "$status" -eq 1 ]
}

@test "store-api-key shows usage with --help flag" {
  run "$STORE_API_KEY_SCRIPT" --help
  [ "$status" -eq 0 ]
}

@test "store-api-key shows usage with -h flag" {
  run "$STORE_API_KEY_SCRIPT" -h
  [ "$status" -eq 0 ]
}

@test "store-api-key rejects invalid service name" {
  run "$STORE_API_KEY_SCRIPT" "INVALID@SERVICE" "test-key"
  [ "$status" -eq 3 ]
}

@test "store-api-key accepts valid service name" {
  run "$STORE_API_KEY_SCRIPT" "VALID_SERVICE_KEY" "test-api-key" --force
  [ "$status" -eq 0 ]
}

@test "store-api-key handles --force flag correctly" {
  run "$STORE_API_KEY_SCRIPT" "TEST_SERVICE" "test-key" --force
  [ "$status" -eq 0 ]
}
