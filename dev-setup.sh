#!/bin/bash
# =============================================================================
# Developer Environment Setup Script
# One-click setup for: Zsh + Oh My Zsh + Starship + Ghostty + cmux + Catppuccin
# =============================================================================
set -e

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage: dev-setup.sh

Bootstraps a macOS developer terminal environment by installing packages,
fonts, shell plugins, and config files.

This script is idempotent and safe to run multiple times.
EOF
  exit 0
fi

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

step() { echo -e "\n${BOLD}${BLUE}[$1/$TOTAL_STEPS]${NC} ${BOLD}$2${NC}"; }
info() { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }

TOTAL_STEPS=12

echo -e "${BOLD}=======================================${NC}"
echo -e "${BOLD}  Developer Environment Setup${NC}"
echo -e "${BOLD}  Zsh + Starship + Ghostty + cmux + Catppuccin${NC}"
echo -e "${BOLD}=======================================${NC}"

# ─────────────────────────────────────────────────────────────────────────────
step 1 "Installing Homebrew (if needed)"
# ─────────────────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Apple Silicon
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  info "Homebrew installed"
else
  info "Homebrew already installed"
fi

# ─────────────────────────────────────────────────────────────────────────────
step 2 "Installing CLI tools"
# ─────────────────────────────────────────────────────────────────────────────
BREW_PACKAGES=(starship zoxide lazygit delta yazi bat fd ripgrep fzf eza)
for pkg in "${BREW_PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    info "$pkg already installed"
  else
    brew install "$pkg"
    info "$pkg installed"
  fi
done

# Install Ghostty cask
if brew list --cask ghostty &>/dev/null 2>&1 || [[ -d "/Applications/Ghostty.app" ]]; then
  info "Ghostty already installed"
else
  brew install --cask ghostty
  info "Ghostty installed"
fi

# Install cmux (Ghostty-based terminal for AI coding agents)
if brew list --cask cmux &>/dev/null 2>&1 || [[ -d "/Applications/cmux.app" ]]; then
  info "cmux already installed"
else
  brew tap manaflow-ai/cmux 2>/dev/null || true
  brew install --cask cmux
  info "cmux installed"
fi

# ─────────────────────────────────────────────────────────────────────────────
step 3 "Installing Nerd Font (MesloLGS NF)"
# ─────────────────────────────────────────────────────────────────────────────
if fc-list 2>/dev/null | grep -qi "MesloLGS" || ls ~/Library/Fonts/MesloLGS* &>/dev/null 2>&1; then
  info "MesloLGS NF already installed"
else
  FONT_DIR="$HOME/Library/Fonts"
  mkdir -p "$FONT_DIR"
  FONT_BASE="https://github.com/romkatv/powerlevel10k-media/raw/master"
  for variant in "Regular" "Bold" "Italic" "Bold Italic"; do
    FILE="MesloLGS NF ${variant}.ttf"
    URL_FILE=$(echo "$FILE" | sed 's/ /%20/g')
    curl -sL "${FONT_BASE}/${URL_FILE}" -o "${FONT_DIR}/${FILE}"
  done
  info "MesloLGS NF fonts installed"
fi

# ─────────────────────────────────────────────────────────────────────────────
step 4 "Installing Oh My Zsh (if needed)"
# ─────────────────────────────────────────────────────────────────────────────
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  info "Oh My Zsh already installed"
else
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  info "Oh My Zsh installed"
fi

# ─────────────────────────────────────────────────────────────────────────────
step 5 "Installing Zsh plugins"
# ─────────────────────────────────────────────────────────────────────────────
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

PLUGIN_NAMES=(
  "zsh-autosuggestions"
  "zsh-syntax-highlighting"
  "zsh-history-substring-search"
  "you-should-use"
)

PLUGIN_URLS=(
  "https://github.com/zsh-users/zsh-autosuggestions"
  "https://github.com/zsh-users/zsh-syntax-highlighting"
  "https://github.com/zsh-users/zsh-history-substring-search"
  "https://github.com/MichaelAquilina/zsh-you-should-use"
)

