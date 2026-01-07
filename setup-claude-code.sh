#!/bin/bash
#
# Claude Code Universal VPS Setup Script
# Usage: curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/setup-claude-code.sh | bash
#
# Author: Vyacheslav
# Version: 2.0.0
# Updated: January 2026
#
# Features:
#   - Auto-discovers existing services and projects
#   - Flexible permissions for ~/  and /opt/
#   - Dynamic CLAUDE.md generation based on actual server state
#   - No hardcoded directory structure assumptions
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
CLAUDE_CONFIG_DIR="$HOME/.claude"
INSTALL_NODEJS=false

# ============================================
# PRE-FLIGHT CHECKS
# ============================================
print_header "Claude Code Universal VPS Setup"

echo -e "${CYAN}This script will:${NC}"
echo "  • Install Claude Code CLI (native binary preferred)"
echo "  • Auto-discover existing services and projects"
echo "  • Generate dynamic CLAUDE.md with server context"
echo "  • Configure flexible permissions for ~/ and /opt/"
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

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

if curl -fsSL https://claude.ai/install.sh | bash 2>/dev/null; then
    if ! grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null; then
        echo '' >> "$HOME/.bashrc"
        echo '# Claude Code' >> "$HOME/.bashrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    fi
    print_success "Claude Code installed via native binary"
else
    print_warning "Native binary failed. Installing Node.js + npm as fallback..."
    INSTALL_NODEJS=true

    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - > /dev/null 2>&1
    sudo apt-get install -y -qq nodejs > /dev/null 2>&1

    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global"
    export PATH="$HOME/.npm-global/bin:$PATH"

    if ! grep -q 'npm-global' "$HOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
    fi

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
# GATHER SYSTEM INFO
# ============================================
print_header "Discovering Server Environment"

HOSTNAME=$(hostname)
IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}' || curl -s ifconfig.me 2>/dev/null || echo "unknown")
PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "")
TOTAL_MEM=$(free -h | awk '/^Mem:/ {print $2}')
TOTAL_DISK=$(df -h / | awk 'NR==2 {print $2}')
CPU_CORES=$(nproc)
CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || echo "unknown")

# Detect installed services
DOCKER_INSTALLED=$(command -v docker &> /dev/null && echo "yes" || echo "no")
NGINX_INSTALLED=$(command -v nginx &> /dev/null && echo "yes" || echo "no")
APACHE_INSTALLED=$(command -v apache2 &> /dev/null && echo "yes" || echo "no")
MYSQL_INSTALLED=$(command -v mysql &> /dev/null && echo "yes" || echo "no")
POSTGRES_INSTALLED=$(command -v psql &> /dev/null && echo "yes" || echo "no")
REDIS_INSTALLED=$(command -v redis-cli &> /dev/null && echo "yes" || echo "no")
JAVA_INSTALLED=$(command -v java &> /dev/null && echo "yes" || echo "no")

print_step "Scanning for projects and services..."

# ============================================
# AUTO-DISCOVER PROJECTS
# ============================================
DISCOVERED_PROJECTS=""
DOCKER_COMPOSE_LOCATIONS=""
MINECRAFT_SERVERS=""
MEDIA_SERVERS=""

# Find docker-compose files
if [ "$DOCKER_INSTALLED" = "yes" ]; then
    while IFS= read -r file; do
        [ -n "$file" ] && DOCKER_COMPOSE_LOCATIONS="${DOCKER_COMPOSE_LOCATIONS}\n  - $(dirname "$file")"
    done < <(find /opt /home /srv /var 2>/dev/null -name "docker-compose.yml" -o -name "docker-compose.yaml" -o -name "compose.yml" -o -name "compose.yaml" 2>/dev/null | head -20)
fi

# Find Minecraft servers (by server.properties or eula.txt)
while IFS= read -r file; do
    if [ -n "$file" ]; then
        dir=$(dirname "$file")
        MINECRAFT_SERVERS="${MINECRAFT_SERVERS}\n  - $dir"
    fi
done < <(find /opt /home /srv 2>/dev/null -name "server.properties" 2>/dev/null | head -10)

# Detect media servers
[ -d "/var/lib/jellyfin" ] || [ -d "/opt/jellyfin" ] && MEDIA_SERVERS="${MEDIA_SERVERS}\n  - Jellyfin"
[ -d "/var/lib/plexmediaserver" ] || [ -d "/opt/plex" ] && MEDIA_SERVERS="${MEDIA_SERVERS}\n  - Plex"
[ -d "/opt/emby" ] && MEDIA_SERVERS="${MEDIA_SERVERS}\n  - Emby"

