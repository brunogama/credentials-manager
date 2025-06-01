#!/usr/bin/env bats
# credmatch_basic.bats - Basic tests for credmatch script

load test_helper

CREDMATCH_SCRIPT="${PROJECT_ROOT}/credmatch"

@test "credmatch script exists and is executable" {
  assert_script_exists "$CREDMATCH_SCRIPT"
}

@test "credmatch script has valid bash syntax" {
  check_script_syntax "$CREDMATCH_SCRIPT"
}

@test "credmatch script passes shellcheck" {
  check_script_shellcheck "$CREDMATCH_SCRIPT"
}

@test "credmatch shows usage when no arguments provided" {
  run "$CREDMATCH_SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "credmatch shows usage with --help flag" {
  run "$CREDMATCH_SCRIPT" --help
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "credmatch shows error for unknown command" {
  run "$CREDMATCH_SCRIPT" unknown-command
  [ "$status" -eq 1 ]
}

@test "credmatch init requires git repository URL" {
  run "$CREDMATCH_SCRIPT" init
  [ "$status" -eq 1 ]
}

@test "credmatch store requires key and value" {
  run "$CREDMATCH_SCRIPT" store
  [ "$status" -eq 1 ]
}

@test "credmatch fetch requires key" {
  run "$CREDMATCH_SCRIPT" fetch
  [ "$status" -eq 1 ]
}