#!/usr/bin/env bash
# =============================================================================
# Claude Code — Setup Script
# Configures MCPs and dependencies on any machine (Windows/Linux/Mac)
# Usage: cd ~/.claude && ./setup.sh
# =============================================================================

set -euo pipefail

CLAUDE_DIR="$(cd "$(dirname "$0")" && pwd)"
MCP_DIR="$CLAUDE_DIR/mcp-servers"
TEMPLATE="$CLAUDE_DIR/mcp-template.jsonc"
SECRETS_FILE="$CLAUDE_DIR/.mcp-secrets"
TARGET="$HOME/.claude.json"

# --- Colors ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }
info() { echo -e "  ${CYAN}→${NC} $1"; }

# --- Detect OS ---
detect_os() {
    case "$(uname -s)" in
        Linux*)   OS="linux";;
        Darwin*)  OS="mac";;
        MINGW*|MSYS*|CYGWIN*) OS="windows";;
        *)        OS="unknown";;
    esac

    if [ "$OS" = "windows" ]; then
        VENV_BIN="Scripts"
        EXE=".exe"
        HOME_NATIVE="C:/Users/$(whoami)"
    else
        VENV_BIN="bin"
        EXE=""
        HOME_NATIVE="$HOME"
    fi

    echo ""
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Claude Code Setup — OS: ${OS}${NC}"
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    echo ""
    info "Home: $HOME"
    info "Claude dir: $CLAUDE_DIR"
    info "Venv bin: $VENV_BIN"
    echo ""
}

# --- Secrets ---
# Edit the SECRETS array below to match your MCP secrets.
# Each entry: "VARIABLE_NAME|Human-readable label"
SECRETS=(
    "MY_API_KEY|My API Key"
    "ANOTHER_SECRET|Another service password"
)

load_or_ask_secrets() {
    echo -e "${CYAN}[1/4] Secrets${NC}"

    if [ -f "$SECRETS_FILE" ]; then
        source "$SECRETS_FILE"
        ok "Secrets loaded from .mcp-secrets"
    else
        warn ".mcp-secrets not found — creating interactively"
        echo ""
    fi

    for entry in "${SECRETS[@]}"; do
        local var_name="${entry%%|*}"
        local label="${entry##*|}"
        ask_secret "$var_name" "$label"
    done

    # Save secrets file
    {
        echo "# MCP Secrets — DO NOT commit this file"
        for entry in "${SECRETS[@]}"; do
            local var_name="${entry%%|*}"
            local val="${!var_name:-}"
            echo "${var_name}=\"${val}\""
        done
    } > "$SECRETS_FILE"
    chmod 600 "$SECRETS_FILE"
    ok "Secrets saved to .mcp-secrets"
    echo ""
}

ask_secret() {
    local var_name="$1"
    local label="$2"
    local current_val="${!var_name:-}"

    if [ -n "$current_val" ]; then
        ok "$label: already configured"
    else
        read -rp "  ? $label: " input_val
        if [ -z "$input_val" ]; then
            warn "$label: empty (MCP may fail)"
            eval "$var_name=''"
        else
            eval "$var_name='$input_val'"
            ok "$label: saved"
        fi
    fi
}

# --- Generate .claude.json ---
generate_config() {
    echo -e "${CYAN}[2/4] Generating .claude.json${NC}"

    if [ ! -f "$TEMPLATE" ]; then
        fail "Template not found: $TEMPLATE"
        exit 1
    fi

    # Read template, strip comments, replace placeholders
    local content
    content=$(grep -v '^\s*//' "$TEMPLATE")

    # OS placeholders
    content="${content//\{\{HOME\}\}/$HOME}"
    content="${content//\{\{HOME_NATIVE\}\}/$HOME_NATIVE}"
    content="${content//\{\{VENV_BIN\}\}/$VENV_BIN}"
    content="${content//\{\{EXE\}\}/$EXE}"

    # Secret placeholders
    for entry in "${SECRETS[@]}"; do
        local var_name="${entry%%|*}"
        local val="${!var_name:-}"
        content="${content//\{\{${var_name}\}\}/$val}"
    done

    # Merge with existing .claude.json or create new
    if [ -f "$TARGET" ]; then
        info "Merging with existing .claude.json..."

        python_cmd="python3"
        command -v python3 >/dev/null 2>&1 || python_cmd="py"

        echo "$content" | $python_cmd -c "
import sys, json

new_config = json.load(sys.stdin)
with open('$TARGET', 'r') as f:
    existing = json.load(f)

existing['mcpServers'] = new_config.get('mcpServers', {})

for proj_key, proj_val in new_config.get('projects', {}).items():
    if proj_key in existing.get('projects', {}):
        existing['projects'][proj_key].setdefault('mcpServers', {})
        existing['projects'][proj_key]['mcpServers'].update(proj_val.get('mcpServers', {}))
    else:
        existing.setdefault('projects', {})[proj_key] = proj_val

with open('$TARGET', 'w') as f:
    json.dump(existing, f, indent=2)
"
        ok ".claude.json updated (existing fields preserved)"
    else
        echo "$content" > "$TARGET"
        ok ".claude.json created"
    fi
    echo ""
}

