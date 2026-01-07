# Claude Code: Complete Guide 2026

## What is Claude Code?

Claude Code is an agentic programming tool from Anthropic that works directly in the terminal. It allows Claude to directly edit files, run commands, create commits, and interact with external services through MCP (Model Context Protocol).

Key capabilities:
- Analyze and work with entire codebases
- Execute bash commands and scripts
- Edit files with context awareness
- Integration with Git, GitHub and other tools
- Subagents for parallel tasks
- Hooks for workflow automation
- MCP support for integration with external services

---

## System Requirements

| Component | Requirements |
|-----------|-----------|
| OS | macOS 10.15+, Ubuntu 20.04+, Debian 10+, Windows 10+ (WSL/Git Bash) |
| Node.js | v18+ (for npm installation) |
| RAM | Minimum 4GB |
| Terminal | Bash, Zsh, Fish (recommended) |
| Network | Persistent internet connection |

---

## Installing Claude Code

### Method 1: Native Binary (recommended)

This method avoids package manager conflicts and is the most stable.

**Linux/macOS:**
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://claude.ai/install.ps1 | iex
```

After installation Claude will be available at `~/.local/bin/claude` or `~/.claude/bin/claude`.

**Add to PATH (if needed):**
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Method 2: NPM (alternative)

```bash
# Requires Node.js 18+
npm install -g @anthropic-ai/claude-code
```

> ⚠️ **Important:** Never use `sudo` with this command — it causes permission issues.

### Verify Installation

```bash
claude --version
claude doctor  # Installation diagnostics
```

---

## Authentication

### Option 1: Claude Pro/Max subscription (recommended)

```bash
claude
# Follow the instructions for OAuth through browser
```

On first run, a browser will open for authentication through claude.ai.

### Option 2: API Key

```bash
# Get key: https://console.anthropic.com/
export ANTHROPIC_API_KEY="sk-ant-..."
claude
```

**For permanent use:**
```bash
# Bash
echo 'export ANTHROPIC_API_KEY="your-api-key"' >> ~/.bashrc

# Zsh
echo 'export ANTHROPIC_API_KEY="your-api-key"' >> ~/.zshrc
```

### Check Authentication Status

```bash
# In Claude Code session
/status
```

---

## Basic Commands

### Launch

```bash
claude                          # Interactive mode
claude "explain this project"   # With initial prompt
claude -p "summarize README.md" # Non-interactive (headless) mode
claude -c                       # Continue last session
claude -r "<session-id>"        # Resume specific session
```

### Model Selection

```bash
claude --model sonnet           # Claude Sonnet 4.5 (fast, for everyday tasks)
claude --model opus             # Claude Opus 4.5 (powerful, for complex tasks)
```

### Working with Directories

```bash
claude --add-dir ../frontend --add-dir ../backend  # Add access to folders
```

### Management and Updates

```bash
claude update           # Update Claude Code
claude doctor           # Diagnose issues
claude config           # Settings
```

---

## Slash Commands (in session)

| Command | Description |
|---------|----------|
| `/help` | Show all available commands |
| `/clear` | Clear conversation history |
| `/exit` | Exit Claude Code |
| `/status` | Authentication status |
| `/permissions` | Manage access permissions |
| `/context` | Show context usage |
| `/agents` | Manage subagents |
| `/compact` | Compress context (compactification) |

---

## CLAUDE.md File — Project Memory

Create a `CLAUDE.md` file in the project root to preserve context between sessions:

```markdown
# Project: MyApp

## Tech Stack
- Python 3.11 + FastAPI
- PostgreSQL 15
- Docker + Docker Compose
- Nginx reverse proxy

## Coding Standards
- Use type hints everywhere
- Tests with pytest
- Docstrings in Google format
- Max line length: 88 (Black formatter)

## Project Structure
```
myapp/
├── src/
│   ├── api/          # FastAPI routes
│   ├── services/     # Business logic
│   └── models/       # SQLAlchemy models
├── tests/
└── docker-compose.yml
```

## Important Notes
- Don't commit until I approve
- Write tests first (TDD approach)
- Use environment variables for secrets
```

**CLAUDE.md Levels:**
- `~/.claude/CLAUDE.md` — global (your personal settings)
- `./CLAUDE.md` — project-specific

---

## Subagents

Subagents are isolated Claude instances for executing specific tasks without polluting the main context.

### Creating a Subagent

```bash
/agents  # Interactive creation
```

Or create file `.claude/agents/researcher.md`:

```markdown
---
name: researcher
description: Deep research agent for exploring codebases and documentation
tools: Read, Grep, LS, Bash(find *)
---

You are a thorough research assistant. Your job is to explore
codebases, read documentation, and provide comprehensive summaries.

