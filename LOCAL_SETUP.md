# Joy of Painting API - Local Development Environment

## Database Configuration

### Connection Details
- **Host**: localhost
- **Port**: 5432
- **Database**: joy_of_painting
- **Username**: joy_user

### Connection String
```
postgresql://joy_user:joy_painting_2024@localhost:5432/joy_of_painting
```

## Environment Variables

Create a `.env` file in your project root with:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=joy_of_painting
DB_USER=joy_user
DB_PASSWORD=joy_painting_2024
DATABASE_URL=postgresql://joy_user:joy_painting_2024@localhost:5432/joy_of_painting

# API Configuration
PORT=3000
NODE_ENV=development

# CORS Configuration (adjust as needed)
CORS_ORIGIN=http://localhost:3000
```

## Quick Start

1. **Start Database**:
   ```bash
   chmod +x setup-local-db.sh
   ./setup-local-db.sh
   ```

2. **Connect via psql**:
   ```bash
   psql postgresql://joy_user:joy_painting_2024@localhost:5432/joy_of_painting
   ```

3. **Start pgAdmin** (optional):
   ```bash
   docker-compose up -d pgadmin
   # Access at: http://localhost:8080
   # Email: admin@joyofpainting.local
   # Password: admin123
   ```

## Database Management

### Backup Database
```bash
chmod +x backup-db.sh
./backup-db.sh
```

### Restore Database
```bash
chmod +x restore-db.sh
./restore-db.sh backups/joy_of_painting_backup_YYYYMMDD_HHMMSS.sql
```

### View Logs
```bash
docker-compose logs postgres
```

### Stop Database
```bash
docker-compose down
```

## Development Workflow

1. **Start database**: `./setup-local-db.sh`
2. **Develop your API** connecting to `localhost:5432`
3. **Test queries** using pgAdmin at `http://localhost:8080`
4. **Backup regularly**: `./backup-db.sh`
5. **Stop when done**: `docker-compose down`

## Production Considerations

For production deployment, consider:
- Change default passwords
- Use environment variables for sensitive data
- Set up SSL/TLS connections
- Configure proper backup schedules
- Use managed PostgreSQL services (AWS RDS, Google Cloud SQL, etc.)
