# Joy of Painting API - Setup & Testing Guide

## Quick Start

### 1. Set up the Database
```bash
# Make setup script executable and run it
chmod +x setup-local-db.sh
./setup-local-db.sh

# Initialize the database with schema and data
docker exec -i joy_of_painting_db psql -U joy_user -d joy_of_painting < sql/01_create_schema.sql
docker exec -i joy_of_painting_db psql -U joy_user -d joy_of_painting < sql/02_insert_master_data.sql
docker exec -i joy_of_painting_db psql -U joy_user -d joy_of_painting < sql/03_insert_episodes.sql
docker exec -i joy_of_painting_db psql -U joy_user -d joy_of_painting < sql/04_insert_episode_colors.sql
docker exec -i joy_of_painting_db psql -U joy_user -d joy_of_painting < sql/05_insert_episode_elements.sql
```

### 2. Install API Dependencies
```bash
npm install
```

### 3. Start the API Server
```bash
# Development mode (with auto-restart)
npm run dev

# Or production mode
npm start
```

The API will be available at: `http://localhost:3000`

## Testing with Postman

### Option 1: Import Collection File
1. Open Postman
2. Click "Import" button
3. Select `Joy_of_Painting_API.postman_collection.json`
4. The collection will be imported with all endpoints ready to test

### Option 2: Manual Setup

#### Base URL
Set up an environment variable in Postman:
- Variable: `base_url`
- Value: `http://localhost:3000`

#### Test Endpoints

1. **Health Check**
   ```
   GET {{base_url}}/health
   ```

2. **API Documentation**
   ```
   GET {{base_url}}/
   ```

3. **Get All Mountain Episodes** (Your Original Request)
   ```
   GET {{base_url}}/subjects/mountain
   ```

4. **Filter Episodes by Subject**
   ```
   GET {{base_url}}/episodes?subject=MOUNTAIN,WATERFALL
   ```

5. **Filter Episodes by Season**
   ```
   GET {{base_url}}/episodes?season=1
   ```

6. **Filter Episodes by Paint Colors**
   ```
   GET {{base_url}}/episodes?color=Titanium White,Prussian Blue
   ```

7. **Search Episodes by Title**
   ```
   GET {{base_url}}/episodes/search?q=mountain
   ```

## API Endpoints Reference

### Episodes
- `GET /episodes` - Get all episodes with optional filtering
- `GET /episodes/:id` - Get specific episode by ID
- `GET /episodes/search?q=query` - Search episodes by title

### Subject Matter
- `GET /subjects` - Get all subject elements with episode counts
- `GET /subjects/mountain` - Get all episodes with mountain subject matter

### Colors
- `GET /colors` - Get all paint colors with episode counts

### Utility
- `GET /health` - Health check
- `GET /stats` - Database statistics
- `GET /` - API documentation

## Query Parameters

### Filtering Episodes (`/episodes`)
- `season` - Filter by season number (1-31)
- `subject` - Filter by subject matter (comma-separated, e.g., "MOUNTAIN,TREE")
- `color` - Filter by paint colors (comma-separated, e.g., "Titanium White,Prussian Blue")
- `month` - Filter by broadcast month (1-12)
- `year` - Filter by broadcast year
- `limit` - Number of results per page (default: 50)
- `offset` - Number of results to skip (default: 0)

### Examples
```
# Get all mountain episodes from season 1
GET /episodes?season=1&subject=MOUNTAIN

# Get episodes using Titanium White and broadcast in January
GET /episodes?color=Titanium White&month=1

# Get first 10 episodes with pagination
GET /episodes?limit=10&offset=0
```

## Response Format

All endpoints return JSON responses:

```json
{
  "episodes": [...],
  "total": 25,
  "page": 1,
  "limit": 50
}
```

## Troubleshooting

### Database Connection Issues
- Ensure PostgreSQL container is running: `docker ps`
- Check connection details in `.env` file
- Verify database exists: `docker exec joy_of_painting_db psql -U joy_user -l`

### API Issues
- Check if API is running: `curl http://localhost:3000/health`
- View API logs in terminal
- Ensure port 3000 is not in use by another application

### Postman Issues
- Verify base URL is set correctly
- Check that Content-Type is set to `application/json` for POST requests (if added later)
- Ensure no authentication is required for GET requests
