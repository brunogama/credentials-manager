#!/usr/bin/env bash

# Atomic file operations module
# Provides functions for atomic file operations with proper permission handling

# shellcheck disable=SC2034
ATOMIC_VERSION="1.0.0"

# Write content to a file atomically
# Usage: echo "content" | atomic_write "/path/to/file"
atomic_write() {
  local target_file="$1"
  local target_dir
  local temp_file
  local exit_code=0

  # Validate input
  if [ -z "$target_file" ]; then
    echo "Error: No target file specified" >&2
    return 1
  fi

  # Get target directory
  target_dir=$(dirname "$target_file")

  # Check if target directory exists and is writable
  if [ ! -d "$target_dir" ] || [ ! -w "$target_dir" ]; then
    echo "Error: Target directory '$target_dir' does not exist or is not writable" >&2
    return 1
  fi

  # Create temporary file in the same directory as target
  # This ensures atomic move operation works across filesystems
  temp_file=$(mktemp "${target_dir}/.atomic_write.XXXXXX") || {
    echo "Error: Failed to create temporary file" >&2
    return 1
  }

  # Ensure temporary file has secure permissions before writing content
  chmod 600 "$temp_file" || {
    rm -f "$temp_file"
    echo "Error: Failed to set permissions on temporary file" >&2
    return 1
  }

  # Read from stdin and write to temporary file
  # Using dd to avoid any line buffering issues
  dd bs=4096 of="$temp_file" status=none || {
    exit_code=$?
    rm -f "$temp_file"
    echo "Error: Failed to write content to temporary file" >&2
    return $exit_code
  }

  # Atomically move temporary file to target
  mv -f "$temp_file" "$target_file" || {
    exit_code=$?
    rm -f "$temp_file"
    echo "Error: Failed to move temporary file to target" >&2
    return $exit_code
  }

  # Verify final permissions
  if ! chmod 600 "$target_file" 2>/dev/null; then
    echo "Warning: Failed to verify final file permissions" >&2
    # Don't fail the operation as the file was written successfully
  fi

  return 0
}
