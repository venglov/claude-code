#!/bin/bash
#
# Claude Code Minimal Setup (Native Binary)
# Usage: curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/setup-claude-code-minimal.sh | bash
#

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}[1/4]${NC} Installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq curl git tmux ripgrep > /dev/null 2>&1

echo -e "${CYAN}[2/4]${NC} Installing Claude Code (native binary)..."
mkdir -p ~/.local/bin
curl -fsSL https://claude.ai/install.sh | bash 2>/dev/null
grep -q '.local/bin' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"

echo -e "${CYAN}[3/4]${NC} Creating workspace..."
mkdir -p ~/claude-workspace/.claude/{commands,agents}
mkdir -p ~/services

cat > ~/claude-workspace/CLAUDE.md << EOF
# VPS Assistant
- OS: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
- Host: $(hostname)
- User: $(whoami)
- IP: $(hostname -I | awk '{print $1}')

## Rules
- Docker Compose for services
- Secrets in .env files
- Ask before rm -rf
EOF

cat > ~/claude-workspace/.claude/settings.json << 'EOF'
{"permissions":{"allow":["Read","Write(~/**)","Bash(docker *)","Bash(systemctl status *)","Bash(journalctl *)","Bash(df *)","Bash(free *)","Bash(cat *)","Bash(tail *)","Bash(grep *)","Bash(ls *)","Bash(git *)","Bash(curl *)"],"deny":["Bash(rm -rf /)","Write(/etc/*)","Read(/etc/shadow)"]}}
EOF

echo -e "${CYAN}[4/4]${NC} Creating shortcuts..."
cat > ~/claude << 'EOF'
#!/bin/bash
cd ~/claude-workspace
tmux has-session -t claude 2>/dev/null && tmux attach -t claude || tmux new-session -s claude
EOF
chmod +x ~/claude
grep -q 'alias cc=' ~/.bashrc || echo 'alias cc="~/claude"' >> ~/.bashrc

echo -e "\n${GREEN}✓ Done!${NC}"
echo -e "  1. ${YELLOW}source ~/.bashrc${NC}"
echo -e "  2. ${YELLOW}export ANTHROPIC_API_KEY=\"your-key\"${NC}"
echo -e "  3. ${YELLOW}~/claude${NC}"