# Find project directories (containing .git, package.json, requirements.txt, etc.)
while IFS= read -r file; do
    [ -n "$file" ] && DISCOVERED_PROJECTS="${DISCOVERED_PROJECTS}\n  - $(dirname "$file")"
done < <(find /opt /home/$USER 2>/dev/null -maxdepth 3 \( -name ".git" -o -name "package.json" -o -name "requirements.txt" -o -name "Cargo.toml" -o -name "go.mod" \) 2>/dev/null | head -20)

# Running Docker containers
RUNNING_CONTAINERS=""
if [ "$DOCKER_INSTALLED" = "yes" ] && docker ps --format '{{.Names}}' 2>/dev/null | head -10 > /tmp/containers.txt; then
    while IFS= read -r container; do
        [ -n "$container" ] && RUNNING_CONTAINERS="${RUNNING_CONTAINERS}\n  - $container"
    done < /tmp/containers.txt
    rm -f /tmp/containers.txt
fi

# Listening ports
LISTENING_PORTS=$(ss -tlnp 2>/dev/null | awk 'NR>1 {print $4}' | grep -oE '[0-9]+$' | sort -un | head -15 | tr '\n' ' ' || echo "unknown")

print_success "Discovery complete"

# ============================================
# CREATE CLAUDE CONFIGURATION DIRECTORY
# ============================================
print_header "Creating Configuration"

mkdir -p "$CLAUDE_CONFIG_DIR/commands"

# ============================================
# CREATE CLAUDE.md (Dynamic)
# ============================================
cat > "$HOME/CLAUDE.md" << EOF
# VPS Administration Assistant

## Server Information
| Property | Value |
|----------|-------|
| Hostname | $HOSTNAME |
| OS | $OS $OS_VERSION |
| Internal IP | $IP_ADDR |
| Public IP | ${PUBLIC_IP:-"N/A"} |
| CPU | $CPU_CORES cores ($CPU_MODEL) |
| Memory | $TOTAL_MEM |
| Disk | $TOTAL_DISK |
| User | $USER |

## Installed Services
| Service | Status |
|---------|--------|
| Docker | $DOCKER_INSTALLED |
| Nginx | $NGINX_INSTALLED |
| Apache | $APACHE_INSTALLED |
| MySQL | $MYSQL_INSTALLED |
| PostgreSQL | $POSTGRES_INSTALLED |
| Redis | $REDIS_INSTALLED |
| Java | $JAVA_INSTALLED |
EOF

# Add discovered sections dynamically
if [ -n "$DOCKER_COMPOSE_LOCATIONS" ]; then
    echo -e "\n## Docker Compose Projects" >> "$HOME/CLAUDE.md"
    echo -e "$DOCKER_COMPOSE_LOCATIONS" >> "$HOME/CLAUDE.md"
fi

if [ -n "$RUNNING_CONTAINERS" ]; then
    echo -e "\n## Running Containers" >> "$HOME/CLAUDE.md"
    echo -e "$RUNNING_CONTAINERS" >> "$HOME/CLAUDE.md"
fi

if [ -n "$MINECRAFT_SERVERS" ]; then
    echo -e "\n## Minecraft Servers" >> "$HOME/CLAUDE.md"
    echo -e "$MINECRAFT_SERVERS" >> "$HOME/CLAUDE.md"
fi

if [ -n "$MEDIA_SERVERS" ]; then
    echo -e "\n## Media Servers" >> "$HOME/CLAUDE.md"
    echo -e "$MEDIA_SERVERS" >> "$HOME/CLAUDE.md"
fi

if [ -n "$DISCOVERED_PROJECTS" ]; then
    echo -e "\n## Discovered Projects" >> "$HOME/CLAUDE.md"
    echo -e "$DISCOVERED_PROJECTS" >> "$HOME/CLAUDE.md"
fi

cat >> "$HOME/CLAUDE.md" << EOF

## Active Ports
$LISTENING_PORTS

## Guidelines
- Store secrets in .env files (never commit them)
- Use Docker Compose for containerized services
- Ask before destructive operations (rm -rf, DROP, etc.)
- Use Let's Encrypt for SSL certificates
- Check logs before making assumptions about issues

## Common Locations
- /opt/ — System-wide applications and services
- /home/$USER/ — User files and projects
- /var/log/ — System and service logs
- /etc/ — Configuration files (read carefully before editing)

