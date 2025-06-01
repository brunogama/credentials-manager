# Credentials Storage and Management

A secure command-line tool suite for managing API keys and credentials locally.

## Features

- Store API keys securely with service identifiers
- Retrieve stored API keys
- List all stored API keys
- Pattern matching for finding specific API keys
- Secure storage with encryption (planned)

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/credentials-storage-and-management
cd credentials-storage-and-management

# Run tests to verify everything works
make test
```

## Usage

### Store an API Key
```bash
./store-api-key SERVICE_NAME API_KEY
```

### Retrieve an API Key
```bash
./get-api-key SERVICE_NAME
```

### List All API Keys
```bash
./dump-api-keys
```

### Find API Keys by Pattern
```bash
./credmatch PATTERN
```

## Development

### Prerequisites
- Bash 4.0+
- [bats](https://github.com/bats-core/bats-core) for testing
- [shellcheck](https://github.com/koalaman/shellcheck) for linting
- [pre-commit](https://pre-commit.com/) for git hooks

### Setup Development Environment
```bash
# Install pre-commit hooks
make setup-pre-commit

# Run tests
make test

# Run linting
make lint

# Run pre-commit checks manually
make run-pre-commit
```

## Roadmap

### Version 1.1 (Next Release)
- [ ] Add encryption support for stored credentials
- [ ] Implement secure password-based key derivation
- [ ] Add backup/restore functionality

### Version 1.2
- [ ] Add support for different credential types (tokens, certificates)
- [ ] Implement credential rotation policies
- [ ] Add expiration date tracking

### Version 1.3
- [ ] Add support for cloud storage sync (optional)
- [ ] Implement credential sharing mechanisms
- [ ] Add audit logging

### Version 2.0
- [ ] GUI interface (TUI/CLI)
- [ ] Integration with popular credential managers
- [ ] Plugin system for custom storage backends

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests and ensure they pass (`make test`)
4. Commit your changes (`git commit -m 'feat: add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## Testing

The project uses [bats](https://github.com/bats-core/bats-core) for testing. All scripts have corresponding test files in the `tests/` directory.

```bash
# Run all tests
make test

# Run specific test file
bats tests/test-file.bats
```

## Security

This tool is designed for local credential management. While we strive to implement secure practices:
- Credentials are stored locally
- Future versions will include encryption
- No credentials are transmitted over the network

## License

MIT License - See LICENSE file for details