for i in "${!PLUGIN_NAMES[@]}"; do
  plugin="${PLUGIN_NAMES[$i]}"
  plugin_url="${PLUGIN_URLS[$i]}"
  if [[ -d "$ZSH_CUSTOM/plugins/$plugin" ]]; then
    info "$plugin already installed"
  else
    git clone "$plugin_url" "$ZSH_CUSTOM/plugins/$plugin"
    info "$plugin installed"
  fi
done

# ─────────────────────────────────────────────────────────────────────────────
step 6 "Configuring Zsh (.zshrc)"
# ─────────────────────────────────────────────────────────────────────────────
# Backup existing .zshrc
if [[ -f "$HOME/.zshrc" ]]; then
  cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
  warn "Backed up existing .zshrc"
fi

cat > "$HOME/.zshrc" << 'ZSHRC'
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme — disabled, Starship handles the prompt
ZSH_THEME=""

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search zsh-history-substring-search you-should-use)
source $ZSH/oh-my-zsh.sh

# Limit syntax highlighting to prevent input lag on long commands
ZSH_HIGHLIGHT_MAXLENGTH=200

# Language
export LANG=en_US.UTF-8

# User-local binaries
export PATH="$HOME/.local/bin:$PATH"

# ──────────────────────────────────────────────
# JDK Switcher — usage: jdk8, jdk17, jdk19, jdks
# ──────────────────────────────────────────────
_jdk_base=/Library/Java/JavaVirtualMachines
if [[ -d "$_jdk_base" ]]; then
  # Set default JAVA_HOME to first available JDK
  for jdk in zulu-8.jdk zulu-17.jdk zulu-19.jdk; do
    if [[ -d "$_jdk_base/$jdk" ]]; then
      export JAVA_HOME="$_jdk_base/$jdk/Contents/Home"
      break
    fi
  done
  jdk8()  { [[ -d "$_jdk_base/zulu-8.jdk" ]]  && export JAVA_HOME=$_jdk_base/zulu-8.jdk/Contents/Home  && export PATH="$JAVA_HOME/bin:${PATH##*jdk*/Contents/Home/bin:}" && java -version 2>&1 | head -1 || echo "JDK 8 not installed"; }
  jdk17() { [[ -d "$_jdk_base/zulu-17.jdk" ]] && export JAVA_HOME=$_jdk_base/zulu-17.jdk/Contents/Home && export PATH="$JAVA_HOME/bin:${PATH##*jdk*/Contents/Home/bin:}" && java -version 2>&1 | head -1 || echo "JDK 17 not installed"; }
  jdk19() { [[ -d "$_jdk_base/zulu-19.jdk" ]] && export JAVA_HOME=$_jdk_base/zulu-19.jdk/Contents/Home && export PATH="$JAVA_HOME/bin:${PATH##*jdk*/Contents/Home/bin:}" && java -version 2>&1 | head -1 || echo "JDK 19 not installed"; }
  jdks()  { echo "Installed JDKs:"; ls $_jdk_base 2>/dev/null; echo "\nActive: $JAVA_HOME"; }
fi

# ──────────────────────────────────────────────
# Maven
# ──────────────────────────────────────────────
if [[ -d "/Library/apache-maven-3.6.3" ]]; then
  export M2_HOME=/Library/apache-maven-3.6.3
  PATH=${M2_HOME}/bin:${PATH}
fi

# ──────────────────────────────────────────────
# dotnet
# ──────────────────────────────────────────────
[[ -d "/usr/local/share/dotnet" ]] && PATH=/usr/local/share/dotnet:${PATH}
export PATH

# ──────────────────────────────────────────────
# SBT
# ──────────────────────────────────────────────
if [[ -d "/Library/sbt" ]]; then
  export SBT_HOME=/Library/sbt
  export PATH=${SBT_HOME}/bin:${PATH}
fi

# ──────────────────────────────────────────────
# Lazy-load NVM — only initializes when you first use node/npm/nvm/npx
# ──────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
if [[ -d "$NVM_DIR" ]]; then
  lazy_load_nvm() {
    unset -f nvm node npm npx
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  }
  nvm() { lazy_load_nvm && nvm "$@"; }
  node() { lazy_load_nvm && node "$@"; }
  npm() { lazy_load_nvm && npm "$@"; }
  npx() { lazy_load_nvm && npx "$@"; }