When called:
1. Use grep and find to locate relevant files
2. Read and analyze content
3. Return a structured summary of findings
```

### Usage

```
Use the researcher subagent to analyze the authentication system
```

Or using `@`:
```
@researcher find all API endpoints in this project
```

### Built-in Subagents

- **Explore** — codebase exploration
- **Plan** — implementation planning
- **claude-code-guide** — Claude Code help

---

## Hooks

Hooks allow executing commands on specific events.

### Configuration in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": ["bash -c 'echo \"Writing to: $CLAUDE_FILE_PATH\"'"]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash(npm test*)",
        "hooks": ["bash -c 'if [ $CLAUDE_EXIT_CODE -ne 0 ]; then echo \"Tests failed!\"; fi'"]
      }
    ],
    "Stop": [
      {
        "hooks": ["bash -c 'git status'"]
      }
    ]
  }
}
```

### Hook Events

| Event | When Triggered |
|---------|------------------|
| `PreToolUse` | Before tool execution |
| `PostToolUse` | After tool execution |
| `Stop` | On session end |
| `SubagentStop` | On subagent end |

---

## MCP (Model Context Protocol)

MCP allows Claude Code to connect to external services.

### Adding an MCP Server

```bash
# Filesystem (file system access)
claude mcp add filesystem -- npx @modelcontextprotocol/server-filesystem /path/to/project

# GitHub
claude mcp add github -- npx @modelcontextprotocol/server-github

# Puppeteer (browser automation)
claude mcp add playwright -- npx @playwright/mcp@latest

# SQLite database
claude mcp add sqlite -- npx @modelcontextprotocol/server-sqlite /path/to/db.sqlite
```

### `.mcp.json` File for Command

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-filesystem", "/home/project"]
    },
    "github": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

---

## Custom Commands

Create file `.claude/commands/deploy.md`:

```markdown
Deploy the application to production:
1. Run all tests with `npm test`
2. Build the production bundle with `npm run build`
3. Check for any security vulnerabilities with `npm audit`
4. If all checks pass, create a git tag with the current version
5. Push to the main branch
```

Now the `/project:deploy` command is available.

---

## Best Practices

### 1. Effective Prompts

```bash
# ❌ Bad: vague request
claude "check my code"

# ✅ Good: specific and detailed
claude "Review UserAuth.js for security vulnerabilities, focusing on JWT handling and password hashing"
```

### 2. Use Thinking Modes

```
think about how to implement the authentication system
think hard about the best architecture for this feature
think harder about potential edge cases
ultrathink about security implications
```

### 3. Context Management

- Monitor context indicator (bottom right)
- Use `/compact` to compress when needed
- Delegate research to subagents
- Don't ask Claude to read everything at once — provide specific files

