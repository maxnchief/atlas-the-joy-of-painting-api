#!/bin/bash

# Joy of Painting Database - Restore Script
# Restores the database from a backup file

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Joy of Painting Database Restore ===${NC}\n"

# Check if backup file is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Usage: $0 <backup_file.sql>${NC}"
    echo -e "${YELLOW}Available backups:${NC}"
    ls -la backups/joy_of_painting_backup_*.sql 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Backup file not found: $BACKUP_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Restoring from: ${GREEN}$BACKUP_FILE${NC}"
echo -e "${RED}WARNING: This will replace all existing data!${NC}"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Restore cancelled.${NC}"
    exit 0
fi

# Drop and recreate database
echo -e "${YELLOW}Dropping existing database...${NC}"
docker exec joy_of_painting_db psql -U joy_user -d postgres -c "DROP DATABASE IF EXISTS joy_of_painting;"
docker exec joy_of_painting_db psql -U joy_user -d postgres -c "CREATE DATABASE joy_of_painting;"

# Restore from backup
echo -e "${YELLOW}Restoring database...${NC}"
docker exec -i joy_of_painting_db psql -U joy_user -d joy_of_painting < "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database restored successfully!${NC}"
else
    echo -e "${RED}✗ Restore failed${NC}"
    exit 1
fi
