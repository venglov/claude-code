# Claude Code Universal VPS Setup

Quick installation and configuration of [Claude Code](https://claude.ai) on any VPS server with automatic service discovery.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/venglov/claude-code/main/setup-claude-code.sh | bash
```

or

```bash
wget -qO- https://raw.githubusercontent.com/venglov/claude-code/main/setup-claude-code.sh | bash
```

## Features

- **Auto-discovery** — Automatically detects Docker Compose projects, Minecraft servers, media servers (Jellyfin/Plex), and other services
- **Flexible permissions** — Full access to `~/`, `/opt/`, `/srv/` out of the box
- **Dynamic context** — CLAUDE.md generated based on actual server state
- **No assumptions** — Works with any existing directory structure

## What Gets Installed

| Component | Description |
|-----------|-------------|
| Claude Code CLI | Native binary (no Node.js required) |
| tmux | Session persistence on disconnect |
| ripgrep | Fast file search |
| Configuration | Permissions, commands, and server context |

## What Gets Configured

- **~/CLAUDE.md** — Auto-generated server context with discovered services
- **~/.claude/settings.json** — Flexible permissions for VPS administration
- **Custom Commands:**
  - `/project:status` — Comprehensive health check
  - `/project:discover` — Find all services and projects
  - `/project:logs <target>` — Analyze logs
  - `/project:backup <target>` — Create backups
- **~/start-claude** — Quick launcher with tmux
- **~/update-claude-context** — Re-scan for new services

## Structure After Installation

```
$HOME/
├── start-claude              # Quick start script (tmux session)
├── update-claude-context     # Re-discovery helper
├── CLAUDE.md                 # Auto-generated server context
├── .claude/
│   ├── settings.json         # Permissions configuration
│   └── commands/
│       ├── status.md
│       ├── discover.md
│       ├── logs.md
│       └── backup.md
└── .tmux.conf                # tmux configuration
```

## Auto-Discovery

The script automatically scans for and documents:

| Type | Detection Method |
|------|------------------|
| Docker Compose | `docker-compose.yml`, `compose.yml` in /opt, /home, /srv |
| Minecraft | `server.properties` files |
| Media Servers | Jellyfin, Plex, Emby directories |
| Projects | `.git`, `package.json`, `requirements.txt`, etc. |
| Running Containers | `docker ps` output |
| Listening Ports | Active network services |

Run `~/update-claude-context` after installing new services to refresh.

## Permissions

**Allowed by default:**
- Read anywhere
- Write to `~/`, `/opt/`, `/srv/`
- Docker, systemctl, journalctl
- Common tools: git, curl, wget, tar, apt, npm, python, java, etc.
- Network tools: ss, netstat, ip, ufw
- SSL: certbot, nginx

**Blocked:**
- `rm -rf /`, `rm -rf /*`
- `dd`, `mkfs` (disk operations)
- Write to `/etc/passwd`, `/etc/shadow`
- Fork bombs

## Authentication

### Option 1: API Key

```bash
export ANTHROPIC_API_KEY="sk-ant-api03-..."

# For permanent use:
echo 'export ANTHROPIC_API_KEY="your-key"' >> ~/.bashrc
source ~/.bashrc
```

Get your key: https://console.anthropic.com/

### Option 2: OAuth (Claude Pro/Max)

```bash
claude
# Follow OAuth instructions
```

For headless servers use SSH tunnel:

```bash
# On local machine
ssh -L 8080:localhost:8080 user@your-vps

# On VPS run claude and open the URL in your local browser
```

## Usage

### Launch

```bash
# Via quick start script (tmux session)
~/start-claude

# Or via alias
cc

# Direct launch
claude
```

### tmux Commands

| Key | Action |
|-----|--------|
| `Ctrl+a d` | Detach (Claude continues running) |
| `Ctrl+a \|` | Split vertically |
| `Ctrl+a -` | Split horizontally |
| `Alt+arrows` | Navigate between panes |

### Examples

```bash
# Check server health
/project:status

# Find all services on this server
/project:discover

# Analyze logs for a container
/project:logs nginx

# Create backup
/project:backup /opt/myapp

# Continue last session
claude -c
```

## Requirements

- Ubuntu 20.04+ / Debian 10+
- User with sudo access
- Internet connection

## Installing Node.js (Optional)

Node.js is needed **only** for MCP servers via `npx`:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Troubleshooting

### command not found: claude

```bash
source ~/.bashrc
# or
export PATH="$HOME/.local/bin:$PATH"
```

### Verify Installation

```bash
claude doctor
```

### Re-discover Services

```bash
~/update-claude-context
# Or re-run the setup script for full regeneration
```

## License

MIT

## Links

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Anthropic Console](https://console.anthropic.com/)
- [Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
