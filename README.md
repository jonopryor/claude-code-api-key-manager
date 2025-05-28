# Claude API Key Manager

A simple bash-based tool to manage multiple Claude API keys for different projects and easily switch between them.

This has been written so that Claude Code can be more efficiently used with API keys in different Workspaces, without requiring the oauth flow for generating the keys, allowing you to distribute keys you have generated from the Anthropic console individually without providing access to the console. 

The default behaviour of all keys from the oauth flow being in a single "Claude Code" Workspace can make FinOps difficult for organizations using Claude Code. 

## Features

- Store multiple API keys with project names
- Switch between different API keys
- Interactive menu interface
- Command-line interface for scripting
- Secure storage in JSON format
- Masked key display for security

## Files

- `claude-key-manager.sh` - Core functionality and CLI interface
- `menu.sh` - Interactive menu interface

## Setup

1. Make the scripts executable:
   
   ```bash
   chmod +x claude-key-manager.sh menu.sh
   ```

2. Run the interactive menu:
   
   ```bash
   ./menu.sh
   ```

## Usage

### Interactive Menu

Run `./menu.sh` to access the full interactive interface with options to:

1. List all saved keys
2. Add a new key
3. Remove a key
4. Switch to a different key
5. Show current active key
6. Save current key as default
7. Exit

### Command Line Interface

```bash
# Add a new API key
./claude-key-manager.sh add

# Remove an existing key
./claude-key-manager.sh remove
```

## Storage

- API keys are stored in `~/claude-api-project-keys.json`
- Claude configuration is stored in `~/.claude.json`
- Both files are created automatically if they don't exist

## Security

- Keys are stored in JSON format in your home directory
- The interactive menu displays masked keys (showing only first 8 and last 4 characters)
- No keys are logged or displayed in plain text during normal operation