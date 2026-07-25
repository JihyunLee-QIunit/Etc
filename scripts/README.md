# CLI tool install scripts

`install.sh` installs popular AI coding CLI tools with a single command.

## Usage

```sh
./scripts/install.sh --tool <name> [options]
```

Options:

| Option        | Description                                          |
| ------------- | ---------------------------------------------------- |
| `--tool NAME` | Tool to install (required)                           |
| `--list`      | List supported tools and exit                        |
| `--dry-run`   | Print the commands that would run without running them |
| `--yes`, `-y` | Skip the confirmation prompt                         |
| `--help`, `-h`| Show help and exit                                   |

## Supported tools

### Claude Code
```sh
./scripts/install.sh --tool claude-code
```

### Codex CLI
```sh
./scripts/install.sh --tool codex
```

### Gemini CLI
```sh
./scripts/install.sh --tool gemini-cli
```

### Aider
```sh
./scripts/install.sh --tool aider
```

### Windsurf
```sh
./scripts/install.sh --tool windsurf
```

## Requirements

- **claude-code**, **codex**, **gemini-cli** — install via `npm`, so
  [Node.js](https://nodejs.org) is required.
- **aider** — installs via `uv`, `pipx`, or `pip` (Python 3), whichever is found
  first.
- **windsurf** — uses Homebrew on macOS and the official apt repository on
  Debian/Ubuntu Linux. On other platforms, download it from
  <https://windsurf.com/download>.