## Quick Commands Reference
\`\`\`bash
# Docker
docker ps                    # List running containers
docker compose logs -f       # Follow logs
docker compose up -d         # Start services
docker compose down          # Stop services

# System
htop                         # Interactive process viewer
df -h                        # Disk usage
free -h                      # Memory usage
journalctl -f                # Follow system logs
ss -tlnp                     # Listening ports
\`\`\`
EOF

print_success "Created ~/CLAUDE.md with discovered services"

# ============================================
# CREATE SETTINGS.JSON (Flexible Permissions)
# ============================================
cat > "$CLAUDE_CONFIG_DIR/settings.json" << 'EOF'
{
  "permissions": {
    "allow": [
      "Read",
      "Write(~/**)",
      "Write(/opt/**)",
      "Write(/srv/**)",
      "Bash(docker *)",
      "Bash(docker compose *)",
      "Bash(docker-compose *)",
      "Bash(systemctl *)",
      "Bash(journalctl *)",
      "Bash(htop)",
      "Bash(top)",
      "Bash(df *)",
      "Bash(free *)",
      "Bash(cat *)",
      "Bash(tail *)",
      "Bash(head *)",
      "Bash(less *)",
      "Bash(grep *)",
      "Bash(find *)",
      "Bash(ls *)",
      "Bash(ps *)",
      "Bash(ss *)",
      "Bash(netstat *)",
      "Bash(ip *)",
      "Bash(git *)",
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(tar *)",
      "Bash(unzip *)",
      "Bash(zip *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(mkdir *)",
      "Bash(chmod *)",
      "Bash(chown *)",
      "Bash(nano *)",
      "Bash(vim *)",
      "Bash(apt *)",
      "Bash(apt-get *)",
      "Bash(npm *)",
      "Bash(node *)",
      "Bash(python *)",
      "Bash(python3 *)",
      "Bash(pip *)",
      "Bash(pip3 *)",
      "Bash(java *)",
      "Bash(screen *)",
      "Bash(tmux *)",
      "Bash(crontab *)",
      "Bash(nginx *)",
      "Bash(certbot *)",
      "Bash(ufw *)"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(rm -rf /*)",
      "Bash(rm -rf /home)",
      "Bash(rm -rf /opt)",
      "Bash(dd if=*)",
      "Bash(mkfs*)",
      "Bash(:(){ :|:& };:)",
      "Write(/etc/passwd)",
      "Write(/etc/shadow)",
      "Read(/etc/shadow)"
    ]
  }
}
EOF

print_success "Created flexible permissions (~/**, /opt/**, /srv/**)"

# ============================================
# CREATE CUSTOM COMMANDS
# ============================================
cat > "$CLAUDE_CONFIG_DIR/commands/status.md" << 'EOF'
Comprehensive server health check:
1. `df -h` — disk space on all mounts
2. `free -h` — memory usage
3. `uptime` — load average
4. `docker ps 2>/dev/null` — running containers (if docker installed)
5. `systemctl list-units --state=failed 2>/dev/null` — failed services
6. `ss -tlnp | head -20` — listening ports

Summarize overall health status with any warnings or issues.
EOF

cat > "$CLAUDE_CONFIG_DIR/commands/discover.md" << 'EOF'
Discover and list all services/projects on this server:

1. Find Docker Compose files:
   `find /opt /home /srv -name "docker-compose*.yml" -o -name "compose*.yml" 2>/dev/null`

2. List running Docker containers:
   `docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null`

3. Find project directories:
   `find /opt /home -maxdepth 3 \( -name ".git" -o -name "package.json" \) 2>/dev/null`

4. Check systemd services:
   `systemctl list-units --type=service --state=running | head -20`

5. Check listening ports:
   `ss -tlnp`

Provide a summary of all discovered services and their locations.
EOF

cat > "$CLAUDE_CONFIG_DIR/commands/logs.md" << 'EOF'
Analyze logs for: $ARGUMENTS

If $ARGUMENTS is a Docker container or compose project:
  `docker compose logs --tail=100 $ARGUMENTS 2>/dev/null || docker logs --tail=100 $ARGUMENTS 2>/dev/null`

If $ARGUMENTS is a systemd service:
  `journalctl -u $ARGUMENTS --since "1 hour ago" | tail -100`

If $ARGUMENTS is a path:
  `tail -100 $ARGUMENTS`

General system logs:
  `journalctl --since "1 hour ago" -p err | tail -50`

Find errors, warnings, and provide actionable recommendations.
EOF

cat > "$CLAUDE_CONFIG_DIR/commands/backup.md" << 'EOF'
Create a backup of: $ARGUMENTS

1. Determine what to backup based on $ARGUMENTS
2. Create timestamped backup: `tar -czvf backup_$(date +%Y%m%d_%H%M%S).tar.gz $ARGUMENTS`
3. If it's a database, use appropriate dump command:
   - MySQL: `mysqldump`
   - PostgreSQL: `pg_dump`
4. Verify backup integrity
5. Report backup size and location
EOF

print_success "Created commands: status, discover, logs, backup"

# ============================================
# TMUX CONFIG
# ============================================
if [ ! -f "$HOME/.tmux.conf" ]; then
    cat > "$HOME/.tmux.conf" << 'EOF'
set -g mouse on
set -g prefix C-a
unbind C-b
bind C-a send-prefix
set -g base-index 1
setw -g pane-base-index 1
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D
set -g history-limit 50000
set -g status-style 'bg=#333333 fg=#ffffff'
set -g status-right '%H:%M '
EOF
    print_success "Created tmux config"
else
    print_warning "Existing tmux config preserved"
fi

# ============================================
# QUICK START SCRIPT
# ============================================
cat > "$HOME/start-claude" << 'EOF'
#!/bin/bash
# Start Claude Code in a tmux session
cd ~
if tmux has-session -t claude 2>/dev/null; then
    tmux attach -t claude
else
    tmux new-session -s claude -n main "claude; bash"
fi
EOF
chmod +x "$HOME/start-claude"

# Aliases (avoid duplicates)
if ! grep -q 'alias cc=' "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" << 'EOF'

# Claude Code aliases
alias cc="~/start-claude"
alias claude-discover="claude '/project:discover'"
alias claude-status="claude '/project:status'"
EOF
fi

print_success "Created ~/start-claude script and aliases"

# ============================================
# UPDATE CLAUDE.md SCRIPT (for re-discovery)
# ============================================
cat > "$HOME/update-claude-context" << 'SCRIPT'
#!/bin/bash
# Re-run discovery and update CLAUDE.md
# Run this after installing new services

echo "Updating Claude context..."

# Quick discovery
DOCKER_COMPOSE_LOCATIONS=$(find /opt /home /srv 2>/dev/null -name "docker-compose*.yml" -o -name "compose*.yml" 2>/dev/null | head -20 | while read f; do dirname "$f"; done | sort -u)
RUNNING_CONTAINERS=$(docker ps --format '{{.Names}}' 2>/dev/null | head -10)

echo "Found Docker Compose projects:"
echo "$DOCKER_COMPOSE_LOCATIONS"
echo ""
echo "Running containers:"
echo "$RUNNING_CONTAINERS"
echo ""
echo "To fully regenerate CLAUDE.md, re-run the setup script."
SCRIPT
chmod +x "$HOME/update-claude-context"

print_success "Created ~/update-claude-context helper"

# ============================================
# SUMMARY
# ============================================
print_header "Installation Complete!"

echo -e "${GREEN}${BOLD}Claude Code installed successfully!${NC}\n"

if [ "$INSTALL_NODEJS" = true ]; then
    echo -e "${YELLOW}Note: Installed via npm (Node.js fallback)${NC}\n"
fi

echo -e "${CYAN}Quick Start:${NC}"
echo "  1. ${YELLOW}source ~/.bashrc${NC}"
echo "  2. ${YELLOW}export ANTHROPIC_API_KEY=\"your-key\"${NC}"
echo "  3. ${YELLOW}~/start-claude${NC}  (or just: ${BOLD}cc${NC})"
echo ""

echo -e "${CYAN}Slash Commands:${NC}"
echo "  /project:status    — Server health check"
echo "  /project:discover  — Find all services/projects"
echo "  /project:logs      — Analyze logs"
echo "  /project:backup    — Create backups"
echo ""

echo -e "${CYAN}Files Created:${NC}"
echo "  ~/CLAUDE.md              — Server context for Claude"
echo "  ~/.claude/settings.json  — Permissions config"
echo "  ~/.claude/commands/      — Custom slash commands"
echo "  ~/start-claude           — Quick launcher"
echo "  ~/update-claude-context  — Re-discover services"
echo ""

echo -e "${CYAN}Permissions:${NC}"
echo "  • Full access to ~/ and /opt/ and /srv/"
echo "  • Docker, systemctl, common tools allowed"
echo "  • Destructive commands blocked by default"
echo ""

# Show discovered items
if [ -n "$DOCKER_COMPOSE_LOCATIONS" ] || [ -n "$RUNNING_CONTAINERS" ] || [ -n "$MINECRAFT_SERVERS" ]; then
    echo -e "${CYAN}Discovered on this server:${NC}"
    [ -n "$DOCKER_COMPOSE_LOCATIONS" ] && echo -e "  Docker Compose:$DOCKER_COMPOSE_LOCATIONS"
    [ -n "$RUNNING_CONTAINERS" ] && echo -e "  Containers:$RUNNING_CONTAINERS"
    [ -n "$MINECRAFT_SERVERS" ] && echo -e "  Minecraft:$MINECRAFT_SERVERS"
    [ -n "$MEDIA_SERVERS" ] && echo -e "  Media Servers:$MEDIA_SERVERS"
    echo ""
fi

print_success "Done!"
