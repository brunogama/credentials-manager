#!/usr/bin/env bats

load test_helper.bash
load ../lib/atomic.sh

# Setup and teardown
setup() {
  TEST_DIR="$(mktemp -d)"
  TEST_FILE="${TEST_DIR}/test_file"
  export TEST_DIR TEST_FILE
}

teardown() {
  rm -rf "$TEST_DIR"
}

# Test atomic_write basic functionality
@test "atomic_write creates file with correct content" {
  echo "test content" | atomic_write "$TEST_FILE"

  # Verify file exists and has correct content
  [ -f "$TEST_FILE" ]
  run cat "$TEST_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "test content" ]
}

# Test file permissions
@test "atomic_write creates file with secure permissions" {
  echo "test content" | atomic_write "$TEST_FILE"

  # Check permissions (600)
  run stat -f "%Lp" "$TEST_FILE" 2>/dev/null || stat -c "%a" "$TEST_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "600" ]
}

# Test atomic operation
@test "atomic_write operation is atomic" {
  # Create test data (10KB of 'x' characters)
  local test_size=10240
  local large_content
  large_content=$(printf '%*s' "$test_size" | tr ' ' 'x')

  # Start writing in background
  echo -n "$large_content" | atomic_write "$TEST_FILE" &
  local write_pid=$!

  # Try to read file immediately
  local partial_read=0
  while kill -0 $write_pid 2>/dev/null; do
    if [ -f "$TEST_FILE" ]; then
      local size
      size=$(wc -c < "$TEST_FILE" 2>/dev/null || echo "0")
      if [ "$size" -gt 0 ] && [ "$size" -lt "$test_size" ]; then
        partial_read=1
        break
      fi
    fi
    sleep 0.1
  done

  # Wait for write to complete
  wait $write_pid

  # Verify no partial content was ever visible
  [ "$partial_read" -eq 0 ]

  # Get file size
  local actual_size
  actual_size=$(wc -c < "$TEST_FILE")

  # Verify final content length
  [ "$actual_size" -eq "$test_size" ]

  # Verify content is correct (all 'x' characters)
  local file_content
  file_content=$(cat "$TEST_FILE")
  local expected_content
  expected_content=$(printf '%*s' "$test_size" | tr ' ' 'x')
  [ "$file_content" = "$expected_content" ]
}

# Test error handling
@test "atomic_write fails on invalid directory" {
  run bash -c "source $PROJECT_ROOT/lib/atomic.sh && echo 'test' | atomic_write '/nonexistent/file'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: Target directory '/nonexistent' does not exist or is not writable"* ]]
}

# Test concurrent writes
@test "atomic_write handles concurrent writes correctly" {
  # Start multiple concurrent writes
  for i in {1..5}; do
    echo "content $i" | atomic_write "$TEST_FILE" &
  done

  # Wait for all writes to complete
  wait

  # Verify file exists and has content from one of the writes
  [ -f "$TEST_FILE" ]
  run cat "$TEST_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^content\ [1-5]$ ]]
}
