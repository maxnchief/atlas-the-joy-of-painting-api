const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*'
}));
app.use(morgan('combined'));
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Root endpoint with API documentation
app.get('/', (req, res) => {
  res.json({
    message: 'The Joy of Painting API',
    version: '1.0.0',
    endpoints: {
      'GET /episodes': 'Get all episodes with optional filtering',
      'GET /episodes/:id': 'Get specific episode by ID',
      'GET /episodes/search': 'Search episodes by title',
      'GET /subjects': 'Get all subject elements',
      'GET /subjects/mountain': 'Get all mountain-related episodes',
      'GET /colors': 'Get all paint colors',
      'GET /stats': 'Get database statistics'
    },
    filters: {
      'season': 'Filter by season number',
      'subject': 'Filter by subject matter (comma-separated)',
      'color': 'Filter by paint colors (comma-separated)',
      'month': 'Filter by broadcast month (1-12)',
      'year': 'Filter by broadcast year'
    }
  });
});

// Get all episodes with optional filtering
app.get('/episodes', async (req, res) => {
  try {
    const { season, subject, color, month, year, limit = 50, offset = 0 } = req.query;
    
    let query = `
      SELECT DISTINCT e.episode_id, e.season, e.episode, e.episode_code, 
             e.title, e.broadcast_date, e.img_src, e.youtube_src, 
             e.num_colors, e.special_guest,
             STRING_AGG(DISTINCT se.element_name, ', ') as subjects,
             STRING_AGG(DISTINCT c.color_name, ', ') as colors
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
      query += ` AND EXISTS (
        SELECT 1 FROM episode_elements ee2 
        JOIN subject_elements se2 ON ee2.element_id = se2.element_id 
        WHERE ee2.episode_id = e.episode_id 
        AND se2.element_name = ANY($${paramCount})
      )`;
      params.push(subjects);
    }
    
    if (color) {
      const colors = color.split(',').map(c => c.trim());
      paramCount++;
      query += ` AND EXISTS (
        SELECT 1 FROM episode_colors ec2 
        JOIN colors c2 ON ec2.color_id = c2.color_id 
        WHERE ec2.episode_id = e.episode_id 
        AND c2.color_name = ANY($${paramCount})
      )`;
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
      GROUP BY e.episode_id, e.season, e.episode, e.episode_code, 
               e.title, e.broadcast_date, e.img_src, e.youtube_src, 
               e.num_colors, e.special_guest
      ORDER BY e.season, e.episode
    `;
    
    paramCount++;
    query += ` LIMIT $${paramCount}`;
    params.push(parseInt(limit));
    
    paramCount++;
    query += ` OFFSET $${paramCount}`;
    params.push(parseInt(offset));
    
    const result = await pool.query(query, params);
    
    res.json({
      episodes: result.rows,
      total: result.rowCount,
      page: Math.floor(offset / limit) + 1,
      limit: parseInt(limit)
    });
  } catch (err) {
    console.error('Error fetching episodes:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get specific episode by ID
app.get('/episodes/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const query = `
      SELECT e.*, 
             STRING_AGG(DISTINCT se.element_name, ', ') as subjects,
             STRING_AGG(DISTINCT c.color_name, ', ') as colors
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
  } catch (err) {
    console.error('Error fetching episode:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Search episodes by title
app.get('/episodes/search', async (req, res) => {
  try {
    const { q, limit = 20 } = req.query;
    
    if (!q) {
      return res.status(400).json({ error: 'Search query parameter "q" is required' });
    }
    
    const query = `
      SELECT e.episode_id, e.season, e.episode, e.episode_code, 
             e.title, e.broadcast_date, e.img_src
      FROM episodes e
      WHERE e.title ILIKE $1
      ORDER BY e.season, e.episode
      LIMIT $2
    `;
    
    const result = await pool.query(query, [`%${q}%`, parseInt(limit)]);
    
    res.json({
      episodes: result.rows,
      total: result.rowCount,
      query: q
    });
  } catch (err) {
    console.error('Error searching episodes:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get all subject elements
app.get('/subjects', async (req, res) => {
  try {
    const query = `
      SELECT se.element_id, se.element_name, se.element_category,
             COUNT(ee.episode_id) as episode_count
      FROM subject_elements se
      LEFT JOIN episode_elements ee ON se.element_id = ee.element_id
      GROUP BY se.element_id, se.element_name, se.element_category
      ORDER BY se.element_category, se.element_name
    `;
    
    const result = await pool.query(query);
    
    res.json({
      subjects: result.rows
    });
  } catch (err) {
    console.error('Error fetching subjects:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get all mountain-related episodes (your original request)
app.get('/subjects/mountain', async (req, res) => {
  try {
    const query = `
      SELECT DISTINCT
          e.episode_id,
          e.season,
          e.episode,
          e.episode_code,
          e.title,
          e.broadcast_date,
          e.img_src,
          e.youtube_src,
          STRING_AGG(se.element_name, ', ') as mountain_elements
      FROM episodes e
      JOIN episode_elements ee ON e.episode_id = ee.episode_id
      JOIN subject_elements se ON ee.element_id = se.element_id
      WHERE se.element_name ILIKE '%mountain%'
      GROUP BY e.episode_id, e.season, e.episode, e.episode_code, e.title, e.broadcast_date, e.img_src, e.youtube_src
      ORDER BY e.season, e.episode
    `;
    
    const result = await pool.query(query);
    
    res.json({
      episodes: result.rows,
      total: result.rowCount,
      message: 'All episodes featuring mountain subject matter'
    });
  } catch (err) {
    console.error('Error fetching mountain episodes:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get all paint colors
app.get('/colors', async (req, res) => {
  try {
    const query = `
      SELECT c.color_id, c.color_name, c.color_hex,
             COUNT(ec.episode_id) as episode_count
      FROM colors c
      LEFT JOIN episode_colors ec ON c.color_id = ec.color_id
      GROUP BY c.color_id, c.color_name, c.color_hex
      ORDER BY c.color_name
    `;
    
    const result = await pool.query(query);
    
    res.json({
      colors: result.rows
    });
  } catch (err) {
    console.error('Error fetching colors:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get database statistics
app.get('/stats', async (req, res) => {
  try {
    const episodeCount = await pool.query('SELECT COUNT(*) FROM episodes');
    const subjectCount = await pool.query('SELECT COUNT(*) FROM subject_elements');
    const colorCount = await pool.query('SELECT COUNT(*) FROM colors');
    const relationshipCount = await pool.query('SELECT COUNT(*) FROM episode_elements');
    
    res.json({
      total_episodes: parseInt(episodeCount.rows[0].count),
      total_subjects: parseInt(subjectCount.rows[0].count),
      total_colors: parseInt(colorCount.rows[0].count),
      total_relationships: parseInt(relationshipCount.rows[0].count)
    });
  } catch (err) {
    console.error('Error fetching stats:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Start server
app.listen(port, () => {
  console.log(`🎨 Joy of Painting API running on port ${port}`);
  console.log(`📚 API documentation: http://localhost:${port}/`);
  console.log(`🏔️  Mountain episodes: http://localhost:${port}/subjects/mountain`);
});

module.exports = app;
