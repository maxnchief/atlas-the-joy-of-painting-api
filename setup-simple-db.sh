#!/bin/bash

# Joy of Painting Database - Simple Docker Setup
# This script sets up a local PostgreSQL database using Docker directly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Joy of Painting Database Setup (Docker) ===${NC}\n"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed${NC}"

# Stop and remove any existing joy_of_painting_db container
echo -e "${YELLOW}Cleaning up any existing containers...${NC}"
docker stop joy_of_painting_db 2>/dev/null || true
docker rm joy_of_painting_db 2>/dev/null || true

# Remove any existing volume (to ensure clean start)
docker volume rm joy_postgres_data 2>/dev/null || true

# Start PostgreSQL container
echo -e "${YELLOW}Starting PostgreSQL database...${NC}"
docker run -d \
  --name joy_of_painting_db \
  --restart unless-stopped \
  -e POSTGRES_USER=joy_user \
  -e POSTGRES_PASSWORD=joy_painting_2024 \
  -e POSTGRES_DB=joy_of_painting \
  -p 5432:5432 \
  -v joy_postgres_data:/var/lib/postgresql/data \
  postgres:14-alpine

# Wait for PostgreSQL to be ready
echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
sleep 15

# Test connection
echo -e "${YELLOW}Testing database connection...${NC}"
if docker exec joy_of_painting_db pg_isready -U joy_user -d joy_of_painting; then
    echo -e "${GREEN}✓ PostgreSQL is running successfully!${NC}"
    
    # Load the database schema and data
    echo -e "${YELLOW}Loading database schema and data...${NC}"
    
    # Copy SQL files to container and execute them in order
    for sql_file in 01_create_schema.sql 02_insert_master_data.sql 03_insert_episodes.sql 04_insert_episode_colors.sql 05_insert_episode_elements.sql; do
        if [ -f "$sql_file" ]; then
            echo -e "${YELLOW}Loading $sql_file...${NC}"
            docker cp "$sql_file" joy_of_painting_db:/tmp/
            docker exec joy_of_painting_db psql -U joy_user -d joy_of_painting -f "/tmp/$sql_file"
        else
            echo -e "${YELLOW}Warning: $sql_file not found, skipping...${NC}"
        fi
    done
    
    echo -e "\n${BLUE}=== Database Connection Details ===${NC}"
    echo -e "Host: ${GREEN}localhost${NC}"
    echo -e "Port: ${GREEN}5432${NC}"
    echo -e "Database: ${GREEN}joy_of_painting${NC}"
    echo -e "Username: ${GREEN}joy_user${NC}"
    echo -e "Password: ${GREEN}joy_painting_2024${NC}"
    
    echo -e "\n${BLUE}=== Connection String ===${NC}"
    echo -e "${GREEN}postgresql://joy_user:joy_painting_2024@localhost:5432/joy_of_painting${NC}"
    
    echo -e "\n${BLUE}=== Useful Commands ===${NC}"
    echo -e "Connect via psql: ${YELLOW}psql postgresql://joy_user:joy_painting_2024@localhost:5432/joy_of_painting${NC}"
    echo -e "Stop database: ${YELLOW}docker stop joy_of_painting_db${NC}"
    echo -e "Start database: ${YELLOW}docker start joy_of_painting_db${NC}"
    echo -e "View logs: ${YELLOW}docker logs joy_of_painting_db${NC}"
    echo -e "Remove database: ${YELLOW}docker rm -f joy_of_painting_db && docker volume rm joy_postgres_data${NC}"
    
    # Test a simple query
    echo -e "\n${YELLOW}Testing with a simple query...${NC}"
    docker exec joy_of_painting_db psql -U joy_user -d joy_of_painting -c "SELECT COUNT(*) as episode_count FROM episodes;" || echo -e "${YELLOW}Schema not loaded yet, that's okay!${NC}"
    
else
    echo -e "${RED}✗ Failed to start PostgreSQL${NC}"
    echo -e "${YELLOW}Check logs with: docker logs joy_of_painting_db${NC}"
    exit 1
fi

echo -e "\n${GREEN}=== Setup Complete! ===${NC}"
echo -e "${BLUE}Your Joy of Painting database is now running locally on localhost:5432${NC}"
