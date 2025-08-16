# 🎨 The Joy of Painting API

A RESTful API for exploring Bob Ross's "The Joy of Painting" episodes, featuring comprehensive filtering by subject matter, paint colors, and broadcast dates. Perfect for developers who want to add a touch of happy little trees to their applications!

## 📊 Database Overview

- **403 Episodes** across 31 seasons
- **67 Subject Elements** (mountains, trees, water, etc.)
- **18 Paint Colors** with hex codes
- **Broadcast Dates** from 1983-1994
- **4,250+ Color Relationships**
- **2,997+ Subject Relationships**

## 🚀 Quick Start Tutorial

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed
- [Node.js](https://nodejs.org/) (v16 or higher)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)

### Step 1: Clone the Repository

```bash
git clone https://github.com/your-username/atlas-the-joy-of-painting-api.git
cd atlas-the-joy-of-painting-api
```

### Step 2: Start the Database

```bash
# Make the setup script executable
chmod +x setup-db-direct.sh

# Start PostgreSQL database with Docker
./setup-db-direct.sh
```

### Step 3: Initialize Database with Data

```bash
# Make the initialization script executable
chmod +x init-database.sh

# Load schema and all episode data
./init-database.sh
```

### Step 4: Install Dependencies and Start API

```bash
# Install Node.js dependencies
npm install

# Start the API server in development mode
npm run dev
```

### Step 5: Test Your API! 🎉

Your API is now running at `http://localhost:3000`

**Quick Test Commands:**
```bash
# Health check
curl http://localhost:3000/health

# Get all mountain episodes
curl http://localhost:3000/subjects/mountain

# Get API documentation
curl http://localhost:3000/
```

## 📚 API Endpoints

### Core Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | API documentation and available endpoints |
| `GET` | `/health` | Health check and database connection status |
| `GET` | `/stats` | Database statistics (episode count, colors, etc.) |

### Episode Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/episodes` | Get all episodes with optional filtering |
| `GET` | `/episodes/:id` | Get specific episode by ID |
| `GET` | `/search?q=query` | Search episodes by title or subject |

### Subject Matter Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/subjects` | Get all available subject elements |
| `GET` | `/subjects/mountain` | Get all episodes featuring mountains |
| `GET` | `/subjects/:subject` | Get episodes by specific subject |

### Color Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/colors` | Get all paint colors with hex codes |

## 🔍 Query Parameters & Filtering

### Episode Filtering

Filter episodes using these query parameters:

```bash
# Filter by season
GET /episodes?season=1

# Filter by subject matter (comma-separated)
GET /episodes?subject=mountain,tree

# Filter by paint colors (comma-separated)
GET /episodes?color=Titanium White,Prussian Blue

# Filter by broadcast month (1-12)
GET /episodes?month=12

# Filter by broadcast year
GET /episodes?year=1983

# Pagination
GET /episodes?limit=20&offset=40

# Combine filters
GET /episodes?season=5&subject=mountain&month=11
```

### Example Responses

**Get Mountain Episodes:**
```json
{
  "subject": "MOUNTAIN",
  "episodes": [
    {
      "episode_id": 2,
      "title": "Mount McKinley",
      "season": 1,
      "episode": 2,
      "episode_code": "S01E02",
      "broadcast_date": "1983-01-11T00:00:00.000Z",
      "subject_elements": ["MOUNTAIN", "SNOW", "WINTER"],
      "colors": ["Prussian Blue", "Titanium White", "Van Dyke Brown"]
    }
  ],
  "total": 39,
  "page": 1,
  "limit": 50,
  "totalPages": 1
}
```

## 🧪 Testing with Postman

1. **Import Collection**: Import `Joy_of_Painting_API.postman_collection.json`
2. **Set Base URL**: `http://localhost:3000`
3. **Test Endpoints**: 14 pre-configured requests ready to use

### Featured Postman Requests

- 🏔️ **Mountain Episodes** - Get all episodes with mountains
- 🌊 **Water Episodes** - Episodes featuring lakes, rivers, streams
- 🌲 **Tree Episodes** - Episodes with various tree types
- 🎨 **Color Filtering** - Filter by specific paint colors
- 📅 **Seasonal Browsing** - Filter by broadcast month/year

## 🛠️ Development

### Project Structure

```
atlas-the-joy-of-painting-api/
├── server.js                 # Main API server
├── package.json              # Node.js dependencies
├── .env                      # Environment configuration
├── docker-compose.yml        # Database setup (alternative)
├── setup-db-direct.sh        # Database setup script
├── init-database.sh          # Data initialization script
├── sql/                      # Database schema and data
│   ├── 01_create_schema.sql
│   ├── 02_insert_master_data.sql
│   ├── 03_insert_episodes.sql
│   ├── 04_insert_episode_colors.sql
│   └── 05_insert_episode_elements.sql
└── Joy_of_Painting_API.postman_collection.json
```

### Available Scripts

```bash
npm start        # Start production server
npm run dev      # Start development server with auto-reload
npm test         # Run tests (placeholder)
```

### Environment Variables

The API uses these environment variables (see `.env`):

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=joy_of_painting
DB_USER=joy_user
DB_PASSWORD=joy_painting_2024

# API Configuration
PORT=3000
NODE_ENV=development
```

## 🎯 Use Cases

### For Developers
- **Art Apps**: Build applications that recommend episodes based on subjects
- **Educational Tools**: Create learning resources about color theory and painting techniques
- **Data Analysis**: Analyze patterns in Bob Ross's painting choices over 31 seasons

### For Bob Ross Fans
- **Episode Discovery**: Find episodes featuring your favorite subjects (mountains, cabins, wildlife)
- **Seasonal Viewing**: Watch episodes that originally aired during specific months
- **Color Exploration**: Discover episodes that use your favorite paint colors

### Example Applications
- **"Happy Little API"**: Slack bot that suggests daily Bob Ross episodes
- **"Paint Along Calendar"**: App that suggests episodes based on current season
- **"Color Mood Matcher"**: Match episodes to your current color preferences

## 🏔️ Special Feature: Mountain Episodes

Since you specifically requested mountain subject matter, here are some quick ways to explore mountain episodes:

```bash
# All mountain episodes
curl "http://localhost:3000/subjects/mountain"

# Mountain episodes from Season 5
curl "http://localhost:3000/episodes?subject=mountain&season=5"

# Mountain episodes from winter months
curl "http://localhost:3000/episodes?subject=mountain&month=12"

# Search for specific mountain episodes
curl "http://localhost:3000/search?q=mount"
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 🔗 Connect

**Developer**: Maxwell Logan
**LinkedIn**: https://www.linkedin.com/in/maxwell-logan/  

*"We don't make mistakes, just happy little accidents."* - Bob Ross

Made with ❤️ and happy little trees 🌲