fi

# ──────────────────────────────────────────────
# Rancher Desktop
# ──────────────────────────────────────────────
[[ -d "$HOME/.rd/bin" ]] && export PATH="$HOME/.rd/bin:$PATH"

# ──────────────────────────────────────────────
# SDKMAN (must be near end of file)
# ──────────────────────────────────────────────
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# ──────────────────────────────────────────────
# Azure CLI completion
# ──────────────────────────────────────────────
if command -v brew &>/dev/null && [[ -f "$(brew --prefix)/etc/bash_completion.d/az" ]]; then
  autoload bashcompinit && bashcompinit
  source "$(brew --prefix)/etc/bash_completion.d/az"
fi

# ──────────────────────────────────────────────
# TUI tool aliases and settings
# ──────────────────────────────────────────────
alias lg="lazygit"
export BAT_THEME="Catppuccin Mocha"

# ──────────────────────────────────────────────
# Starship prompt + Zoxide (must be at end)
# ──────────────────────────────────────────────
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
ZSHRC

info ".zshrc configured"

# ─────────────────────────────────────────────────────────────────────────────
step 7 "Configuring Starship (Catppuccin Powerline)"
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config"

cat > "$HOME/.config/starship.toml" << 'STARSHIP'
"$schema" = 'https://starship.rs/config-schema.json'

format = """
[](red)\
$os\
$username\
[](bg:peach fg:red)\
$directory\
[](bg:yellow fg:peach)\
$git_branch\
$git_status\
[](fg:yellow bg:green)\
$c\
$rust\
$golang\
$nodejs\
$php\
$java\
$kotlin\
$haskell\
$python\
[](fg:green bg:sapphire)\
$conda\
[](fg:sapphire bg:blue)\
$azure\
[](fg:blue bg:lavender)\
$time\
[ ](fg:lavender)\
$cmd_duration\
$line_break\
$character"""

palette = 'catppuccin_mocha'

[os]
disabled = false
style = "bg:red fg:crust"

[os.symbols]
Windows = ""
Ubuntu = "󰕈"
SUSE = ""
Raspbian = "󰐿"
Mint = "󰣭"
Macos = "󰀵"
Manjaro = ""
Linux = "󰌽"
Gentoo = "󰣨"
Fedora = "󰣛"
Alpine = ""
Amazon = ""
Android = ""
AOSC = ""
Arch = "󰣇"
Artix = "󰣇"
CentOS = ""
Debian = "󰣚"
Redhat = "󱄛"
RedHatEnterprise = "󱄛"

[username]
show_always = true
style_user = "bg:red fg:crust"
style_root = "bg:red fg:crust"
format = '[ $user]($style)'

[directory]
style = "bg:peach fg:crust"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = "󰝚 "
"Pictures" = " "
"Developer" = "󰲋 "

[git_branch]
symbol = ""
style = "bg:yellow"
format = '[[ $symbol $branch ](fg:crust bg:yellow)]($style)'

[git_status]
style = "bg:yellow"
format = '[[($all_status$ahead_behind )](fg:crust bg:yellow)]($style)'

