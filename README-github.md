# Claude Code VPS Setup Scripts

Quick installation and configuration of [Claude Code](https://claude.ai) on VPS servers.

## 🚀 Quick Start

### Full Installation (recommended)

```bash
wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-vps/main/setup-claude-code.sh | bash
```

or

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-vps/main/setup-claude-code.sh | bash
```

### Minimal Installation

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-vps/main/setup-claude-code-minimal.sh | bash
```

## 📦 What Gets Installed

| Component | Description |
|-----------|----------|
| Claude Code CLI | Native binary (no dependencies!) |
| tmux | Session persistence on disconnect |
| ripgrep | Fast file search |
| Workspace | Directory structure and configs |

> **Note:** Node.js is **not required** for native binary installation.
> Install Node.js only if you need MCP servers via `npx`.

## 🔧 What Gets Configured

- **CLAUDE.md** — server context (OS, hostname, installed services)
- **Permissions** — secure access rights for Claude
- **Custom Commands** — ready-made commands for administration:
  - `/project:status` — check server status
  - `/project:deploy <service>` — deploy Docker service
  - `/project:logs <service>` — analyze logs
  - `/project:backup <service>` — backup service
  - `/project:update <service>` — update images
- **Subagent monitor** — agent for system monitoring
- **tmux config** — convenient terminal configuration

## 📁 Structure After Installation

```
$HOME/
├── claude                    # Quick start script
├── claude-workspace/         # Working directory
│   ├── CLAUDE.md            # Project context
│   ├── README.md            # Documentation
│   └── .claude/
│       ├── settings.json    # Access permissions
│       ├── commands/        # Custom commands
│       │   ├── status.md
│       │   ├── deploy.md
│       │   ├── logs.md
│       │   ├── backup.md
│       │   └── update.md
│       └── agents/
│           └── monitor.md   # Monitoring subagent
├── services/                # Docker Compose services
└── .tmux.conf               # tmux configuration
```

## 🔑 Authentication

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
# On VPS
claude
# Follow the instructions for OAuth through browser
```

For headless servers use SSH tunnel:

```bash
# On local machine
ssh -L 8080:localhost:8080 user@your-vps

# On VPS run claude and open the URL in your local browser
```

## 🎮 Usage

### Launch

```bash
# Via quick start script (tmux session)
~/claude

# Or via alias
cc

# Direct
cd ~/claude-workspace && claude
```

### tmux Commands

| Key | Action |
|------|----------|
| `Ctrl+a d` | Detach (Claude continues running) |
| `Ctrl+a \|` | Split vertically |
| `Ctrl+a -` | Split horizontally |
| `Alt+arrows` | Navigate between panes |

### Usage Examples

```bash
# Check server status
/project:status

# Deploy new service
/project:deploy nginx

# Use subagent
Use the monitor subagent to analyze system performance

# Continue last session
claude -c
```

## 🔒 Security

The script configures limited access permissions:

**Allowed:**
- Read files
- Write to ~/claude-workspace/ and ~/services/
- Docker commands
- View logs and service status
- Git, npm, curl etc.

**Denied:**
- rm -rf /
- Write to /etc/
- Read /etc/shadow
- Destructive operations

## 📋 Requirements

- Ubuntu 20.04+ / Debian 10+
- User with sudo access
- Internet connection

## 🔌 Installing Node.js (optional)

Node.js is needed **only** for MCP servers via `npx`:

```bash
# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Configure npm without sudo
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Or edit the script and set `INSTALL_NODEJS=true` before running.

## 🐛 Troubleshooting

### command not found: claude

```bash
source ~/.bashrc
# or
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
```

### Permission denied on npm install

The script automatically configures npm to work without sudo. If the problem persists:

```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
```

### Verify Installation

```bash
claude doctor
```

## 📝 License

MIT

## 🔗 Links

- [Claude Code Documentation](https://code.claude.com/docs)
- [Anthropic Console](https://console.anthropic.com/)
- [Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
