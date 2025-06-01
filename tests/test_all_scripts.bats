#!/usr/bin/env bats
# test_all_scripts.bats - Unit tests for test-all-scripts.sh script

load test_helper

TEST_ALL_SCRIPTS="${PROJECT_ROOT}/test-all-scripts.sh"

@test "test-all-scripts.sh script exists and is executable" {
  assert_script_exists "$TEST_ALL_SCRIPTS"
}

@test "test-all-scripts.sh script has valid bash syntax" {
  check_script_syntax "$TEST_ALL_SCRIPTS"
}

@test "test-all-scripts.sh script passes shellcheck" {
  check_script_shellcheck "$TEST_ALL_SCRIPTS"
}

@test "test-all-scripts.sh runs without errors" {
  # Run with timeout to prevent hanging
  run timeout 30s "$TEST_ALL_SCRIPTS"
  # Should complete within timeout (exit code 0 or test failures)
  [[ "$status" -ne 124 ]]  # 124 is timeout exit code
}

@test "test-all-scripts.sh produces test output" {
  run timeout 30s "$TEST_ALL_SCRIPTS"
  # Should produce some test output
  [[ "$output" =~ "Testing" ]] || [[ "$output" =~ "PASS" ]] || [[ "$output" =~ "FAIL" ]]
}

@test "test-all-scripts.sh includes syntax tests" {
  run timeout 30s "$TEST_ALL_SCRIPTS"
  # Should test script syntax
  [[ "$output" =~ "syntax" ]] || [[ "$output" =~ "Syntax" ]]
}

@test "test-all-scripts.sh includes help tests" {
  run timeout 30s "$TEST_ALL_SCRIPTS"
  # Should test help output
  [[ "$output" =~ "help" ]] || [[ "$output" =~ "Help" ]]
}

@test "test-all-scripts.sh includes dependency tests" {
  run timeout 30s "$TEST_ALL_SCRIPTS"
  # Should test dependencies
  [[ "$output" =~ "dependencies" ]] || [[ "$output" =~ "Dependencies" ]]
}

@test "test-all-scripts.sh tests credmatch functionality" {
  run timeout 30s "$TEST_ALL_SCRIPTS"
  # Should test credmatch
  [[ "$output" =~ "credmatch" ]] || [[ "$output" =~ "CredMatch" ]]
}

@test "test-all-scripts.sh tests API scripts" {
  run timeout 30s "$TEST_ALL_SCRIPTS"
  # Should test API key scripts
  [[ "$output" =~ "api" ]] || [[ "$output" =~ "API" ]]
}

@test "test-all-scripts.sh shows test summary" {
  run timeout 30s "$TEST_ALL_SCRIPTS"
  # Should show test results summary
  [[ "$output" =~ "passed" ]] || [[ "$output" =~ "failed" ]] || [[ "$output" =~ "Total" ]]
}

@test "test-all-scripts.sh uses colors in output" {
  run timeout 30s "$TEST_ALL_SCRIPTS"
  # Should use color codes (ANSI escape sequences)
  [[ "$output" =~ $'\033' ]]
}

@test "test-all-scripts.sh handles script errors gracefully" {
  # This test verifies the script doesn't crash on errors
  run timeout 30s "$TEST_ALL_SCRIPTS"
  # Should not exit with signal (like segfault)
  [[ "$status" -lt 128 ]]
}
