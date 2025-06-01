# Atomic File Operations

This module provides atomic file operations for secure file handling in the credentials management system.

## Functions

### atomic_write

Writes content to a file atomically, ensuring that the operation is either completely successful or fails without corrupting the target file.

```bash
# Usage
echo "content" | atomic_write "/path/to/file"
```

#### Features

- Atomic write operation using temporary files
- Secure file permissions (600)
- Directory existence and permission checks
- Proper error handling and reporting
- Safe cleanup of temporary files

#### Error Handling

The function will return non-zero and output an error message to stderr in the following cases:
- No target file specified
- Target directory doesn't exist
- Target directory is not writable
- Temporary file creation fails
- Write operation fails
- Move operation fails

#### Example

```bash
# Write content to a file
echo "sensitive data" | atomic_write "/path/to/credentials"

# Check return status
if [ $? -eq 0 ]; then
  echo "Write successful"
else
  echo "Write failed"
fi
```
