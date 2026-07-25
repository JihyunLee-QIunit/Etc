#!/usr/bin/env bash
#
# install.sh — install popular AI coding CLI tools.
#
# Usage:
#   ./scripts/install.sh --tool <name> [--dry-run] [--yes]
#   ./scripts/install.sh --list
#   ./scripts/install.sh --help
#
# Supported tools:
#   claude-code   Anthropic Claude Code       (npm: @anthropic-ai/claude-code)
#   codex         OpenAI Codex CLI            (npm: @openai/codex)
#   gemini-cli    Google Gemini CLI          (npm: @google/gemini-cli)
#   aider         Aider AI pair programmer   (pip: aider-chat)
#   windsurf      Codeium Windsurf editor    (brew cask / apt / download)
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Globals
# ---------------------------------------------------------------------------
SCRIPT_NAME="$(basename "$0")"
TOOL=""
DRY_RUN=0
ASSUME_YES=0

SUPPORTED_TOOLS=(claude-code codex gemini-cli aider windsurf)

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  C_RESET="$(printf '\033[0m')"
  C_BOLD="$(printf '\033[1m')"
  C_RED="$(printf '\033[31m')"
  C_GREEN="$(printf '\033[32m')"
  C_YELLOW="$(printf '\033[33m')"
  C_BLUE="$(printf '\033[34m')"
else
  C_RESET="" C_BOLD="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE=""
fi

info()  { printf '%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()    { printf '%s✓%s %s\n'  "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf '%s!%s %s\n'  "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()   { printf '%s✗%s %s\n'  "$C_RED" "$C_RESET" "$*" >&2; }

die() { err "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
${C_BOLD}${SCRIPT_NAME}${C_RESET} — install AI coding CLI tools

${C_BOLD}Usage:${C_RESET}
  ./scripts/install.sh --tool <name> [options]
  ./scripts/install.sh --list
  ./scripts/install.sh --help

${C_BOLD}Options:${C_RESET}
  --tool <name>   Tool to install (see list below)
  --list          List supported tools and exit
  --dry-run       Print the commands that would run without executing them
  --yes, -y       Do not prompt for confirmation
  --help, -h      Show this help and exit

${C_BOLD}Supported tools:${C_RESET}
  claude-code     Anthropic Claude Code
  codex           OpenAI Codex CLI
  gemini-cli      Google Gemini CLI
  aider           Aider AI pair programmer
  windsurf        Codeium Windsurf editor

${C_BOLD}Examples:${C_RESET}
  ./scripts/install.sh --tool claude-code
  ./scripts/install.sh --tool aider --dry-run
EOF
}

list_tools() {
  printf '%s\n' "${SUPPORTED_TOOLS[@]}"
}

# ---------------------------------------------------------------------------
# Environment detection
# ---------------------------------------------------------------------------
detect_os() {
  case "$(uname -s)" in
    Linux*)  echo "linux" ;;
    Darwin*) echo "macos" ;;
    CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
    *)       echo "unknown" ;;
  esac
}

has() { command -v "$1" >/dev/null 2>&1; }

# Run a command, honoring --dry-run.
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%s[dry-run]%s %s\n' "$C_YELLOW" "$C_RESET" "$*"
    return 0
  fi
  info "$*"
  "$@"
}

