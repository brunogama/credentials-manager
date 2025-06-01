#!/usr/bin/env bats

load tests/test_helper

@test "debug stderr capture" {
  run ./get-api-key TEST_API_KEY
  echo "Status: $status"
  echo "Output: $output"
  echo "Lines: ${#lines[@]}"
  for i in "${!lines[@]}"; do
    echo "Line $i: ${lines[$i]}"
  done
}
