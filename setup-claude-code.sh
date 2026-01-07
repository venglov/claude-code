#!/bin/bash
#
# Claude Code Quick Setup Script for VPS
# Usage: curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/setup-claude-code.sh | bash
#
# Author: Vyacheslav
# Version: 1.1.0
# Updated: January 2026
#

set -e

# ============================================
# COLORS
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

print_header() {
    echo -e "\n${BLUE}${BOLD}══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}  $1${NC}"
    echo -e "${BLUE}${BOLD}══════════════════════════════════════════════════════${NC}\n"
}

print_step() { echo -e "${CYAN}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# ============================================
# CONFIGURATION
# ============================================
CLAUDE_WORKDIR="$HOME/claude-workspace"
SERVICES_DIR="$HOME/services"
INSTALL_NODEJS=false  # Will be set to true only if native binary fails

# ============================================
# PRE-FLIGHT CHECKS
# ============================================
print_header "Claude Code VPS Setup Script"

echo -e "${CYAN}This script will:${NC}"
echo "  • Install Claude Code CLI (native binary)"
echo "  • Create workspace directory structure"
echo "  • Configure CLAUDE.md with server context"
echo "  • Set up permissions and custom commands"
echo "  • Install tmux for session persistence"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. Recommended to run as regular user with sudo."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
else
    print_error "Cannot detect OS."
    exit 1
fi

print_step "Detected OS: $OS $OS_VERSION"

# ============================================
# INSTALL BASIC DEPENDENCIES
# ============================================
print_header "Installing Dependencies"

print_step "Updating package lists..."
sudo apt-get update -qq

print_step "Installing essential packages..."
sudo apt-get install -y -qq \
    curl \
    wget \
    git \
    tmux \
    htop \
    ripgrep \
    jq \
    unzip \
    ca-certificates \
    > /dev/null 2>&1

print_success "Essential packages installed"

# ============================================
# INSTALL CLAUDE CODE (Native Binary)
# ============================================
print_header "Installing Claude Code"

print_step "Installing via native binary (recommended)..."

# Ensure ~/.local/bin exists and is in PATH
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

if curl -fsSL https://claude.ai/install.sh | bash 2>/dev/null; then
    # Add to PATH permanently
    if ! grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null; then
        echo '' >> "$HOME/.bashrc"
        echo '# Claude Code' >> "$HOME/.bashrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    fi
    print_success "Claude Code installed via native binary"
else
    print_warning "Native binary failed. Installing Node.js + npm as fallback..."
    INSTALL_NODEJS=true

    # Install Node.js
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - > /dev/null 2>&1
    sudo apt-get install -y -qq nodejs > /dev/null 2>&1

    # Configure npm for user-level global packages
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global"
    export PATH="$HOME/.npm-global/bin:$PATH"

    if ! grep -q 'npm-global' "$HOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
    fi

    # Install via npm
    npm install -g @anthropic-ai/claude-code
    print_success "Claude Code installed via npm"
fi

# Verify installation
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "installed")
    print_success "Claude Code $CLAUDE_VERSION ready"
else
    print_error "Installation failed!"
    exit 1
fi

# ============================================
# CREATE DIRECTORY STRUCTURE
# ============================================
print_header "Creating Workspace"

mkdir -p "$CLAUDE_WORKDIR/.claude/commands"
mkdir -p "$CLAUDE_WORKDIR/.claude/agents"
mkdir -p "$SERVICES_DIR"

print_success "Created $CLAUDE_WORKDIR"

# ============================================
# GATHER SYSTEM INFO
# ============================================
HOSTNAME=$(hostname)
IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "unknown")
TOTAL_MEM=$(free -h | awk '/^Mem:/ {print $2}')
TOTAL_DISK=$(df -h / | awk 'NR==2 {print $2}')
CPU_CORES=$(nproc)

DOCKER_INSTALLED=$(command -v docker &> /dev/null && echo "yes" || echo "no")
NGINX_INSTALLED=$(command -v nginx &> /dev/null && echo "yes" || echo "no")

# ============================================
# CREATE CLAUDE.md
# ============================================
print_header "Creating Configuration"

cat > "$CLAUDE_WORKDIR/CLAUDE.md" << EOF
# VPS Administration Assistant

## Server Info
- **Hostname:** $HOSTNAME
- **OS:** $OS $OS_VERSION
- **IP:** $IP_ADDR
- **CPU:** $CPU_CORES cores
- **Memory:** $TOTAL_MEM
- **Disk:** $TOTAL_DISK
- **User:** $USER

## Services
- Docker: $DOCKER_INSTALLED
- Nginx: $NGINX_INSTALLED

## Directories
- ~/claude-workspace/ — Claude work
- ~/services/ — Docker Compose services

## Rules
- Secrets in .env files
- Docker Compose for all services
- Ask before destructive operations
- SSL via Let's Encrypt
EOF