confirm() {
  [ "$ASSUME_YES" -eq 1 ] && return 0
  [ "$DRY_RUN" -eq 1 ] && return 0
  local prompt="$1"
  printf '%s [y/N] ' "$prompt"
  local reply
  read -r reply || true
  case "$reply" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Prerequisite helpers
# ---------------------------------------------------------------------------
require_npm() {
  if ! has npm; then
    die "npm is required but not found. Install Node.js (https://nodejs.org) first."
  fi
}

# Pick the best available Python package installer command.
pip_installer() {
  if has uv; then
    echo "uv tool install"
  elif has pipx; then
    echo "pipx install"
  elif has pip3; then
    echo "pip3 install --user"
  elif has pip; then
    echo "pip install --user"
  else
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Per-tool installers
# ---------------------------------------------------------------------------
install_claude_code() {
  require_npm
  info "Installing Claude Code via npm…"
  run npm install -g @anthropic-ai/claude-code
  ok "Claude Code installed. Run 'claude' to get started."
}

install_codex() {
  require_npm
  info "Installing OpenAI Codex CLI via npm…"
  run npm install -g @openai/codex
  ok "Codex CLI installed. Run 'codex' to get started."
}

install_gemini_cli() {
  require_npm
  info "Installing Google Gemini CLI via npm…"
  run npm install -g @google/gemini-cli
  ok "Gemini CLI installed. Run 'gemini' to get started."
}

install_aider() {
  local installer
  if ! installer="$(pip_installer)"; then
    die "No Python installer found. Install one of: uv, pipx, or pip (with Python 3)."
  fi
  info "Installing Aider via '${installer}'…"
  # shellcheck disable=SC2086
  run $installer aider-chat
  ok "Aider installed. Run 'aider' inside a git repo to get started."
}

install_windsurf() {
  local os
  os="$(detect_os)"
  case "$os" in
    macos)
      if has brew; then
        info "Installing Windsurf via Homebrew…"
        run brew install --cask windsurf
        ok "Windsurf installed. Launch it from Applications or run 'windsurf'."
      else
        warn "Homebrew not found."
        warn "Install Homebrew (https://brew.sh) then re-run, or download Windsurf"
        warn "directly from https://windsurf.com/download"
        return 1
      fi
      ;;
    linux)
      info "Setting up the Windsurf apt repository…"
      if ! has apt-get; then
        warn "This installer supports apt-based Linux distros only."
        warn "Download Windsurf directly from https://windsurf.com/download"
        return 1
      fi
      if [ "$DRY_RUN" -eq 1 ]; then
        printf '%s[dry-run]%s configure apt repo + apt-get install windsurf\n' \
          "$C_YELLOW" "$C_RESET"
        return 0
      fi
      local sudo=""
      [ "$(id -u)" -ne 0 ] && sudo="sudo"
      run bash -c "curl -fsSL 'https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg' \
        | $sudo gpg --dearmor -o /usr/share/keyrings/windsurf-stable-archive-keyring.gpg"
      run bash -c "echo 'deb [signed-by=/usr/share/keyrings/windsurf-stable-archive-keyring.gpg] \
https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main' \
        | $sudo tee /etc/apt/sources.list.d/windsurf.list >/dev/null"
      run $sudo apt-get update
      run $sudo apt-get install -y windsurf
      ok "Windsurf installed. Run 'windsurf' to launch it."
      ;;
    *)
      warn "Automated Windsurf install is not supported on this platform ($os)."
      warn "Download it directly from https://windsurf.com/download"
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
install_tool() {
  local tool="$1"
  case "$tool" in
    claude-code) install_claude_code ;;
    codex)       install_codex ;;
    gemini-cli)  install_gemini_cli ;;
    aider)       install_aider ;;
    windsurf)    install_windsurf ;;
    *)
      err "Unknown tool: '$tool'"
      err "Supported tools: ${SUPPORTED_TOOLS[*]}"
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
main() {
  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --tool)
        [ "$#" -ge 2 ] || die "--tool requires a value"
        TOOL="$2"
        shift 2
        ;;
      --tool=*)
        TOOL="${1#*=}"
        shift
        ;;
      --list)
        list_tools
        exit 0
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --yes|-y)
        ASSUME_YES=1
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        err "Unknown argument: '$1'"
        usage
        exit 1
        ;;
    esac
  done

  [ -n "$TOOL" ] || die "No tool specified. Use --tool <name> or --list."

  # Validate the tool name up front.
  local valid=0
  for t in "${SUPPORTED_TOOLS[@]}"; do
    [ "$t" = "$TOOL" ] && valid=1 && break
  done
  if [ "$valid" -eq 0 ]; then
    err "Unknown tool: '$TOOL'"
    err "Supported tools: ${SUPPORTED_TOOLS[*]}"
    exit 1
  fi

  if ! confirm "Install '${TOOL}'?"; then
    warn "Aborted."
    exit 1
  fi

  install_tool "$TOOL"
}

main "$@"