# --- Install dependencies ---
# Edit the calls below to match your MCP servers.
install_deps() {
    echo -e "${CYAN}[3/4] Checking MCP dependencies${NC}"

    # Node MCPs: install_node_mcp "dir-name" "npm-package-name"
    install_node_mcp "memory" "@modelcontextprotocol/server-memory"
    install_node_mcp "sequential-thinking" "@modelcontextprotocol/server-sequential-thinking"

    # Python MCPs: install_python_mcp "dir-name" "requirements.txt|pyproject.toml"
    # install_python_mcp "my-python-mcp" "requirements.txt"

    echo ""
}

install_node_mcp() {
    local name="$1"
    local pkg="$2"
    local dir="$MCP_DIR/$name"

    if [ -d "$dir/node_modules" ]; then
        ok "$name: node_modules exists"
    elif [ -f "$dir/package.json" ]; then
        info "$name: running npm install..."
        (cd "$dir" && npm install --silent 2>&1) && ok "$name: installed" || fail "$name: npm install failed"
    else
        warn "$name: no package.json — creating and installing $pkg"
        mkdir -p "$dir"
        (cd "$dir" && npm init -y --silent 2>/dev/null && npm install "$pkg" --silent 2>&1) && ok "$name: installed" || fail "$name: failed"
    fi
}

install_python_mcp() {
    local name="$1"
    local deps_file="$2"
    local dir="$MCP_DIR/$name"
    local venv_dir="$dir/venv"

    if [ ! -d "$dir" ]; then
        warn "$name: directory not found — skipping"
        return
    fi

    if [ -d "$venv_dir" ]; then
        ok "$name: venv exists"
    else
        info "$name: creating venv..."
        python_cmd="python3"
        command -v python3 >/dev/null 2>&1 || python_cmd="py"
        $python_cmd -m venv "$venv_dir" && ok "$name: venv created" || { fail "$name: venv failed"; return; }

        local pip="$venv_dir/$VENV_BIN/pip"
        if [ "$deps_file" = "pyproject.toml" ]; then
            info "$name: installing via pyproject.toml..."
            (cd "$dir" && "$pip" install -e . --quiet 2>&1) && ok "$name: deps installed" || fail "$name: pip install failed"
        elif [ -f "$dir/$deps_file" ]; then
            info "$name: installing via $deps_file..."
            "$pip" install -r "$dir/$deps_file" --quiet 2>&1 && ok "$name: deps installed" || fail "$name: pip install failed"
        fi
    fi
}

# --- Verify external services ---
verify_services() {
    echo -e "${CYAN}[4/4] Checking external services${NC}"

    # Add your own checks here. Examples:
    # check_file "$MCP_DIR/ms365/node_modules/.../token-cache.json" "ms365 token cache"
    # check_file "$MCP_DIR/youtube-music/oauth.json" "YouTube Music auth"

    info "Add service checks to verify_services() in setup.sh"
    echo ""
}

# --- Main ---
main() {
    detect_os
    load_or_ask_secrets
    generate_config
    install_deps
    verify_services

    echo -e "${GREEN}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Setup complete!${NC}"
    echo -e "${GREEN}══════════════════════════════════════════${NC}"
    echo ""
    info "Restart Claude Code to load the MCPs."
    echo ""
}

main "$@"
