#!/bin/bash
# Setup script for Tailscale with Headscale on Linux (systemd)
# Run as root: sudo bash setup.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Tailscale Headscale Setup ===${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: Please run as root (sudo bash setup.sh)${NC}"
    exit 1
fi

# Configuration
read -p "Enter your Headscale server URL (e.g., http://localhost:8000): " LOGIN_SERVER
read -p "Enter your pre-auth key: " AUTH_KEY
read -p "Accept routes from other nodes? (y/n): " ACCEPT_ROUTES
read -p "Advertise as exit node? (y/n): " EXIT_NODE
read -p "Advertise routes (comma-separated, leave empty if none): " ROUTES

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    echo -e "${YELLOW}Tailscale not found. Installing...${NC}"
    curl -fsSL https://tailscale.com/install.sh | sh
fi

# Create environment file
ENV_FILE="/etc/default/tailscaled"
echo -e "${GREEN}Creating environment file at $ENV_FILE${NC}"

cat > "$ENV_FILE" <<EOF
# Tailscale Environment Configuration
TS_LOGIN_SERVER=$LOGIN_SERVER
TS_AUTHKEY=$AUTH_KEY
TS_STATE_DIR=/var/lib/tailscale
EOF

if [ "$ACCEPT_ROUTES" = "y" ]; then
    echo "TS_ACCEPT_ROUTES=true" >> "$ENV_FILE"
fi

if [ "$EXIT_NODE" = "y" ]; then
    echo "TS_EXIT_NODE=true" >> "$ENV_FILE"
fi

if [ -n "$ROUTES" ]; then
    echo "TS_ROUTES=$ROUTES" >> "$ENV_FILE"
fi

# Restart Tailscale service
echo -e "${GREEN}Restarting Tailscale service...${NC}"
systemctl restart tailscaled

# Wait a moment for service to start
sleep 2

# Connect to Headscale
echo -e "${GREEN}Connecting to Headscale...${NC}"

CMD="tailscale up --login-server=$LOGIN_SERVER --authkey=$AUTH_KEY"

if [ "$ACCEPT_ROUTES" = "y" ]; then
    CMD="$CMD --accept-routes"
fi

if [ "$EXIT_NODE" = "y" ]; then
    CMD="$CMD --advertise-exit-node"
fi

if [ -n "$ROUTES" ]; then
    CMD="$CMD --advertise-routes=$ROUTES"
fi

eval "$CMD"

echo -e "\n${GREEN}=== Setup Complete! ===${NC}"
echo -e "${GREEN}Tailscale is now connected to your Headscale server.${NC}\n"
echo -e "Check status with: ${YELLOW}tailscale status${NC}"
echo -e "View IP address: ${YELLOW}tailscale ip${NC}"
echo -e "Check connection: ${YELLOW}tailscale netcheck${NC}"
