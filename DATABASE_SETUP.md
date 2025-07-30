# The Joy of Painting Database Setup Instructions

This guide will help you set up the complete Joy of Painting database from scratch using PostgreSQL (or adaptable to other SQL databases).

## Prerequisites

- PostgreSQL 12+ (recommended) or MySQL 8+/SQL Server 2019+
- Database client (pgAdmin, DBeaver, or command line)
- Basic SQL knowledge

## Quick Setup (PostgreSQL)

### 1. Create Database
```sql
CREATE DATABASE joy_of_painting;
\c joy_of_painting;
```

### 2. Run Scripts in Order
Execute the following SQL files in the exact order:

```bash
# 1. Create schema and tables
psql -d joy_of_painting -f 01_create_schema.sql

# 2. Insert master data (colors and subject elements)
psql -d joy_of_painting -f 02_insert_master_data.sql

# 3. Insert episode data
psql -d joy_of_painting -f 03_insert_episodes.sql

# 4. Insert episode-color relationships
psql -d joy_of_painting -f 04_insert_episode_colors.sql

# 5. Insert episode-element relationships
psql -d joy_of_painting -f 05_insert_episode_elements.sql
```

## Database Schema Overview

### Core Tables
- **episodes**: 401 episodes with broadcast dates, titles, and metadata
- **colors**: 18 unique paint colors used in the show
- **subject_elements**: 67 painting elements (trees, mountains, cabins, etc.)

### Relationship Tables
- **episode_colors**: 4,250 relationships linking episodes to colors used
- **episode_elements**: 2,997 relationships linking episodes to subject matter

### Views and Functions
- **episodes_with_colors**: Episodes with aggregated color lists
- **episodes_with_elements**: Episodes with aggregated element lists
- **get_episodes_by_month()**: Filter episodes by broadcast month
- **search_episodes()**: Full-text search functionality

## Data Statistics

- **Total Episodes**: 401 (Seasons 1-31)
- **Special Guest Episodes**: 7
- **Date Range**: January 1983 - May 1994
- **Color Relationships**: 4,250
- **Element Relationships**: 2,997

## Sample Queries

### Filter by Month
```sql
-- Get all episodes broadcast in January
SELECT * FROM get_episodes_by_month(1);
```

### Filter by Colors
```sql
-- Episodes using "Cadmium Yellow" and "Prussian Blue"
SELECT DISTINCT e.*
FROM episodes e
JOIN episode_colors ec1 ON e.episode_id = ec1.episode_id
JOIN episode_colors ec2 ON e.episode_id = ec2.episode_id
JOIN colors c1 ON ec1.color_id = c1.color_id
JOIN colors c2 ON ec2.color_id = c2.color_id
WHERE c1.color_name = 'Cadmium Yellow'
  AND c2.color_name = 'Prussian Blue';
```

### Filter by Subject Matter
```sql
-- Episodes featuring mountains and trees
SELECT DISTINCT e.*
FROM episodes e
JOIN episode_elements ee1 ON e.episode_id = ee1.episode_id
JOIN episode_elements ee2 ON e.episode_id = ee2.episode_id
JOIN subject_elements se1 ON ee1.element_id = se1.element_id
JOIN subject_elements se2 ON ee2.element_id = se2.element_id
WHERE se1.element_name = 'MOUNTAIN'
  AND se2.element_name = 'TREE';
```

### Combined Filtering
```sql
-- Episodes from January with mountains using Prussian Blue
SELECT DISTINCT e.*
FROM episodes e
JOIN episode_colors ec ON e.episode_id = ec.episode_id
JOIN episode_elements ee ON e.episode_id = ee.episode_id
JOIN colors c ON ec.color_id = c.color_id
JOIN subject_elements se ON ee.element_id = se.element_id
WHERE EXTRACT(MONTH FROM e.broadcast_date) = 1
  AND c.color_name = 'Prussian Blue'
  AND se.element_name = 'MOUNTAIN';
```

## Performance Considerations

The schema includes optimized indexes for:
- Date-based filtering (broadcast_date)
- Text search (title_search_vector)
- Episode lookups (episode_code)
- Relationship joins (foreign keys)

## API Implementation Notes

### Recommended Endpoints
- `GET /episodes?month=1` - Filter by broadcast month
- `GET /episodes?colors=Prussian Blue,Cadmium Yellow` - Filter by colors
- `GET /episodes?elements=MOUNTAIN,TREE` - Filter by subject matter
- `GET /episodes?search=winter` - Full-text search
- `GET /episodes?guest=true` - Special guest episodes

### Performance Tips
- Use the provided views for common queries
- Implement pagination for large result sets
- Consider caching for frequently accessed data
- Use the search function for text-based queries

## Troubleshooting

### Common Issues

1. **Script execution order**: Must run in the specified sequence
2. **Character encoding**: Ensure UTF-8 encoding for special characters
3. **Date formats**: Scripts handle various date formats automatically
4. **Missing relationships**: Verify all 5 scripts completed successfully

### Verification Queries
```sql
-- Check data completeness
SELECT 
    (SELECT COUNT(*) FROM episodes) as episodes,
    (SELECT COUNT(*) FROM colors) as colors,
    (SELECT COUNT(*) FROM subject_elements) as elements,
    (SELECT COUNT(*) FROM episode_colors) as color_relations,
    (SELECT COUNT(*) FROM episode_elements) as element_relations;
```

Expected results: 401 episodes, 18 colors, 67 elements, 4250 color relations, 2997 element relations

## Database Alternatives

### MySQL Setup
Replace PostgreSQL-specific syntax:
- `SERIAL` → `AUTO_INCREMENT`
- `TEXT[]` → `JSON` (for arrays)
- `tsvector` → `FULLTEXT` indexes

### SQL Server Setup
Replace PostgreSQL-specific syntax:
- `SERIAL` → `IDENTITY(1,1)`
- `TEXT[]` → `NVARCHAR(MAX)` (store as JSON)
- `tsvector` → `CONTAINS` for full-text search

## Support

For issues or questions:
1. Check the data_processing_report.txt for processing statistics
2. Verify all SQL files were generated correctly
3. Ensure database user has CREATE/INSERT permissions
4. Review the DATABASE_DESIGN.md for detailed schema documentation

---

*Database contains data from "The Joy of Painting" television series (1983-1994)*
