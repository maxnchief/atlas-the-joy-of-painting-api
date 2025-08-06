const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'joy_of_painting',
  user: process.env.DB_USER || 'joy_user',
  password: process.env.DB_PASSWORD || 'joy_painting_2024',
});

// Test database connection
pool.connect((err, client, release) => {
  if (err) {
    console.error('❌ Error acquiring client:', err.stack);
  } else {
    console.log('✅ Database connected successfully');
    release();
  }
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ 
      status: 'healthy', 
      database: 'connected', 
      timestamp: new Date().toISOString() 
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'unhealthy', 
      database: 'disconnected', 
      error: error.message 
    });
  }
});

// API Documentation
app.get('/', (req, res) => {
  res.json({
    message: "🎨 Welcome to The Joy of Painting API!",
    description: "Filter Bob Ross episodes by subject matter, colors, and broadcast dates",
    version: "1.0.0",
    endpoints: {
      "GET /episodes": "Get all episodes with optional filtering",
      "GET /episodes/:id": "Get specific episode by ID",
      "GET /subjects": "Get all subject elements",
      "GET /subjects/mountain": "Get all episodes with mountains",
      "GET /colors": "Get all paint colors",
      "GET /search?q=query": "Search episodes",
      "GET /health": "Health check",
      "GET /stats": "Database statistics"
    },
    filters: {
      season: "Filter by season number (1-31)",
      subject: "Filter by subject matter (comma-separated)",
      color: "Filter by paint colors (comma-separated)", 
      month: "Filter by broadcast month (1-12)",
      year: "Filter by broadcast year"
    }
  });
});