print_success "Created CLAUDE.md"

# ============================================
# CREATE SETTINGS.JSON
# ============================================
cat > "$CLAUDE_WORKDIR/.claude/settings.json" << 'EOF'
{
  "permissions": {
    "allow": [
      "Read",
      "Write(~/claude-workspace/**)",
      "Write(~/services/**)",
      "Bash(docker *)",
      "Bash(docker compose *)",
      "Bash(systemctl status *)",
      "Bash(journalctl *)",
      "Bash(htop)",
      "Bash(df *)",
      "Bash(free *)",
      "Bash(cat *)",
      "Bash(tail *)",
      "Bash(grep *)",
      "Bash(find *)",
      "Bash(ls *)",
      "Bash(ps *)",
      "Bash(ss *)",
      "Bash(ip *)",
      "Bash(git *)",
      "Bash(curl *)"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(rm -rf /*)",
      "Bash(sudo rm -rf *)",
      "Write(/etc/*)",
      "Read(/etc/shadow)"
    ]
  }
}
EOF

print_success "Created permissions"

# ============================================
# CREATE CUSTOM COMMANDS
# ============================================
cat > "$CLAUDE_WORKDIR/.claude/commands/status.md" << 'EOF'
Check server status:
1. `df -h` — disk space
2. `free -h` — memory
3. `docker ps` — containers (if docker installed)
4. `uptime` — load average
Summarize health status.
EOF

cat > "$CLAUDE_WORKDIR/.claude/commands/deploy.md" << 'EOF'
Deploy Docker service: $ARGUMENTS
1. Create ~/services/$ARGUMENTS/
2. Generate docker-compose.yml
3. Create .env if needed
4. Start: `docker compose up -d`
5. Verify: `docker compose ps`
EOF

cat > "$CLAUDE_WORKDIR/.claude/commands/logs.md" << 'EOF'
Analyze logs for: $ARGUMENTS
- Docker: `docker compose logs --tail=100`
- System: `journalctl --since "1 hour ago" | tail -100`
Find errors and provide recommendations.
EOF

print_success "Created commands: status, deploy, logs"

# ============================================
# CREATE MONITOR SUBAGENT
# ============================================
cat > "$CLAUDE_WORKDIR/.claude/agents/monitor.md" << 'EOF'
---
name: monitor
description: System monitoring and health checks
tools: Read, Bash(docker *), Bash(systemctl *), Bash(journalctl *), Bash(df *), Bash(free *), Bash(ps *), Bash(ss *)
---

You are a system monitoring specialist.

Tasks:
- Check CPU, memory, disk usage
- Monitor Docker containers
- Analyze logs for errors
- Identify bottlenecks

Output: Status (OK/WARNING/CRITICAL), metrics, issues, recommendations.
EOF

print_success "Created monitor subagent"

# ============================================
# TMUX CONFIG
# ============================================
cat > "$HOME/.tmux.conf" << 'EOF'
set -g mouse on
set -g prefix C-a
unbind C-b
bind C-a send-prefix
set -g base-index 1
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D
set -g history-limit 50000
EOF

print_success "Created tmux config"

# ============================================
# QUICK START SCRIPT
# ============================================
cat > "$HOME/claude" << EOF
#!/bin/bash
cd "$CLAUDE_WORKDIR"
tmux has-session -t claude 2>/dev/null && tmux attach -t claude || tmux new-session -s claude
EOF
chmod +x "$HOME/claude"

# Aliases
grep -q 'alias cc=' "$HOME/.bashrc" || {
    echo '' >> "$HOME/.bashrc"
    echo 'alias cc="~/claude"' >> "$HOME/.bashrc"
    echo "alias ccd=\"cd $CLAUDE_WORKDIR && claude\"" >> "$HOME/.bashrc"
}

print_success "Created ~/claude script and aliases"

# ============================================
# SUMMARY
# ============================================
print_header "Installation Complete!"

echo -e "${GREEN}${BOLD}Claude Code installed successfully!${NC}\n"

if [ "$INSTALL_NODEJS" = true ]; then
    echo -e "${YELLOW}Note: Installed via npm (Node.js fallback)${NC}\n"
fi

echo -e "${CYAN}Next steps:${NC}"
echo "  1. ${YELLOW}source ~/.bashrc${NC}"
echo "  2. ${YELLOW}export ANTHROPIC_API_KEY=\"your-key\"${NC}"
echo "  3. ${YELLOW}~/claude${NC}  (or just: cc)"
echo ""
echo -e "${CYAN}Commands:${NC}"
echo "  /project:status   — server health"
echo "  /project:deploy   — deploy service"
echo "  /project:logs     — analyze logs"
echo ""
echo -e "${CYAN}Workspace:${NC} $CLAUDE_WORKDIR"
echo ""
print_success "Done! 🚀"
