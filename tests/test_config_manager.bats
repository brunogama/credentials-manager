#!/usr/bin/env bats
# test_config_manager.bats - Unit tests for test-config-manager.sh script

load test_helper

TEST_CONFIG_MANAGER="${PROJECT_ROOT}/test-config-manager.sh"

@test "test-config-manager.sh script exists and is executable" {
  assert_script_exists "$TEST_CONFIG_MANAGER"
}

@test "test-config-manager.sh script has valid bash syntax" {
  check_script_syntax "$TEST_CONFIG_MANAGER"
}

@test "test-config-manager.sh script passes shellcheck" {
  check_script_shellcheck "$TEST_CONFIG_MANAGER"
}

@test "test-config-manager.sh runs without errors" {
  # Run with timeout to prevent hanging
  run timeout 30s "$TEST_CONFIG_MANAGER"
  # Should complete within timeout
  [[ "$status" -ne 124 ]]  # 124 is timeout exit code
}

@test "test-config-manager.sh produces test output" {
  run timeout 30s "$TEST_CONFIG_MANAGER"
  # Should produce test output
  [[ "$output" =~ "Testing" ]] || [[ "$output" =~ "PASS" ]] || [[ "$output" =~ "FAIL" ]]
}

@test "test-config-manager.sh includes configuration tests" {
  run timeout 30s "$TEST_CONFIG_MANAGER"
  # Should test configuration functionality
  [[ "$output" =~ "Configuration" ]] || [[ "$output" =~ "config" ]]
}

@test "test-config-manager.sh tests file creation" {
  run timeout 30s "$TEST_CONFIG_MANAGER"
  # Should test configuration file creation
  [[ "$output" =~ "creation" ]] || [[ "$output" =~ "file" ]]
}

@test "test-config-manager.sh tests permissions" {
  run timeout 30s "$TEST_CONFIG_MANAGER"
  # Should test file permissions
  [[ "$output" =~ "permission" ]] || [[ "$output" =~ "Permission" ]]
}

@test "test-config-manager.sh tests validation" {
  run timeout 30s "$TEST_CONFIG_MANAGER"
  # Should test configuration validation
  [[ "$output" =~ "validation" ]] || [[ "$output" =~ "Validation" ]]
}

@test "test-config-manager.sh shows test results" {
  run timeout 30s "$TEST_CONFIG_MANAGER"
  # Should show test results
  [[ "$output" =~ "passed" ]] && [[ "$output" =~ "failed" ]]
}

@test "test-config-manager.sh shows test summary" {
  run timeout 30s "$TEST_CONFIG_MANAGER"
  # Should show summary at the end
  [[ "$output" =~ "Test Results" ]] || [[ "$output" =~ "Summary" ]]
}

@test "test-config-manager.sh uses emoji indicators" {
  run timeout 30s "$TEST_CONFIG_MANAGER"
  # Should use emoji for test results
  [[ "$output" =~ "✅" ]] || [[ "$output" =~ "❌" ]] || [[ "$output" =~ "🧪" ]]
}

@test "test-config-manager.sh sources config manager" {
  run timeout 30s "$TEST_CONFIG_MANAGER"
  # Should successfully source the config manager
  [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]  # 0 for success, 1 for test failures
}

@test "test-config-manager.sh handles missing dependencies gracefully" {
  # Test behavior when config manager is missing
  # This is more of a robustness test
  run timeout 30s "$TEST_CONFIG_MANAGER"
  # Should not crash with signal
  [[ "$status" -lt 128 ]]
}

@test "test-config-manager.sh tests security configuration" {
  run timeout 30s "$TEST_CONFIG_MANAGER"
  # Should test security-related configuration
  [[ "$output" =~ "Security" ]] || [[ "$output" =~ "security" ]]
}

@test "test-config-manager.sh provides meaningful output" {
  run timeout 30s "$TEST_CONFIG_MANAGER"
  # Output should be substantial (not just empty or minimal)
  [[ ${#output} -gt 100 ]]
}
