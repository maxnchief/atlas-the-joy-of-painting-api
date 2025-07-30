# The Joy of Painting Database Design Document

## Executive Summary

This document outlines the database design for The Joy of Painting API that enables filtering of 403 episodes based on:
- **Month of original broadcast** - for seasonal viewing preferences
- **Subject Matter** - for specific painting elements (mountains, trees, cabins, etc.)
- **Color Palette** - for specific paint colors used

## Data Source Analysis

The collected data comes from three different sources with different formats:

### 1. `color_palette.csv`
- **Structure**: Relational data with episode metadata
- **Contains**: Episode info, painting details, colors used, YouTube links, hex codes
- **Key Fields**: season, episode, title, colors array, individual color flags

### 2. `subject_matter.csv` 
- **Structure**: Wide table with binary flags (67 columns)
- **Contains**: Episode codes, titles, and 0/1 flags for subject elements
- **Key Fields**: EPISODE, TITLE, plus 67 subject matter columns

### 3. `broadcast_date`
- **Structure**: Text file with title and date pairs
- **Contains**: Episode titles with broadcast dates and special guest info
- **Format**: "Title" (Date) [Optional guest info]

## Database Design Goals

1. **Normalization**: Eliminate data redundancy through proper relationships
2. **Performance**: Enable fast filtering queries on month, subject, and colors
3. **Scalability**: Support future episodes and new subject elements/colors
4. **Data Integrity**: Enforce relationships and constraints
5. **API-Friendly**: Structure optimized for REST API responses

## Entity Relationship Design

### Core Entities

#### Episodes Table
```sql
episodes (
    episode_id INT PRIMARY KEY,
    season INT NOT NULL,
    episode INT NOT NULL,
    episode_code VARCHAR(10) UNIQUE, -- S01E01 format
    title VARCHAR(255) NOT NULL,
    broadcast_date DATE,
    painting_index INT,
    img_src TEXT,
    youtube_src TEXT,
    num_colors INT,
    special_guest VARCHAR(255)
)
```

#### Colors Table
```sql
colors (
    color_id INT PRIMARY KEY,
    color_name VARCHAR(100) UNIQUE,
    color_hex VARCHAR(7) -- #FFFFFF format
)
```

#### Subject Elements Table
```sql
subject_elements (
    element_id INT PRIMARY KEY,
    element_name VARCHAR(100) UNIQUE,
    element_category VARCHAR(50) -- LANDSCAPE, STRUCTURE, WEATHER, etc.
)
```

### Relationship Tables (Many-to-Many)

#### Episode Colors
```sql
episode_colors (
    episode_id INT,
    color_id INT,
    PRIMARY KEY (episode_id, color_id)
)
```

#### Episode Elements
```sql
episode_elements (
    episode_id INT,
    element_id INT,
    PRIMARY KEY (episode_id, element_id)
)
```

## UML Entity Relationship Diagram

```
┌─────────────────────────────────┐
│            Episodes             │
├─────────────────────────────────┤
│ + episode_id: INT (PK)          │
│ + season: INT                   │
│ + episode: INT                  │
│ + episode_code: VARCHAR(10)     │
│ + title: VARCHAR(255)           │
│ + broadcast_date: DATE          │
│ + painting_index: INT           │
│ + img_src: TEXT                 │
│ + youtube_src: TEXT             │
│ + num_colors: INT               │
│ + special_guest: VARCHAR(255)   │
└─────────────────────────────────┘
            │ 1            │ 1
            │              │
            │ *            │ *
            ▼              ▼
┌─────────────────────┐  ┌─────────────────────┐
│   Episode_Colors    │  │  Episode_Elements   │
├─────────────────────┤  ├─────────────────────┤
│ + episode_id: INT   │  │ + episode_id: INT   │
│ + color_id: INT     │  │ + element_id: INT   │
│ (PK: both)          │  │ (PK: both)          │
└─────────────────────┘  └─────────────────────┘
            │ *                        │ *
            │ 1                        │ 1
            ▼                          ▼
┌─────────────────────┐  ┌─────────────────────┐
│       Colors        │  │  Subject_Elements   │
├─────────────────────┤  ├─────────────────────┤
│ + color_id: INT(PK) │  │ + element_id: INT   │
│ + color_name: VAR   │  │ + element_name: VAR │
│ + color_hex: VAR    │  │ + element_category  │
└─────────────────────┘  └─────────────────────┘
```

## Key Design Benefits

### 1. Normalized Structure
- **Colors stored once**: Eliminates redundancy from wide CSV format
- **Elements categorized**: Groups related subjects (LANDSCAPE, STRUCTURE, etc.)
- **Referential integrity**: Foreign keys ensure data consistency

### 2. Query Performance
- **Month filtering**: Direct DATE column with indexes
- **Subject filtering**: Efficient JOINs instead of column scanning
- **Color filtering**: Indexed lookups vs. string parsing
- **Combined filters**: Optimized for complex WHERE clauses

