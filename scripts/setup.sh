#!/bin/bash
# Headscale Setup Script

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Headscale + Tailscale Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if .env exists
if [ -f .env ]; then
    echo -e "${YELLOW}Warning: .env file already exists${NC}"
    read -p "Do you want to reconfigure? (yes/no): " reconfigure
    if [ "$reconfigure" != "yes" ]; then
        echo "Using existing configuration"
    else
        rm .env
    fi
fi

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${GREEN}Creating configuration...${NC}"

    read -p "Enter your domain (e.g., headscale.example.com): " domain
    read -p "Enter PostgreSQL password (or press Enter for random): " db_password

    if [ -z "$db_password" ]; then
        db_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        echo -e "${YELLOW}Generated random password${NC}"
    fi

    cat > .env << EOF
# Headscale Domain Configuration
HEADSCALE_DOMAIN=${domain}

# PostgreSQL Database Configuration
POSTGRES_DB=headscale
POSTGRES_USER=headscale
POSTGRES_PASSWORD=${db_password}

# Timezone
TZ=UTC
EOF

    echo -e "${GREEN}.env file created${NC}"

    # Update config.yaml with domain and password
    if [ -f config/config.yaml ]; then
        sed -i.bak "s|server_url: .*|server_url: https://${domain}:443|g" config/config.yaml
        sed -i.bak "s|password: .*|password: ${db_password}|g" config/config.yaml
        rm config/config.yaml.bak
        echo -e "${GREEN}Updated config.yaml with your settings${NC}"
    fi
fi

echo ""
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}Docker and Docker Compose are installed${NC}"

echo ""
echo -e "${BLUE}Starting services...${NC}"

# Pull images
docker compose pull

# Start services
docker compose up -d

echo ""
echo -e "${GREEN}Services started successfully!${NC}"
echo ""

# Wait for services to be healthy
echo -e "${BLUE}Waiting for services to be ready...${NC}"
sleep 10

# Check if services are running
if docker compose ps | grep -q "Up"; then
    echo -e "${GREEN}All services are running${NC}"
else
    echo -e "${RED}Some services failed to start${NC}"
    docker compose ps
    exit 1
fi

echo ""
echo -e "${BLUE}Creating default user...${NC}"

# Create default user
if docker exec headscale headscale users list | grep -q "default"; then
    echo -e "${YELLOW}User 'default' already exists${NC}"
else
    docker exec headscale headscale users create default
    echo -e "${GREEN}User 'default' created${NC}"
fi

echo ""
echo -e "${BLUE}Generating pre-auth key...${NC}"

# Generate pre-auth key
PREAUTH_KEY=$(docker exec headscale headscale preauthkeys create --user default --reusable --expiration 24h | grep -oP 'key: \K.*')

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Important Information:${NC}"
echo ""
echo -e "Domain:           ${BLUE}$(grep HEADSCALE_DOMAIN .env | cut -d'=' -f2)${NC}"
echo -e "Pre-auth Key:     ${BLUE}${PREAUTH_KEY}${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Make sure your domain DNS points to this server"
echo "2. Connect a device using:"
echo ""
echo -e "   ${BLUE}sudo tailscale up --login-server https://$(grep HEADSCALE_DOMAIN .env | cut -d'=' -f2) --authkey ${PREAUTH_KEY}${NC}"
echo ""
echo "3. Check status with: ./headscale.sh status"
echo "4. View logs with: ./headscale.sh logs"
echo ""
echo -e "For more commands, run: ${BLUE}./headscale.sh help${NC}"
echo ""
