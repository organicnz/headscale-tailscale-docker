#!/bin/bash
# Headscale Backup Script

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}Starting backup...${NC}"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL database
echo -e "${YELLOW}Backing up PostgreSQL database...${NC}"
docker exec headscale-db pg_dump -U headscale headscale > "$BACKUP_DIR/database_${TIMESTAMP}.sql"
echo -e "${GREEN}Database backed up to: $BACKUP_DIR/database_${TIMESTAMP}.sql${NC}"

# Backup configuration
echo -e "${YELLOW}Backing up configuration files...${NC}"
tar -czf "$BACKUP_DIR/config_${TIMESTAMP}.tar.gz" config/ .env
echo -e "${GREEN}Configuration backed up to: $BACKUP_DIR/config_${TIMESTAMP}.tar.gz${NC}"

# Backup Headscale data
if [ -d "data" ]; then
    echo -e "${YELLOW}Backing up Headscale data...${NC}"
    tar -czf "$BACKUP_DIR/data_${TIMESTAMP}.tar.gz" data/
    echo -e "${GREEN}Data backed up to: $BACKUP_DIR/data_${TIMESTAMP}.tar.gz${NC}"
fi

echo ""
echo -e "${GREEN}Backup completed successfully!${NC}"
echo -e "Backup location: ${BLUE}$BACKUP_DIR${NC}"

# Clean up old backups (keep last 7 days)
echo ""
echo -e "${YELLOW}Cleaning up old backups...${NC}"
find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
echo -e "${GREEN}Old backups cleaned up${NC}"