[nodejs]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[c]
symbol = " "
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[rust]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[golang]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[php]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[java]
symbol = " "
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[kotlin]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[haskell]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[python]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version)(\(#$virtualenv\)) ](fg:crust bg:green)]($style)'

[docker_context]
symbol = ""
style = "bg:sapphire"
format = '[[ $symbol( $context) ](fg:crust bg:sapphire)]($style)'

[conda]
symbol = "  "
style = "fg:crust bg:sapphire"
format = '[$symbol$environment ]($style)'
ignore_base = false

[azure]
disabled = false
style = "bg:blue"
format = '[[ 󰠅 $subscription ](fg:crust bg:blue)]($style)'

[time]
disabled = false
time_format = "%R"
style = "bg:lavender"
format = '[[  $time ](fg:crust bg:lavender)]($style)'

[line_break]
disabled = false

[character]
disabled = false
success_symbol = '[❯](bold fg:green)'
error_symbol = '[❯](bold fg:red)'
vimcmd_symbol = '[❮](bold fg:green)'
vimcmd_replace_one_symbol = '[❮](bold fg:lavender)'
vimcmd_replace_symbol = '[❮](bold fg:lavender)'
vimcmd_visual_symbol = '[❮](bold fg:yellow)'

[cmd_duration]
show_milliseconds = true
format = " in $duration "
style = "bg:lavender"
disabled = false
show_notifications = true
min_time_to_notify = 45000

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
flamingo = "#f2cdcd"
pink = "#f5c2e7"
mauve = "#cba6f7"
red = "#f38ba8"
maroon = "#eba0ac"
peach = "#fab387"
yellow = "#f9e2af"
green = "#a6e3a1"
teal = "#94e2d5"
sky = "#89dceb"
sapphire = "#74c7ec"
blue = "#89b4fa"
lavender = "#b4befe"
text = "#cdd6f4"
subtext1 = "#bac2de"
subtext0 = "#a6adc8"
overlay2 = "#9399b2"
overlay1 = "#7f849c"
overlay0 = "#6c7086"
surface2 = "#585b70"
surface1 = "#45475a"
surface0 = "#313244"
base = "#1e1e2e"
mantle = "#181825"
crust = "#11111b"

[palettes.catppuccin_frappe]
rosewater = "#f2d5cf"
flamingo = "#eebebe"
pink = "#f4b8e4"
mauve = "#ca9ee6"
red = "#e78284"
maroon = "#ea999c"
peach = "#ef9f76"
yellow = "#e5c890"
green = "#a6d189"
teal = "#81c8be"
sky = "#99d1db"
sapphire = "#85c1dc"
blue = "#8caaee"
lavender = "#babbf1"
text = "#c6d0f5"
subtext1 = "#b5bfe2"
subtext0 = "#a5adce"
overlay2 = "#949cbb"
overlay1 = "#838ba7"
overlay0 = "#737994"
surface2 = "#626880"
surface1 = "#51576d"
surface0 = "#414559"
base = "#303446"
mantle = "#292c3c"
crust = "#232634"

[palettes.catppuccin_latte]
rosewater = "#dc8a78"
flamingo = "#dd7878"
pink = "#ea76cb"
mauve = "#8839ef"
red = "#d20f39"
maroon = "#e64553"
peach = "#fe640b"
yellow = "#df8e1d"
green = "#40a02b"
teal = "#179299"
sky = "#04a5e5"
sapphire = "#209fb5"
blue = "#1e66f5"
lavender = "#7287fd"
text = "#4c4f69"
subtext1 = "#5c5f77"
subtext0 = "#6c6f85"
overlay2 = "#7c7f93"
overlay1 = "#8c8fa1"
overlay0 = "#9ca0b0"
surface2 = "#acb0be"
surface1 = "#bcc0cc"
surface0 = "#ccd0da"
base = "#eff1f5"
mantle = "#e6e9ef"
crust = "#dce0e8"

[palettes.catppuccin_macchiato]
rosewater = "#f4dbd6"
flamingo = "#f0c6c6"
pink = "#f5bde6"
mauve = "#c6a0f6"
red = "#ed8796"
maroon = "#ee99a0"
peach = "#f5a97f"
yellow = "#eed49f"
green = "#a6da95"
teal = "#8bd5ca"
sky = "#91d7e3"
sapphire = "#7dc4e4"
blue = "#8aadf4"
lavender = "#b7bdf8"
text = "#cad3f5"
subtext1 = "#b8c0e0"
subtext0 = "#a5adcb"
overlay2 = "#939ab7"
overlay1 = "#8087a2"
overlay0 = "#6e738d"
surface2 = "#5b6078"
surface1 = "#494d64"
surface0 = "#363a4f"
base = "#24273a"
mantle = "#1e2030"
crust = "#181926"
STARSHIP

info "Starship configured with Catppuccin Powerline + Azure module"

# ─────────────────────────────────────────────────────────────────────────────
step 8 "Configuring Ghostty"
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/ghostty"

cat > "$HOME/.config/ghostty/config" << 'GHOSTTY'
# Theme — matches Starship Catppuccin Mocha palette
theme = Catppuccin Mocha

# Font
font-family = MesloLGS NF
font-size = 14

# Window
window-padding-x = 8
window-padding-y = 8
window-decoration = true

# Shell integration
shell-integration = zsh

# Native macOS tab bar in titlebar
macos-titlebar-style = tabs

# Copy on select (highlight text = copied)
copy-on-select = clipboard

# Clickable URLs (Cmd+click to open)
link-url = true

# New tabs/splits open in same working directory
window-inherit-working-directory = true
window-inherit-font-size = true

# Notify when a command takes longer than 30 seconds (only when unfocused)
notify-on-command-finish = unfocused
notify-on-command-finish-after = 30

# Split navigation — Opt+hjkl
keybind = opt+h=goto_split:left
keybind = opt+j=goto_split:bottom
keybind = opt+k=goto_split:top
keybind = opt+l=goto_split:right

# Split resize — Opt+Shift+hjkl
keybind = opt+shift+h=resize_split:left,20
keybind = opt+shift+l=resize_split:right,20
keybind = opt+shift+k=resize_split:up,20
keybind = opt+shift+j=resize_split:down,20

# Equalize all splits
keybind = cmd+shift+equal=equalize_splits

# Quick Terminal — global hotkey dropdown (Quake-style)
keybind = global:ctrl+grave_accent=toggle_quick_terminal
quick-terminal-position = top
quick-terminal-screen = main
quick-terminal-animation-duration = 0.15
GHOSTTY

info "Ghostty configured"

# ─────────────────────────────────────────────────────────────────────────────
step 9 "Configuring VS Code / Windsurf themes"
# ─────────────────────────────────────────────────────────────────────────────

# VS Code
CODE_BIN=""
if command -v code &>/dev/null; then
  CODE_BIN="$(command -v code)"
else
  for VSCODE_APP in \
    "/Applications/Visual Studio Code.app" \
    "$HOME/Applications/Visual Studio Code.app" \
    "/Applications/Visual Studio Code - Insiders.app" \
    "$HOME/Applications/Visual Studio Code - Insiders.app"
  do
    VSCODE_CLI="$VSCODE_APP/Contents/Resources/app/bin/code"
    if [[ -x "$VSCODE_CLI" ]]; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$VSCODE_CLI" "$HOME/.local/bin/code"
      CODE_BIN="$HOME/.local/bin/code"
      info "VS Code CLI linked to $CODE_BIN"
      break
    fi
  done
fi

if [[ -n "$CODE_BIN" ]]; then
  "$CODE_BIN" --install-extension Catppuccin.catppuccin-vsc --force 2>/dev/null || true
  "$CODE_BIN" --install-extension Catppuccin.catppuccin-vsc-icons --force 2>/dev/null || true

  VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
  mkdir -p "$(dirname "$VSCODE_SETTINGS")"
  if [[ -f "$VSCODE_SETTINGS" ]]; then
    # Update existing settings using python
    python3 -c "
import json
with open('$VSCODE_SETTINGS', 'r') as f:
    s = json.load(f)
s['workbench.colorTheme'] = 'Catppuccin Mocha'
s['workbench.iconTheme'] = 'catppuccin-mocha'
s['editor.fontFamily'] = 'MesloLGS NF, Fira Code'
s['editor.fontLigatures'] = True
s['editor.fontSize'] = 14
s['terminal.external.osxExec'] = 'Ghostty.app'
s['terminal.explorerKind'] = 'external'
with open('$VSCODE_SETTINGS', 'w') as f:
    json.dump(s, f, indent=2)
" 2>/dev/null
    info "VS Code settings updated"
  else
    cat > "$VSCODE_SETTINGS" << 'VSCODE'
{
  "workbench.colorTheme": "Catppuccin Mocha",
  "workbench.iconTheme": "catppuccin-mocha",
  "editor.fontFamily": "MesloLGS NF, Fira Code",
  "editor.fontLigatures": true,
  "editor.fontSize": 14,
  "terminal.external.osxExec": "Ghostty.app",
  "terminal.explorerKind": "external"
}
VSCODE
    info "VS Code settings created"
  fi
else
  warn "VS Code CLI not found — skipping"
fi

# Windsurf
if command -v windsurf &>/dev/null; then
  # Download VSIX from Open-VSX (Windsurf can't use VS Code Marketplace directly)
  VSIX_THEME=$(mktemp /tmp/catppuccin-vsc-XXXXXX.vsix)
  VSIX_ICONS=$(mktemp /tmp/catppuccin-icons-XXXXXX.vsix)
  curl -sL "https://open-vsx.org/api/Catppuccin/catppuccin-vsc/latest/file/Catppuccin.catppuccin-vsc-3.18.1.vsix" -o "$VSIX_THEME" 2>/dev/null
  curl -sL "https://open-vsx.org/api/Catppuccin/catppuccin-vsc-icons/latest/file/Catppuccin.catppuccin-vsc-icons-1.26.0.vsix" -o "$VSIX_ICONS" 2>/dev/null
  windsurf --install-extension "$VSIX_THEME" 2>/dev/null || true
  windsurf --install-extension "$VSIX_ICONS" 2>/dev/null || true
  rm -f "$VSIX_THEME" "$VSIX_ICONS"

  WINDSURF_SETTINGS="$HOME/Library/Application Support/Windsurf/User/settings.json"
  if [[ -f "$WINDSURF_SETTINGS" ]]; then
    python3 -c "
import json
with open('$WINDSURF_SETTINGS', 'r') as f:
    s = json.load(f)
s['workbench.colorTheme'] = 'Catppuccin Mocha'
s['workbench.iconTheme'] = 'catppuccin-mocha'
s['editor.fontFamily'] = 'MesloLGS NF, Fira Code'
s['editor.fontLigatures'] = True
s['editor.fontSize'] = 14
s['terminal.external.osxExec'] = 'Ghostty.app'
with open('$WINDSURF_SETTINGS', 'w') as f:
    json.dump(s, f, indent=2)
" 2>/dev/null
    info "Windsurf settings updated"
  fi
else
  warn "Windsurf CLI not found — skipping"
fi

# ─────────────────────────────────────────────────────────────────────────────
step 10 "Configuring TUI tools (lazygit + yazi)"
# ─────────────────────────────────────────────────────────────────────────────

# lazygit — Catppuccin Mocha theme + delta pager
LAZYGIT_CONFIG_DIR="$HOME/.config/lazygit"
mkdir -p "$LAZYGIT_CONFIG_DIR"

if [[ -f "$LAZYGIT_CONFIG_DIR/config.yml" ]]; then
  info "lazygit config already exists — skipping"
else
  cat > "$LAZYGIT_CONFIG_DIR/config.yml" << 'LAZYGIT'
gui:
  showFileTree: true
  mouseEvents: true
  nerdFontsVersion: "3"

os:
  editPreset: 'nvim'

git:
  paging:
    colorArg: always
    pager: delta --paging=never --line-numbers

theme:
  activeBorderColor:
    - '#89b4fa'
    - bold
  inactiveBorderColor:
    - '#a6adc8'
  searchingActiveBorderColor:
    - '#f9e2af'
  optionsTextColor:
    - '#89b4fa'
  selectedLineBgColor:
    - '#313244'
  inactiveViewSelectedLineBgColor:
    - '#6c7086'
  cherryPickedCommitFgColor:
    - '#89b4fa'
  cherryPickedCommitBgColor:
    - '#45475a'
  markedBaseCommitFgColor:
    - '#89b4fa'
  markedBaseCommitBgColor:
    - '#f9e2af'
  unstagedChangesColor:
    - '#f38ba8'
  defaultFgColor:
    - '#cdd6f4'

authorColors:
  '*': '#b4befe'
LAZYGIT
  info "lazygit configured (Catppuccin Mocha + delta pager)"
fi

# yazi — Catppuccin Mocha theme + preview settings
YAZI_CONFIG_DIR="$HOME/.config/yazi"
mkdir -p "$YAZI_CONFIG_DIR"

if [[ -f "$YAZI_CONFIG_DIR/yazi.toml" ]]; then
  info "yazi config already exists — skipping"
else
  cat > "$YAZI_CONFIG_DIR/yazi.toml" << 'YAZITOML'
[mgr]
ratio = [1, 4, 3]
sort_by = "alphabetical"
sort_dir_first = true
show_hidden = false

[opener]
edit = [
    { run = 'nvim "$@"', desc = "nvim", block = true, for = "unix" },
]

[preview]
wrap = "no"
tab_size = 2
max_width = 600
max_height = 900
YAZITOML

  cat > "$YAZI_CONFIG_DIR/theme.toml" << 'YAZITHEME'
[flavor]
dark = "catppuccin-mocha"
YAZITHEME

  # Install Catppuccin Mocha flavor for yazi
  if command -v ya &>/dev/null; then
    ya pack -a yazi-rs/flavors:catppuccin-mocha 2>/dev/null || true
  fi

  info "yazi configured (Catppuccin Mocha + nvim opener)"
fi

# ─────────────────────────────────────────────────────────────────────────────
step 11 "Configuring git tools (delta + bat themes)"
# ─────────────────────────────────────────────────────────────────────────────

# delta — Catppuccin Mocha as git diff pager
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global delta.line-numbers true
git config --global delta.syntax-theme "Catppuccin Mocha"
info "delta configured (side-by-side + Catppuccin Mocha)"

# bat — install Catppuccin Mocha syntax theme
BAT_THEME_DIR="$(bat --config-dir 2>/dev/null)/themes"
if [[ -n "$BAT_THEME_DIR" ]]; then
  mkdir -p "$BAT_THEME_DIR"
  if [[ ! -f "$BAT_THEME_DIR/Catppuccin Mocha.tmTheme" ]]; then
    curl -sL "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme" \
      -o "$BAT_THEME_DIR/Catppuccin Mocha.tmTheme"
    bat cache --build 2>/dev/null
    info "bat Catppuccin Mocha theme installed"
  else
    info "bat Catppuccin Mocha theme already installed"
  fi
else
  warn "bat config dir not found — skipping theme"
fi

# ─────────────────────────────────────────────────────────────────────────────
step 12 "Cleaning up"
# ─────────────────────────────────────────────────────────────────────────────

# Remove Powerlevel10k remnants if present
rm -f "$HOME/.p10k.zsh"
rm -rf "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
rm -rf "$HOME/.cache/p10k-"*
info "Cleaned up Powerlevel10k remnants"

echo -e "\n${BOLD}${GREEN}=======================================${NC}"
echo -e "${BOLD}${GREEN}  Setup Complete!${NC}"
echo -e "${BOLD}${GREEN}=======================================${NC}"
echo ""
echo -e "  ${BOLD}What was installed:${NC}"
echo "  • Oh My Zsh + 6 plugins (autosuggestions, syntax-highlighting, etc.)"
echo "  • Starship prompt (Catppuccin Powerline + Azure module)"
echo "  • Ghostty terminal (Catppuccin Mocha + vim splits + quick terminal)"
echo "  • cmux terminal (AI-native terminal with vertical tabs + git sidebar)"
echo "  • MesloLGS Nerd Font"
echo "  • Catppuccin Mocha theme for VS Code / Windsurf"
echo "  • lazygit (TUI git client — Catppuccin Mocha + delta diffs)"
echo "  • delta (beautiful git diffs — side-by-side + syntax highlighting)"
echo "  • yazi (terminal file manager — Catppuccin Mocha + bat preview)"
echo "  • bat (syntax-highlighted cat — Catppuccin Mocha theme)"
echo "  • CLI tools: fd, ripgrep, fzf, eza"
echo "  • Lazy-loaded NVM (faster shell startup)"
echo "  • JDK switcher (jdk8, jdk17, jdk19, jdks)"
echo "  • Zoxide (smart cd)"
echo ""
echo -e "  ${BOLD}Quick reference:${NC}"
echo "  • Ctrl+\`        — Quick terminal (from anywhere)"
echo "  • Cmd+D          — Split pane right"
echo "  • Cmd+Shift+D    — Split pane down"
echo "  • Opt+H/J/K/L    — Navigate splits"
echo "  • Cmd+Shift+W    — Close split"
echo "  • lg              — lazygit (review diffs, stage, commit)"
echo "  • yazi / y        — Terminal file manager with preview"
echo "  • bat <file>      — Syntax-highlighted file viewer"
echo "  • z <dir>        — Smart cd (zoxide)"
echo "  • jdk8/jdk17/19  — Switch Java version"
echo ""
echo -e "  ${YELLOW}Open a new terminal window to see changes.${NC}"
