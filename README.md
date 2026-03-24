# Developer Environment Setup

![Homebrew](https://img.shields.io/badge/Homebrew-supported-FBB040?logo=homebrew&logoColor=white)

One-click script to set up a fully customized macOS developer terminal environment.

## What's Included

### Terminal & Shell
- **Ghostty** — GPU-accelerated terminal (Zig) with native macOS tabs, split panes, quick terminal
- **Zsh + Oh My Zsh** — shell framework with 6 plugins
- **Starship** — cross-shell prompt with Catppuccin Powerline preset + Azure module
- **Zoxide** — smart `cd` replacement that learns your habits

### Theme (Catppuccin Mocha everywhere)
- Ghostty terminal
- Starship prompt
- VS Code
- Windsurf

### Zsh Plugins
| Plugin | What it does |
|--------|-------------|
| `git` | Git aliases and completions |
| `zsh-autosuggestions` | Ghost text suggestions from history |
| `zsh-syntax-highlighting` | Colors commands as you type (limited to 200 chars for performance) |
| `zsh-history-substring-search` | Type partial command, press Up/Down to find matches |
| `you-should-use` | Reminds you when an alias exists for a command |
| `web-search` | Search Google/DuckDuckGo from terminal |

### Developer Tools
- **JDK Switcher** — `jdk8`, `jdk17`, `jdk19`, `jdks` to switch Java versions
- **Lazy-loaded NVM** — node/npm only loads when first used (~0.8s faster shell startup)
- **MesloLGS Nerd Font** — icons in prompt and file explorers

## Usage

```bash
chmod +x dev-setup.sh && ./dev-setup.sh
```

## Install With Homebrew

```bash
brew install --HEAD https://raw.githubusercontent.com/abhishek-bhatkar/macbook-dev-setup/main/Formula/macbook-dev-setup.rb
macbook-dev-setup
```

This installs the script as the `macbook-dev-setup` command. The Homebrew install step only installs the command; your shell and editor configuration changes happen when you run `macbook-dev-setup`.

The script is **idempotent** — safe to run multiple times. It skips already-installed tools and backs up existing configs before overwriting.

On macOS, the script runs with the system Bash and is compatible with the default Bash 3.2 that ships with macOS.

## Prerequisites

- macOS (Apple Silicon or Intel)
- Internet connection
- Admin access (for Homebrew)

## What It Configures

### ~/.zshrc
- Oh My Zsh with no theme (Starship handles prompt)
- 6 plugins
- `~/.local/bin` added to `PATH`
- Lazy-loaded NVM
- JDK switcher functions
- Zoxide init
- Starship init

### ~/.config/starship.toml
- Catppuccin Powerline preset
- Segments: OS > user > directory > git > languages > conda > Azure > time
- Multi-line prompt with command duration

### ~/.config/ghostty/config
- Catppuccin Mocha theme
- MesloLGS NF font (14pt)
- Native macOS tab bar
- Copy on select
- Clickable URLs
- Working directory inheritance
- Long command notifications (>30s)
- Vim-style split navigation (`Opt+hjkl`)
- Quick terminal (`Ctrl+backtick`)

### VS Code / Windsurf
- Catppuccin Mocha color theme
- Catppuccin Mocha file icons
- MesloLGS NF font
- Ghostty as external terminal
- Auto-links the `code` CLI from the installed VS Code app into `~/.local/bin/code` if VS Code is present but the CLI is missing

## Ghostty Shortcuts

| Action | Shortcut |
|--------|----------|
| Quick terminal (global) | `Ctrl+`` ` |
| Split right | `Cmd+D` |
| Split down | `Cmd+Shift+D` |
| Navigate splits | `Opt+H/J/K/L` |
| Resize splits | `Opt+Shift+H/J/K/L` |
| Equalize splits | `Cmd+Shift+=` |
| Close split | `Cmd+Shift+W` |
| Search scrollback | `Cmd+F` |

## Zsh Shortcuts

| Command | What it does |
|---------|-------------|
| `z <partial-path>` | Smart cd (zoxide) |
| `jdk8` / `jdk17` / `jdk19` | Switch Java version |
| `jdks` | List installed JDKs |

## Customization

- **Switch Catppuccin flavor**: Change `catppuccin_mocha` to `catppuccin_frappe`, `catppuccin_macchiato`, or `catppuccin_latte` in `starship.toml` and matching `Catppuccin <Flavor>` in Ghostty config
- **Add Starship modules**: Edit `~/.config/starship.toml`
- **Add Ghostty keybinds**: Edit `~/.config/ghostty/config`
- **Ghostty hot-reloads** on save — no restart needed
