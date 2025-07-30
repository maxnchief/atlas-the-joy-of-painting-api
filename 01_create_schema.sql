-- ============================================================================
-- The Joy of Painting Database Schema - PostgreSQL
-- Database Creation Script
-- ============================================================================

-- Create database (run this separately if needed)
-- CREATE DATABASE joy_of_painting;

-- Connect to the database
-- \c joy_of_painting;

-- ============================================================================
-- Enable Extensions
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- Core Tables
-- ============================================================================

-- Episodes table - Central table containing episode metadata
CREATE TABLE episodes (
    episode_id SERIAL PRIMARY KEY,
    season INTEGER NOT NULL CHECK (season > 0),
    episode INTEGER NOT NULL CHECK (episode > 0),
    episode_code VARCHAR(10) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    broadcast_date DATE,
    painting_index INTEGER,
    img_src TEXT,
    youtube_src TEXT,
    num_colors INTEGER CHECK (num_colors >= 0),
    special_guest VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_episode_code CHECK (episode_code ~ '^S[0-9]{2}E[0-9]{2}$'),
    CONSTRAINT unique_season_episode UNIQUE (season, episode)
);

-- Colors table - Master list of all paint colors
CREATE TABLE colors (
    color_id SERIAL PRIMARY KEY,
    color_name VARCHAR(100) NOT NULL UNIQUE,
    color_hex VARCHAR(7) CHECK (color_hex IS NULL OR color_hex ~ '^#[0-9A-Fa-f]{6}$'),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Subject Elements table - Master list of subject matter elements
CREATE TABLE subject_elements (
    element_id SERIAL PRIMARY KEY,
    element_name VARCHAR(100) NOT NULL UNIQUE,
    element_category VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- Relationship Tables (Many-to-Many)
-- ============================================================================

-- Episode Colors relationship
CREATE TABLE episode_colors (
    episode_id INTEGER NOT NULL,
    color_id INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (episode_id, color_id),
    
    FOREIGN KEY (episode_id) REFERENCES episodes(episode_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (color_id) REFERENCES colors(color_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Episode Elements relationship
CREATE TABLE episode_elements (
    episode_id INTEGER NOT NULL,
    element_id INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (episode_id, element_id),
    
    FOREIGN KEY (episode_id) REFERENCES episodes(episode_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (element_id) REFERENCES subject_elements(element_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================================
-- Indexes for Performance
-- ============================================================================

-- Episodes indexes
CREATE INDEX idx_episodes_broadcast_date ON episodes(broadcast_date);
CREATE INDEX idx_episodes_season ON episodes(season);
CREATE INDEX idx_episodes_title ON episodes USING gin(to_tsvector('english', title));

-- Colors indexes
CREATE INDEX idx_colors_name ON colors(color_name);

-- Subject elements indexes  
CREATE INDEX idx_subject_elements_name ON subject_elements(element_name);
CREATE INDEX idx_subject_elements_category ON subject_elements(element_category);

-- Relationship table indexes
CREATE INDEX idx_episode_colors_color ON episode_colors(color_id);
CREATE INDEX idx_episode_elements_element ON episode_elements(element_id);

-- ============================================================================
-- Views for Common Queries
-- ============================================================================

-- View for episodes with month extraction
CREATE VIEW episodes_with_month AS
SELECT 
    e.*,
    EXTRACT(MONTH FROM e.broadcast_date) AS broadcast_month,
    TO_CHAR(e.broadcast_date, 'Month') AS broadcast_month_name,
    EXTRACT(YEAR FROM e.broadcast_date) AS broadcast_year
FROM episodes e;

-- View for episode statistics
CREATE VIEW episode_stats AS
SELECT 
    e.episode_id,
    e.episode_code,
    e.title,
    e.broadcast_date,
    e.num_colors,
    COUNT(DISTINCT ec.color_id) AS actual_color_count,
    COUNT(DISTINCT ee.element_id) AS element_count,
    e.special_guest
FROM episodes e
LEFT JOIN episode_colors ec ON e.episode_id = ec.episode_id
LEFT JOIN episode_elements ee ON e.episode_id = ee.episode_id
GROUP BY e.episode_id, e.episode_code, e.title, e.broadcast_date, e.num_colors, e.special_guest;

-- View for detailed episode information
CREATE VIEW episode_details AS
SELECT 
    e.episode_id,
    e.season,
    e.episode,
    e.episode_code,
    e.title,
    e.broadcast_date,
    e.painting_index,
    e.img_src,
    e.youtube_src,
    e.num_colors,
    e.special_guest,
    EXTRACT(MONTH FROM e.broadcast_date) AS broadcast_month,
    TO_CHAR(e.broadcast_date, 'Month YYYY') AS broadcast_month_year,
    array_agg(DISTINCT c.color_name ORDER BY c.color_name) FILTER (WHERE c.color_name IS NOT NULL) AS colors,
    array_agg(DISTINCT se.element_name ORDER BY se.element_name) FILTER (WHERE se.element_name IS NOT NULL) AS subject_elements,
    array_agg(DISTINCT se.element_category ORDER BY se.element_category) FILTER (WHERE se.element_category IS NOT NULL) AS subject_categories
FROM episodes e
LEFT JOIN episode_colors ec ON e.episode_id = ec.episode_id
LEFT JOIN colors c ON ec.color_id = c.color_id
LEFT JOIN episode_elements ee ON e.episode_id = ee.episode_id
LEFT JOIN subject_elements se ON ee.element_id = se.element_id
GROUP BY e.episode_id, e.season, e.episode, e.episode_code, e.title, 
         e.broadcast_date, e.painting_index, e.img_src, e.youtube_src, 
         e.num_colors, e.special_guest;

-- ============================================================================
-- Functions for Common Operations
-- ============================================================================

-- Function to get episodes by month
CREATE OR REPLACE FUNCTION get_episodes_by_month(target_month INTEGER)
RETURNS TABLE (
    episode_code VARCHAR(10),
    title VARCHAR(255),
    season INTEGER,
    episode INTEGER,
    broadcast_date DATE,
    img_src TEXT,
    youtube_src TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.episode_code,
        e.title,
        e.season,
        e.episode,
        e.broadcast_date,
        e.img_src,
        e.youtube_src
    FROM episodes e
    WHERE EXTRACT(MONTH FROM e.broadcast_date) = target_month
    ORDER BY e.broadcast_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get episodes by subject matter
CREATE OR REPLACE FUNCTION get_episodes_by_subjects(subject_names TEXT[])
RETURNS TABLE (
    episode_code VARCHAR(10),
    title VARCHAR(255),
    season INTEGER,
    episode INTEGER,
    broadcast_date DATE,
    subjects TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        e.episode_code,
        e.title,
        e.season,
        e.episode,
        e.broadcast_date,
        array_agg(DISTINCT se.element_name ORDER BY se.element_name) AS subjects
    FROM episodes e
    JOIN episode_elements ee ON e.episode_id = ee.episode_id
    JOIN subject_elements se ON ee.element_id = se.element_id
    WHERE se.element_name = ANY(subject_names)
    GROUP BY e.episode_id, e.episode_code, e.title, e.season, e.episode, e.broadcast_date
    ORDER BY e.broadcast_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get episodes by colors
CREATE OR REPLACE FUNCTION get_episodes_by_colors(color_names TEXT[])
RETURNS TABLE (
    episode_code VARCHAR(10),
    title VARCHAR(255),
    season INTEGER,
    episode INTEGER,
    broadcast_date DATE,
    colors_used TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        e.episode_code,
        e.title,
        e.season,
        e.episode,
        e.broadcast_date,
        array_agg(DISTINCT c.color_name ORDER BY c.color_name) AS colors_used
    FROM episodes e
    JOIN episode_colors ec ON e.episode_id = ec.episode_id
    JOIN colors c ON ec.color_id = c.color_id
    WHERE c.color_name = ANY(color_names)
    GROUP BY e.episode_id, e.episode_code, e.title, e.season, e.episode, e.broadcast_date
    ORDER BY e.broadcast_date;
END;
$$ LANGUAGE plpgsql;

-- Complex filtering function
CREATE OR REPLACE FUNCTION get_episodes_filtered(
    target_month INTEGER DEFAULT NULL,
    subject_names TEXT[] DEFAULT NULL,
    color_names TEXT[] DEFAULT NULL
)
RETURNS TABLE (
    episode_code VARCHAR(10),
    title VARCHAR(255),
    season INTEGER,
    episode INTEGER,
    broadcast_date DATE,
    img_src TEXT,
    youtube_src TEXT,
    subjects TEXT[],
    colors_used TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        e.episode_code,
        e.title,
        e.season,
        e.episode,
        e.broadcast_date,
        e.img_src,
        e.youtube_src,
        array_agg(DISTINCT se.element_name ORDER BY se.element_name) FILTER (WHERE se.element_name IS NOT NULL) AS subjects,
        array_agg(DISTINCT c.color_name ORDER BY c.color_name) FILTER (WHERE c.color_name IS NOT NULL) AS colors_used
    FROM episodes e
    LEFT JOIN episode_elements ee ON e.episode_id = ee.episode_id
    LEFT JOIN subject_elements se ON ee.element_id = se.element_id
    LEFT JOIN episode_colors ec ON e.episode_id = ec.episode_id
    LEFT JOIN colors c ON ec.color_id = c.color_id
    WHERE 
        (target_month IS NULL OR EXTRACT(MONTH FROM e.broadcast_date) = target_month)
        AND (subject_names IS NULL OR se.element_name = ANY(subject_names))
        AND (color_names IS NULL OR c.color_name = ANY(color_names))
    GROUP BY e.episode_id, e.episode_code, e.title, e.season, e.episode, 
             e.broadcast_date, e.img_src, e.youtube_src
    ORDER BY e.broadcast_date;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Trigger for updating timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_episodes_updated_at 
    BEFORE UPDATE ON episodes 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Comments for Documentation
-- ============================================================================

COMMENT ON TABLE episodes IS 'Central table storing episode metadata and broadcast information';
COMMENT ON TABLE colors IS 'Master list of paint colors used across all episodes';
COMMENT ON TABLE subject_elements IS 'Master list of subject matter elements found in paintings';
COMMENT ON TABLE episode_colors IS 'Many-to-many relationship between episodes and colors used';
COMMENT ON TABLE episode_elements IS 'Many-to-many relationship between episodes and subject elements';

COMMENT ON COLUMN episodes.episode_code IS 'Unique identifier in format S##E## (e.g., S01E01)';
COMMENT ON COLUMN episodes.broadcast_date IS 'Original air date of the episode';
COMMENT ON COLUMN episodes.painting_index IS 'Unique painting identifier from source data';
COMMENT ON COLUMN colors.color_hex IS 'Hexadecimal color code in #RRGGBB format';
COMMENT ON COLUMN subject_elements.element_category IS 'Category grouping for subject elements (LANDSCAPE, STRUCTURE, etc.)';

-- ============================================================================
-- Sample Validation Queries (for testing after data load)
-- ============================================================================

-- These can be run after data import to validate integrity

/*
-- Check for episodes without colors
SELECT e.episode_code, e.title 
FROM episodes e 
LEFT JOIN episode_colors ec ON e.episode_id = ec.episode_id 
WHERE ec.episode_id IS NULL;

-- Check for episodes without elements
SELECT e.episode_code, e.title 
FROM episodes e 
LEFT JOIN episode_elements ee ON e.episode_id = ee.episode_id 
WHERE ee.episode_id IS NULL;

-- Verify color count matches num_colors field
SELECT e.episode_code, e.num_colors, COUNT(ec.color_id) as actual_colors
FROM episodes e
LEFT JOIN episode_colors ec ON e.episode_id = ec.episode_id
GROUP BY e.episode_id, e.episode_code, e.num_colors
HAVING e.num_colors != COUNT(ec.color_id);

-- Test the filtering functions
SELECT * FROM get_episodes_by_month(3); -- March episodes
SELECT * FROM get_episodes_by_subjects(ARRAY['MOUNTAIN', 'WATERFALL']); -- Mountain and waterfall episodes
SELECT * FROM get_episodes_by_colors(ARRAY['Prussian Blue', 'Titanium White']); -- Specific color episodes
*/

COMMIT;
