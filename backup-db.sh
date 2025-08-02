#!/bin/bash

# Joy of Painting Database - Backup Script
# Creates a backup of the local PostgreSQL database

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create backup directory
mkdir -p backups

# Generate timestamp for backup filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backups/joy_of_painting_backup_${TIMESTAMP}.sql"

echo -e "${BLUE}=== Joy of Painting Database Backup ===${NC}\n"
echo -e "${YELLOW}Creating backup...${NC}"

# Create the backup
docker exec joy_of_painting_db pg_dump -U joy_user -d joy_of_painting > "${BACKUP_FILE}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Backup created successfully!${NC}"
    echo -e "Backup location: ${GREEN}${BACKUP_FILE}${NC}"
    
    # Show backup size
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    echo -e "Backup size: ${GREEN}${BACKUP_SIZE}${NC}"
    
    # Keep only last 5 backups
    echo -e "\n${YELLOW}Cleaning up old backups (keeping last 5)...${NC}"
    ls -t backups/joy_of_painting_backup_*.sql | tail -n +6 | xargs -r rm
    
    echo -e "${GREEN}✓ Backup process complete!${NC}"
else
    echo -e "${RED}✗ Backup failed${NC}"
    exit 1
fi