// Get all episodes with filtering
app.get('/episodes', async (req, res) => {
  try {
    const { season, subject, color, month, year, limit = 50, offset = 0 } = req.query;
    
    let query = `
      SELECT DISTINCT e.episode_id, e.title, e.season, e.episode, e.episode_code, 
             e.broadcast_date, e.painting_index, e.img_src, e.youtube_src, 
             e.num_colors, e.special_guest,
             ARRAY_AGG(DISTINCT se.element_name) as subject_elements,
             ARRAY_AGG(DISTINCT c.color_name) as colors
      FROM episodes e
      LEFT JOIN episode_elements ee ON e.episode_id = ee.episode_id
      LEFT JOIN subject_elements se ON ee.element_id = se.element_id
      LEFT JOIN episode_colors ec ON e.episode_id = ec.episode_id
      LEFT JOIN colors c ON ec.color_id = c.color_id
      WHERE 1=1
    `;
    
    const params = [];
    let paramCount = 0;
    
    if (season) {
      paramCount++;
      query += ` AND e.season = $${paramCount}`;
      params.push(parseInt(season));
    }
    
    if (subject) {
      const subjects = subject.split(',').map(s => s.trim().toUpperCase());
      paramCount++;
      query += ` AND se.element_name = ANY($${paramCount})`;
      params.push(subjects);
    }
    
    if (color) {
      const colors = color.split(',').map(c => c.trim());
      paramCount++;
      query += ` AND c.color_name = ANY($${paramCount})`;
      params.push(colors);
    }
    
    if (month) {
      paramCount++;
      query += ` AND EXTRACT(MONTH FROM e.broadcast_date) = $${paramCount}`;
      params.push(parseInt(month));
    }
    
    if (year) {
      paramCount++;
      query += ` AND EXTRACT(YEAR FROM e.broadcast_date) = $${paramCount}`;
      params.push(parseInt(year));
    }
    
    query += ` 
      GROUP BY e.episode_id, e.title, e.season, e.episode, e.episode_code, 
               e.broadcast_date, e.painting_index, e.img_src, e.youtube_src, 
               e.num_colors, e.special_guest
      ORDER BY e.season, e.episode
      LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
    `;
    
    params.push(parseInt(limit), parseInt(offset));
    
    const result = await pool.query(query, params);
    
    // Get total count for pagination
    const countQuery = `SELECT COUNT(*) FROM episodes`;
    const countResult = await pool.query(countQuery);
    const total = parseInt(countResult.rows[0].count);
    
    res.json({
      episodes: result.rows,
      total,
      page: Math.floor(offset / limit) + 1,
      limit: parseInt(limit),
      totalPages: Math.ceil(total / limit)
    });
  } catch (error) {
    console.error('Error fetching episodes:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get specific episode by ID
app.get('/episodes/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const query = `
      SELECT e.*, 
             ARRAY_AGG(DISTINCT se.element_name) as subject_elements,
             ARRAY_AGG(DISTINCT c.color_name) as colors
      FROM episodes e
      LEFT JOIN episode_elements ee ON e.episode_id = ee.episode_id
      LEFT JOIN subject_elements se ON ee.element_id = se.element_id
      LEFT JOIN episode_colors ec ON e.episode_id = ec.episode_id
      LEFT JOIN colors c ON ec.color_id = c.color_id
      WHERE e.episode_id = $1
      GROUP BY e.episode_id
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Episode not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching episode:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get episodes with specific subject (e.g., mountain)
app.get('/subjects/:subject', async (req, res) => {
  try {
    const { subject } = req.params;
    const { limit = 50, offset = 0 } = req.query;
    
    const query = `
      SELECT DISTINCT e.episode_id, e.title, e.season, e.episode, e.episode_code, 
             e.broadcast_date, e.painting_index, e.img_src, e.youtube_src, 
             e.num_colors, e.special_guest,
             ARRAY_AGG(DISTINCT se.element_name) as subject_elements,
             ARRAY_AGG(DISTINCT c.color_name) as colors
      FROM episodes e
      JOIN episode_elements ee ON e.episode_id = ee.episode_id
      JOIN subject_elements se ON ee.element_id = se.element_id
      LEFT JOIN episode_colors ec ON e.episode_id = ec.episode_id
      LEFT JOIN colors c ON ec.color_id = c.color_id
      WHERE se.element_name ILIKE '%' || $1 || '%'
      GROUP BY e.episode_id, e.title, e.season, e.episode, e.episode_code, 
               e.broadcast_date, e.painting_index, e.img_src, e.youtube_src, 
               e.num_colors, e.special_guest
      ORDER BY e.season, e.episode
      LIMIT $2 OFFSET $3
    `;
    
    const result = await pool.query(query, [subject.toUpperCase(), limit, offset]);
    
    // Get total count
    const countQuery = `
      SELECT COUNT(DISTINCT e.episode_id)
      FROM episodes e
      JOIN episode_elements ee ON e.episode_id = ee.episode_id
      JOIN subject_elements se ON ee.element_id = se.element_id
      WHERE se.element_name ILIKE '%' || $1 || '%'
    `;
    
    const countResult = await pool.query(countQuery, [subject.toUpperCase()]);
    const total = parseInt(countResult.rows[0].count);
    
    res.json({
      subject: subject.toUpperCase(),
      episodes: result.rows,
      total,
      page: Math.floor(offset / limit) + 1,
      limit: parseInt(limit),
      totalPages: Math.ceil(total / limit)
    });
  } catch (error) {
    console.error('Error fetching subject episodes:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get all subject elements
app.get('/subjects', async (req, res) => {
  try {
    const query = `
      SELECT se.element_name, COUNT(ee.episode_id) as episode_count
      FROM subject_elements se
      LEFT JOIN episode_elements ee ON se.element_id = ee.element_id
      GROUP BY se.element_id, se.element_name
      ORDER BY se.element_name
    `;
    
    const result = await pool.query(query);
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching subjects:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get all colors
app.get('/colors', async (req, res) => {
  try {
    const query = `
      SELECT c.color_name, c.color_hex, COUNT(ec.episode_id) as episode_count
      FROM colors c
      LEFT JOIN episode_colors ec ON c.color_id = ec.color_id
      GROUP BY c.color_id, c.color_name, c.color_hex
      ORDER BY c.color_name
    `;
    
    const result = await pool.query(query);
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching colors:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Search episodes
app.get('/search', async (req, res) => {
  try {
    const { q, limit = 50, offset = 0 } = req.query;
    
    if (!q) {
      return res.status(400).json({ error: 'Query parameter "q" is required' });
    }
    
    const query = `
      SELECT DISTINCT e.episode_id, e.title, e.season, e.episode, e.episode_code, 
             e.broadcast_date, e.painting_index, e.img_src, e.youtube_src, 
             e.num_colors, e.special_guest,
             ARRAY_AGG(DISTINCT se.element_name) as subject_elements,
             ARRAY_AGG(DISTINCT c.color_name) as colors
      FROM episodes e
      LEFT JOIN episode_elements ee ON e.episode_id = ee.episode_id
      LEFT JOIN subject_elements se ON ee.element_id = se.element_id
      LEFT JOIN episode_colors ec ON e.episode_id = ec.episode_id
      LEFT JOIN colors c ON ec.color_id = c.color_id
      WHERE e.title ILIKE '%' || $1 || '%' OR se.element_name ILIKE '%' || $1 || '%'
      GROUP BY e.episode_id, e.title, e.season, e.episode, e.episode_code, 
               e.broadcast_date, e.painting_index, e.img_src, e.youtube_src, 
               e.num_colors, e.special_guest
      ORDER BY e.season, e.episode
      LIMIT $2 OFFSET $3
    `;
    
    const result = await pool.query(query, [q, limit, offset]);
    
    res.json({
      query: q,
      episodes: result.rows,
      total: result.rows.length
    });
  } catch (error) {
    console.error('Error searching episodes:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Database statistics
app.get('/stats', async (req, res) => {
  try {
    const episodeCount = await pool.query('SELECT COUNT(*) FROM episodes');
    const colorCount = await pool.query('SELECT COUNT(*) FROM colors');
    const subjectCount = await pool.query('SELECT COUNT(*) FROM subject_elements');
    const seasonCount = await pool.query('SELECT COUNT(DISTINCT season) FROM episodes');
    
    res.json({
      episodes: parseInt(episodeCount.rows[0].count),
      colors: parseInt(colorCount.rows[0].count),
      subjects: parseInt(subjectCount.rows[0].count),
      seasons: parseInt(seasonCount.rows[0].count)
    });
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`🎨 Joy of Painting API running on port ${PORT}`);
  console.log(`📖 API documentation: http://localhost:${PORT}/`);
  console.log(`🏔️  Mountain episodes: http://localhost:${PORT}/subjects/mountain`);
  console.log(`💊 Health check: http://localhost:${PORT}/health`);
});

module.exports = app;