### 3. API-Friendly Design
- **Clean JSON responses**: Easy to serialize relationships
- **Flexible filtering**: Support for AND/OR operations
- **Pagination ready**: Simple LIMIT/OFFSET support
- **Expandable**: Easy to add new filter criteria

## Sample API Queries

### Filter by Month (January episodes)
```sql
SELECT e.episode_code, e.title, e.broadcast_date, e.youtube_src
FROM episodes e
WHERE MONTH(e.broadcast_date) = 1
ORDER BY e.broadcast_date;
```

### Filter by Subject Matter (Mountains and Water)
```sql
SELECT DISTINCT e.episode_code, e.title, e.broadcast_date
FROM episodes e
JOIN episode_elements ee ON e.episode_id = ee.episode_id
JOIN subject_elements se ON ee.element_id = se.element_id
WHERE se.element_name IN ('MOUNTAIN', 'MOUNTAINS', 'WATERFALL', 'LAKE')
ORDER BY e.broadcast_date;
```

### Filter by Colors (Prussian Blue episodes)
```sql
SELECT DISTINCT e.episode_code, e.title, e.broadcast_date
FROM episodes e
JOIN episode_colors ec ON e.episode_id = ec.episode_id
JOIN colors c ON ec.color_id = c.color_id
WHERE c.color_name = 'Prussian Blue'
ORDER BY e.broadcast_date;
```

### Combined Filter (October + Mountains + Autumn Colors)
```sql
SELECT DISTINCT e.episode_code, e.title, e.broadcast_date,
       GROUP_CONCAT(DISTINCT se.element_name) as subjects,
       GROUP_CONCAT(DISTINCT c.color_name) as colors
FROM episodes e
JOIN episode_elements ee ON e.episode_id = ee.episode_id
JOIN subject_elements se ON ee.element_id = se.element_id
JOIN episode_colors ec ON e.episode_id = ec.episode_id
JOIN colors c ON ec.color_id = c.color_id
WHERE MONTH(e.broadcast_date) = 10
  AND se.element_name IN ('MOUNTAIN', 'MOUNTAINS')
  AND c.color_name IN ('Alizarin Crimson', 'Burnt Umber', 'Yellow Ochre')
GROUP BY e.episode_id, e.episode_code, e.title, e.broadcast_date
ORDER BY e.broadcast_date;
```

## Technology Recommendations

### Database Choice: PostgreSQL
- **JSON Support**: Native JSON columns for flexible metadata
- **Performance**: Excellent query optimization for complex JOINs
- **Full-text Search**: Built-in search capabilities for titles
- **Date Functions**: Rich date/time manipulation functions
- **Scalability**: Handles large datasets efficiently

### Alternative: MySQL
- **Simplicity**: Easier setup for local development
- **Compatibility**: Wide hosting support
- **JSON Support**: Available in recent versions
- **Performance**: Good for read-heavy workloads

## Implementation Strategy

### Phase 1: Schema Creation
1. Create database and tables
2. Set up indexes and constraints
3. Create stored procedures for common queries

### Phase 2: Data Migration
1. Process CSV files and normalize data
2. Insert episodes, colors, and subject elements
3. Populate relationship tables
4. Validate data integrity

### Phase 3: API Development
1. Create REST endpoints for filtering
2. Implement caching for performance
3. Add pagination and sorting
4. Build search functionality

## Performance Considerations

### Indexes
```sql
-- Primary performance indexes
CREATE INDEX idx_episodes_broadcast_date ON episodes(broadcast_date);
CREATE INDEX idx_episodes_season_episode ON episodes(season, episode);
CREATE INDEX idx_subject_elements_name ON subject_elements(element_name);
CREATE INDEX idx_colors_name ON colors(color_name);

-- Composite indexes for relationships
CREATE INDEX idx_episode_colors_color ON episode_colors(color_id, episode_id);
CREATE INDEX idx_episode_elements_element ON episode_elements(element_id, episode_id);
```

### Query Optimization
- Use EXPLAIN ANALYZE to monitor query performance
- Consider materialized views for complex frequent queries
- Implement proper caching strategy
- Use pagination to limit result sets

## Data Validation Rules

### Business Rules
- Each episode must have a unique episode_code (S##E##)
- Broadcast dates must be between 1983-1994
- Each episode must have at least one color
- Season and episode numbers must be positive
- Special guest field is optional

### Referential Integrity
- All episode_colors.episode_id must reference episodes.episode_id
- All episode_colors.color_id must reference colors.color_id
- All episode_elements.episode_id must reference episodes.episode_id
- All episode_elements.element_id must reference subject_elements.element_id

This design provides a solid foundation for The Joy of Painting API that will efficiently support the required filtering capabilities while maintaining data integrity and performance.
