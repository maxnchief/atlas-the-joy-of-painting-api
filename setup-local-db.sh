#!/bin/bash

# Joy of Painting Database - Local Setup Script
# This script sets up a local PostgreSQL database for the Joy of Painting API

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Joy of Painting Database Local Setup ===${NC}\n"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✓ Docker and Docker Compose are installed${NC}"

# Create sql directory if it doesn't exist
mkdir -p sql

# Copy SQL files to sql directory
echo -e "${YELLOW}Copying SQL files...${NC}"
cp *.sql sql/ 2>/dev/null || echo -e "${YELLOW}No SQL files found in current directory${NC}"

# Start the database
echo -e "${YELLOW}Starting PostgreSQL database...${NC}"
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
sleep 10

# Check if database is running
if docker-compose ps postgres | grep -q "Up"; then
    echo -e "${GREEN}✓ PostgreSQL is running successfully!${NC}"
    
    echo -e "\n${BLUE}=== Database Connection Details ===${NC}"
    echo -e "Host: ${GREEN}localhost${NC}"
    echo -e "Port: ${GREEN}5432${NC}"
    echo -e "Database: ${GREEN}joy_of_painting${NC}"
    echo -e "Username: ${GREEN}joy_user${NC}"
    echo -e "Password: ${GREEN}joy_painting_2024${NC}"
    
    echo -e "\n${BLUE}=== Connection String ===${NC}"
    echo -e "${GREEN}postgresql://joy_user:joy_painting_2024@localhost:5432/joy_of_painting${NC}"
    
    echo -e "\n${BLUE}=== Management Tools ===${NC}"
    echo -e "Start pgAdmin: ${YELLOW}docker-compose up -d pgadmin${NC}"
    echo -e "pgAdmin URL: ${GREEN}http://localhost:8080${NC}"
    echo -e "pgAdmin Email: ${GREEN}admin@joyofpainting.local${NC}"
    echo -e "pgAdmin Password: ${GREEN}admin123${NC}"
    
    echo -e "\n${BLUE}=== Useful Commands ===${NC}"
    echo -e "Connect via psql: ${YELLOW}psql postgresql://joy_user:joy_painting_2024@localhost:5432/joy_of_painting${NC}"
    echo -e "Stop database: ${YELLOW}docker-compose down${NC}"
    echo -e "View logs: ${YELLOW}docker-compose logs postgres${NC}"
    echo -e "Backup database: ${YELLOW}./backup-db.sh${NC}"
    
else
    echo -e "${RED}✗ Failed to start PostgreSQL${NC}"
    echo -e "${YELLOW}Check logs with: docker-compose logs postgres${NC}"
    exit 1
fi

echo -e "\n${GREEN}=== Setup Complete! ===${NC}"
echo -e "${BLUE}Your Joy of Painting database is now running locally.${NC}"
