#!/bin/bash

# Joy of Painting Database - Native PostgreSQL Setup
# This script sets up the database on your existing PostgreSQL installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Joy of Painting Database Setup (Native PostgreSQL) ===${NC}\n"

# Check if PostgreSQL is running
if ! sudo -u postgres pg_isready &> /dev/null; then
    echo -e "${RED}PostgreSQL is not running. Please start it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ PostgreSQL is running${NC}"

# Create the joy_user if it doesn't exist
echo -e "${YELLOW}Creating database user 'joy_user'...${NC}"
sudo -u postgres psql -c "CREATE USER joy_user WITH PASSWORD 'joy_painting_2024';" 2>/dev/null || echo -e "${YELLOW}User already exists, updating password...${NC}"
sudo -u postgres psql -c "ALTER USER joy_user WITH PASSWORD 'joy_painting_2024';"

# Create the database
echo -e "${YELLOW}Creating database 'joy_of_painting'...${NC}"
sudo -u postgres createdb -O joy_user joy_of_painting 2>/dev/null || echo -e "${YELLOW}Database already exists${NC}"

# Grant necessary permissions
echo -e "${YELLOW}Setting up permissions...${NC}"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE joy_of_painting TO joy_user;"

# Load the schema and data
echo -e "${YELLOW}Loading database schema and data...${NC}"

# Copy SQL files to accessible location
echo -e "${YELLOW}Copying SQL files to accessible location...${NC}"
sudo cp *.sql /tmp/ 2>/dev/null || echo -e "${YELLOW}Some SQL files may not exist${NC}"

# Execute SQL files in order
for sql_file in 01_create_schema.sql 02_insert_master_data.sql 03_insert_episodes.sql 04_insert_episode_colors.sql 05_insert_episode_elements.sql; do
    if [ -f "/tmp/$sql_file" ]; then
        echo -e "${YELLOW}Loading $sql_file...${NC}"
        sudo -u postgres psql -d joy_of_painting -f "/tmp/$sql_file"
    else
        echo -e "${YELLOW}Warning: $sql_file not found, skipping...${NC}"
    fi
done

# Test the connection
echo -e "${YELLOW}Testing connection...${NC}"
if psql postgresql://joy_user:joy_painting_2024@localhost:5432/joy_of_painting -c "SELECT COUNT(*) as episode_count FROM episodes;" &> /dev/null; then
    echo -e "${GREEN}✓ Connection test successful!${NC}"
    
    echo -e "\n${BLUE}=== Database Connection Details ===${NC}"
    echo -e "Host: ${GREEN}localhost${NC}"
    echo -e "Port: ${GREEN}5432${NC}"
    echo -e "Database: ${GREEN}joy_of_painting${NC}"
    echo -e "Username: ${GREEN}joy_user${NC}"
    echo -e "Password: ${GREEN}joy_painting_2024${NC}"
    
    echo -e "\n${BLUE}=== Connection String ===${NC}"
    echo -e "${GREEN}postgresql://joy_user:joy_painting_2024@localhost:5432/joy_of_painting${NC}"
    
    echo -e "\n${BLUE}=== Test Query Results ===${NC}"
    psql postgresql://joy_user:joy_painting_2024@localhost:5432/joy_of_painting -c "
    SELECT 'Episodes:' as table_name, COUNT(*) as count FROM episodes
    UNION ALL
    SELECT 'Colors:', COUNT(*) FROM colors
    UNION ALL  
    SELECT 'Subject Elements:', COUNT(*) FROM subject_elements;"
    
else
    echo -e "${RED}✗ Connection test failed${NC}"
    echo -e "${YELLOW}You may need to configure PostgreSQL authentication${NC}"
    echo -e "${YELLOW}Check your pg_hba.conf file for local authentication settings${NC}"
    exit 1
fi

echo -e "\n${GREEN}=== Setup Complete! ===${NC}"
echo -e "${BLUE}Your Joy of Painting database is ready on your local PostgreSQL server.${NC}"
