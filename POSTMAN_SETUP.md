# Joy of Painting API - Postman Testing Guide

## 🎨 API Overview
Your Joy of Painting API is now running locally! This guide will help you test all the endpoints using Postman.

**Server URL:** `http://localhost:3000`
**Database:** PostgreSQL (Port 5433)
**Total Episodes:** 403

## 📋 Quick Start

### 1. Import Postman Collection
1. Open Postman
2. Click **Import** button
3. Select **Files** tab
4. Choose `Joy_of_Painting_API.postman_collection.json` from your project folder
5. Click **Import**

### 2. Set Base URL
After importing, the collection will automatically use:
- **Base URL:** `http://localhost:3000`

## 🏔️ Mountain Episodes (Your Primary Query)

### Get All Mountain Episodes
```
GET http://localhost:3000/subjects/mountain
```

This returns all episodes featuring mountains as a subject element.

### Get Mountain Episodes with Pagination
```
GET http://localhost:3000/subjects/mountain?page=1&limit=10
```

## 📡 Available Endpoints

### 1. General Endpoints
- `GET /` - API documentation
- `GET /health` - Health check

### 2. Episodes
- `GET /episodes` - Get all episodes (paginated)
- `GET /episodes/:id` - Get specific episode by ID
- `GET /episodes/season/:season` - Get episodes by season

### 3. Subject Matter (What you need!)
- `GET /subjects` - Get all subject elements
- `GET /subjects/:subject` - Get episodes by subject (e.g., `/subjects/mountain`)

### 4. Colors
- `GET /colors` - Get all paint colors
- `GET /colors/:color` - Get episodes using specific color

### 5. Search & Filter
- `GET /search?q=mountain` - Search episodes by title or subject
- `GET /episodes?subject=mountain&color=prussian_blue` - Multi-filter

## 🧪 Testing Mountain Queries in Postman

### Test 1: Basic Mountain Query
```
Method: GET
URL: http://localhost:3000/subjects/mountain
```

Expected: Array of episodes featuring mountains

### Test 2: Mountain Episodes with Pagination
```
Method: GET
URL: http://localhost:3000/subjects/mountain?page=1&limit=5
```

Expected: First 5 mountain episodes with pagination info

### Test 3: Search for Mountain Episodes
```
Method: GET
URL: http://localhost:3000/search?q=mountain
```

Expected: Episodes with "mountain" in title or subjects

### Test 4: Specific Mountain Episode
```
Method: GET
URL: http://localhost:3000/episodes/1
```

Expected: Episode details including subjects and colors

## 📊 Sample Response (Mountain Episodes)

```json
{
  "success": true,
  "data": [
    {
      "episode_id": 1,
      "title": "A Walk in the Woods",
      "season": 1,
      "episode": 1,
      "broadcast_date": "1983-01-11T00:00:00.000Z",
      "subject_matter": ["mountain", "trees", "lake"]
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 89,
    "totalPages": 5
  }
}
```

## 🔍 Advanced Testing

### Combine Filters
Test episodes that have both mountains AND specific colors:
```
GET /episodes?subject=mountain&color=prussian_blue
```

### Date Range Filtering
```
GET /episodes?year=1983
```

### Multiple Subjects
```
GET /episodes?subject=mountain,trees
```

## 🚨 Troubleshooting

### Server Not Responding
1. Check if server is running: Look for "🎨 Joy of Painting API running on port 3000"
2. Verify database connection: Check if PostgreSQL container is running
3. Restart server: In terminal, press `Ctrl+C` and run `npm run dev` again

### No Mountain Data
If mountain queries return empty:
1. Verify database population completed
2. Check subject_elements table: `docker exec -it joy_of_painting_db psql -U joy_user -d joy_of_painting -c "SELECT * FROM subject_elements WHERE element_name ILIKE '%mountain%';"`

### Database Connection Issues
```bash
# Check if container is running
docker ps | grep joy_of_painting_db

# Check database contents
docker exec -it joy_of_painting_db psql -U joy_user -d joy_of_painting -c "SELECT COUNT(*) FROM episodes;"
```

## 📈 Performance Testing

Test API performance with these endpoints:
- `GET /episodes` (all 403 episodes)
- `GET /subjects/mountain` (subset filtering)
- `GET /search?q=mountain` (text search)

## 🎯 Key Mountain-Related Tests

1. **Mountain Subject Count**
   - `GET /subjects/mountain`
   - Verify response contains multiple episodes

2. **Mountain in Search**
   - `GET /search?q=mountain`
   - Should return episodes with "mountain" in title or subjects

3. **Combined Mountain + Color**
   - `GET /episodes?subject=mountain&color=prussian_blue`
   - Test complex filtering

4. **Season-specific Mountains**
   - `GET /episodes/season/1?subject=mountain`
   - Mountains in Season 1

## 🔗 Next Steps

After testing with Postman:
1. Document any issues or unexpected responses
2. Test error handling (invalid IDs, malformed requests)
3. Verify data accuracy against original Joy of Painting episodes
4. Consider adding more advanced filtering options

---

**Need help?** The API server logs all requests. Check your terminal for debugging information!