### 4. Configure Access Permissions

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Write(src/**)",
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(docker compose *)"
    ],
    "deny": [
      "Read(.env*)",
      "Write(production.config.*)",
      "Bash(rm -rf *)",
      "Bash(sudo *)"
    ]
  }
}
```

### 5. Git Integration

```bash
# Generate release notes
git log --oneline -n 10 | claude -p "Create release notes from these commits"

# Analyze changes
git diff HEAD~5 | claude -p "Summarize these changes and identify potential issues"

# Create commit
claude "commit these changes with a descriptive message"
```

---

## Headless Mode for Automation

```bash
# Simple execution
claude -p "summarize README.md"

# With JSON output
claude -p "list all functions in main.py" --output-format json

# Limit steps
claude --max-turns 3 -p "run linter and fix issues"

# Pipe input
cat error.log | claude -p "explain this error and suggest a fix"
```

### Example in CI/CD:

```yaml
# .github/workflows/claude-review.yml
name: Claude Code Review
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Claude Code
        run: curl -fsSL https://claude.ai/install.sh | bash
      - name: Review PR
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          git diff origin/main | claude -p "Review this diff for issues"
```

---

## Advanced Features 2025-2026

### Checkpoints

Claude Code automatically creates restore points. You can roll back to a previous state on errors.

### Asynchronous Agents

```
Start a background agent to monitor logs for errors
```

The agent works in the background while you continue working.

### Plan Mode

Claude automatically creates `plan.md` for complex tasks and follows it, marking completed items.

### Skills

Automatically activated contexts based on task description.

Create `.claude/skills/docker-expert/SKILL.md`:

```markdown
---
name: docker-expert
description: Activate when working with Docker, containers, docker-compose
---

# Docker Expert Skill

When working with Docker:
- Always use multi-stage builds for production
- Prefer alpine images when possible
- Use .dockerignore files
- Set proper health checks
- Use non-root users in containers
```

---

## Plugins

Plugins combine skills, subagents, commands and MCP servers into one package.

```bash
# Install plugin
/plugins install frontend-design

# View installed
/plugins list
```

---

## Troubleshooting

### "command not found: claude"

```bash
# Add to PATH
export PATH="$HOME/.local/bin:$PATH"
source ~/.bashrc
```

### "Invalid API key"

```bash
# Check variable
echo $ANTHROPIC_API_KEY

# Or use /status in session
/status
```

### npm Permission Issues

```bash
# Configure npm to install to home directory
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Diagnostics

```bash
claude doctor
```

---

# Installing Claude Code on VPS — Step-by-Step Flow

## Scenario: VPS Assistant for Server Configuration

Using Claude Code as an assistant for VPS server configuration and administration.

---

## Step 1: VPS Preparation

### 1.1 Connect to Server

```bash
ssh root@your-vps-ip
# Or via SSH key
ssh -i ~/.ssh/your_key root@your-vps-ip
```

### 1.2 Create User (don't work as root)

```bash
# On VPS
adduser claudeuser
usermod -aG sudo claudeuser

# Configure SSH key for new user
mkdir -p /home/claudeuser/.ssh
cp ~/.ssh/authorized_keys /home/claudeuser/.ssh/
chown -R claudeuser:claudeuser /home/claudeuser/.ssh
chmod 700 /home/claudeuser/.ssh
chmod 600 /home/claudeuser/.ssh/authorized_keys

# Switch to new user
su - claudeuser
```

### 1.3 Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify
node --version  # v20.x.x
npm --version   # 10.x.x

# Install additional utilities
sudo apt install -y git curl wget tmux htop ripgrep
```

---

## Step 2: Install Claude Code

### 2.1 Native Binary (recommended)

```bash
curl -fsSL https://claude.ai/install.sh | bash

# Add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
claude --version
```

### 2.2 Alternative via NPM

```bash
# Configure npm for user (without sudo)
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Install
npm install -g @anthropic-ai/claude-code
```

---

## Step 3: Authentication on Headless Server

### Option A: API Key (simplest)

```bash
# Get key at https://console.anthropic.com/
export ANTHROPIC_API_KEY="sk-ant-api03-..."

# For permanent use
echo 'export ANTHROPIC_API_KEY="your-api-key"' >> ~/.bashrc
source ~/.bashrc
```

### Option B: OAuth via SSH Tunnel

If you have Claude Pro/Max subscription:

```bash
# On local machine create tunnel
ssh -L 8080:localhost:8080 claudeuser@your-vps-ip

# In SSH session on VPS run
claude

# Copy URL like http://localhost:8080/...
# and open it in browser on your local machine
```

### Option C: Tailscale for Persistent Access

```bash
# On VPS
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Now you can connect via Tailscale IP
ssh claudeuser@100.x.x.x
```

---

## Step 4: Configure for VPS Administration

### 4.1 Create Working Directory

```bash
mkdir -p ~/vps-admin
cd ~/vps-admin
```

### 4.2 Create CLAUDE.md for VPS Context

```bash
cat > CLAUDE.md << 'EOF'
# VPS Administration Assistant

## Server Info
- OS: Ubuntu 24.04 LTS
- Role: Web server / Docker host
- User: claudeuser (sudo access)

## Installed Services
- Docker & Docker Compose
- Nginx (reverse proxy)
- PostgreSQL 15
- Redis
- Certbot (Let's Encrypt)

## Security Rules
- Never expose ports directly, use Nginx reverse proxy
- Always use UFW firewall
- Use fail2ban for SSH protection
- SSL certificates via Let's Encrypt
- No plaintext passwords in configs

## Coding Standards
- Use docker-compose for all services
- Store secrets in .env files (git-ignored)
- Log everything to /var/log/
- Use systemd for service management

## Common Tasks
- New service: Create docker-compose.yml + nginx config + SSL
- Backup: Use restic to S3-compatible storage
- Monitoring: Check with htop, docker stats, nginx logs

## Important Paths
- /home/claudeuser/services/ - All Docker services
- /etc/nginx/sites-available/ - Nginx configs
- /var/log/ - System logs
EOF
```

### 4.3 Configure Access Permissions

Create `.claude/settings.json`:

```bash
mkdir -p .claude
cat > .claude/settings.json << 'EOF'
{
  "permissions": {
    "allow": [
      "Read",
      "Write(~/services/**)",
      "Write(~/vps-admin/**)",
      "Bash(docker *)",
      "Bash(docker compose *)",
      "Bash(systemctl status *)",
      "Bash(journalctl *)",
      "Bash(htop)",
      "Bash(df *)",
      "Bash(free *)",
      "Bash(cat /var/log/*)",
      "Bash(tail *)",
      "Bash(grep *)",
      "Bash(find *)",
      "Bash(ls *)",
      "Bash(pwd)",
      "Bash(whoami)",
      "Bash(uname *)",
      "Bash(nginx -t)",
      "Bash(certbot *)"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(sudo rm -rf *)",
      "Bash(> /dev/sda*)",
      "Bash(mkfs*)",
      "Bash(dd if=*)",
      "Read(/etc/shadow)",
      "Write(/etc/*)"
    ]
  }
}
EOF
```

---

## Step 5: Useful Commands and Subagents

### 5.1 Create Custom Commands

```bash
mkdir -p .claude/commands

# Server status check command
cat > .claude/commands/server-status.md << 'EOF'
Check the server status:
1. Run `df -h` to check disk space
2. Run `free -h` to check memory
3. Run `docker ps` to list running containers
4. Run `systemctl list-units --failed` to check failed services
5. Check nginx status with `systemctl status nginx`
6. Summarize the overall health of the server
EOF

# New service deployment command
cat > .claude/commands/deploy-service.md << 'EOF'
Deploy a new Docker service with Nginx reverse proxy:
1. Create directory structure in ~/services/$ARGUMENTS/
2. Generate docker-compose.yml based on the service type
3. Create nginx site config in sites-available
4. Enable the site with symlink to sites-enabled
5. Test nginx config with `nginx -t`
6. Request SSL certificate with certbot
7. Start the service with `docker compose up -d`
8. Verify the service is running
EOF
```

### 5.2 Create Monitoring Subagent

```bash
mkdir -p .claude/agents

cat > .claude/agents/monitor.md << 'EOF'
---
name: monitor
description: System monitoring agent for checking server health and logs
tools: Read, Bash(docker *), Bash(systemctl *), Bash(journalctl *), Bash(tail *), Bash(grep *), Bash(df *), Bash(free *)
---

You are a system monitoring specialist. Your job is to:
1. Check system resources (CPU, memory, disk)
2. Review Docker container status and logs
3. Analyze nginx access/error logs for issues
4. Identify potential problems before they become critical
5. Provide clear, actionable summaries

Always prioritize:
- Security issues (failed logins, unusual traffic)
- Resource exhaustion (disk space, memory)
- Service failures (stopped containers, crashed services)
EOF
```

---

## Step 6: Launch and Usage

### 6.1 Launch in tmux (for session persistence)

```bash
# Create tmux session
tmux new-session -s claude

# Launch Claude Code
cd ~/vps-admin
claude
```

**Useful tmux commands:**
- `Ctrl+b d` — detach from session (Claude continues running)
- `tmux attach -t claude` — return to session
- `tmux list-sessions` — list sessions

### 6.2 Usage Examples

```bash
# Check status
/project:server-status

# Deploy new service
/project:deploy-service nextcloud

# Analyze logs
Use the monitor subagent to check nginx logs for the last hour

# Configure new Docker service
Set up a new PostgreSQL container with:
- Port 5432 (internal only)
- Persistent volume for data
- Environment variables from .env file
- Automatic restart policy

# Troubleshooting
Analyze why the nginx service keeps crashing. Check:
1. journalctl logs
2. nginx error.log
3. Config syntax
4. Resource usage
```

---

## Step 7: Automation (optional)

### 7.1 Quick Access Script on Local Machine

Create on your computer `~/.local/bin/vps-claude`:

```bash
#!/bin/bash
# Quick access to Claude Code on VPS

VPS_HOST="your-vps-ip"
VPS_USER="claudeuser"
WORKDIR="~/vps-admin"

# Connect and start Claude in tmux
ssh -t $VPS_USER@$VPS_HOST "
  cd $WORKDIR
  if tmux has-session -t claude 2>/dev/null; then
    tmux attach -t claude
  else
    tmux new-session -s claude -c $WORKDIR 'claude; bash'
  fi
"
```

```bash
chmod +x ~/.local/bin/vps-claude
```

### 7.2 Periodic Checks via cron

```bash
# On VPS add to crontab
crontab -e

# Hourly health check
0 * * * * cd ~/vps-admin && claude -p "Quick health check: disk, memory, docker containers" >> /var/log/claude-health.log 2>&1
```

---

## Useful Resources

- [Official Documentation](https://code.claude.com/docs)
- [Best Practices from Anthropic](https://www.anthropic.com/engineering/claude-code-best-practices)
- [GitHub Repository](https://github.com/anthropics/claude-code)
- [Anthropic Console](https://console.anthropic.com/) — API keys
- [Claude.ai](https://claude.ai) — web interface and subscriptions

---

## VPS Installation Checklist

- [ ] Created user (not root)
- [ ] Installed Node.js 18+
- [ ] Installed Claude Code
- [ ] Configured authentication (API key or OAuth)
- [ ] Created working directory
- [ ] Created CLAUDE.md with server context
- [ ] Configured permissions in settings.json
- [ ] Created useful commands
- [ ] Configured tmux for session persistence
- [ ] Verified operation with `/project:server-status` command

---

*Last updated: January 2026*
