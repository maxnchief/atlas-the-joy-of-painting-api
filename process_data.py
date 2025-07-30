#!/usr/bin/env python3
"""
Data Processing Script for The Joy of Painting Database
Processes CSV files and broadcast date file to generate SQL insert statements
"""

import csv
import re
import json
from datetime import datetime
from typing import Dict, List, Tuple, Optional
import os

def parse_broadcast_date(date_line: str) -> Tuple[str, Optional[str], Optional[str]]:
    """
    Parse a line from broadcast_date file
    Returns: (title, date, special_guest)
    """
    # Pattern to match: "Title" (Date) [Optional guest info]
    pattern = r'"([^"]+)"\s*\(([^)]+)\)(?:\s+(.+))?'
    match = re.match(pattern, date_line.strip())
    
    if not match:
        return "", None, None
    
    title = match.group(1)
    date_str = match.group(2)
    guest_info = match.group(3) if match.group(3) else None
    
    # Parse the date
    try:
        date_formats = [
            "%B %d, %Y",  # "January 11, 1983"
            "%b %d, %Y",  # "Jan 11, 1983"
        ]
        
        parsed_date = None
        for fmt in date_formats:
            try:
                parsed_date = datetime.strptime(date_str, fmt).strftime('%Y-%m-%d')
                break
            except ValueError:
                continue
        
        if not parsed_date:
            print(f"Could not parse date: {date_str}")
            return title, None, guest_info
            
    except Exception as e:
        print(f"Error parsing date {date_str}: {e}")
        return title, None, guest_info
    
    # Extract guest name if present
    special_guest = None
    if guest_info:
        if "Special guest" in guest_info:
            guest_match = re.search(r'Special guest\s+([^(]+)', guest_info)
            if guest_match:
                special_guest = guest_match.group(1).strip()
        elif "Guest Artist" in guest_info:
            guest_match = re.search(r'Guest Artist:\s*([^(]+)', guest_info)
            if guest_match:
                special_guest = guest_match.group(1).strip()
        elif "featuring" in guest_info:
            guest_match = re.search(r'featuring\s+([^(]+)', guest_info)
            if guest_match:
                special_guest = guest_match.group(1).strip()
    
    return title, parsed_date, special_guest

def parse_color_list(color_str: str) -> List[str]:
    """Parse the color list string from CSV"""
    try:
        # Remove extra whitespace and newlines
        color_str = color_str.strip()
        if color_str.startswith('[') and color_str.endswith(']'):
            # Parse as JSON-like list
            colors = eval(color_str)  # Safe because we control the data
            return [color.strip().replace('\r\n', '').replace('\n', '') for color in colors]
        else:
            # Parse as comma-separated
            return [color.strip() for color in color_str.split(',')]
    except Exception as e:
        print(f"Error parsing color list: {color_str}, error: {e}")
        return []

def generate_episode_code(season: int, episode: int) -> str:
    """Generate episode code in format S##E##"""
    return f"S{season:02d}E{episode:02d}"

def normalize_title(title: str) -> str:
    """Normalize title for matching across different data sources"""
    return title.strip('"').upper().replace("'", "").replace("&", "AND")

def clean_title(title: str) -> str:
    """Clean title by removing extra quotes and escaping single quotes"""
    title = title.strip('"')
    title = title.replace("'", "''")  # Escape single quotes for SQL
    return title

def process_data_files():
    """Process all data files and generate SQL insert statements"""
    
    base_path = "/home/maxnchief/atlas-the-joy-of-painting-api-1"
    
    # Read broadcast dates
    print("Reading broadcast dates...")
    broadcast_data = {}
    
    try:
        with open(f"{base_path}/brodcast_date", 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip():
                    title, date, guest = parse_broadcast_date(line)
                    if title:
                        broadcast_data[title] = {
                            'date': date,
                            'guest': guest
                        }
    except Exception as e:
        print(f"Error reading broadcast dates: {e}")
        return
    
    print(f"Processed {len(broadcast_data)} broadcast entries")
    
    # Read color palette data
    print("Reading color palette data...")
    color_data = {}
    
    try:
        with open(f"{base_path}/color_palette", 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                title = row['painting_title']
                color_data[title] = {
                    'painting_index': row['painting_index'],
                    'img_src': row['img_src'],
                    'season': int(row['season']),
                    'episode': int(row['episode']),
                    'num_colors': int(row['num_colors']),
                    'youtube_src': row['youtube_src'],
                    'colors': parse_color_list(row['colors'])
                }
    except Exception as e:
        print(f"Error reading color palette: {e}")
        return
    
    print(f"Processed {len(color_data)} color palette entries")
    
    # Read subject matter data
    print("Reading subject matter data...")
    subject_data = {}
    
    try:
        with open(f"{base_path}/subject_matter", 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                episode_code = row['EPISODE']
                title = row['TITLE'].strip('"')
                
                # Get elements where value is 1
                elements = [k for k, v in row.items() if k not in ['EPISODE', 'TITLE'] and v == '1']
                subject_data[title] = {
                    'episode_code': episode_code,
                    'elements': elements
                }
    except Exception as e:
        print(f"Error reading subject matter: {e}")
        return
    
    print(f"Processed {len(subject_data)} subject matter entries")
    
    # Generate SQL inserts
    print("Generating SQL insert statements...")
    
    sql_episodes = []
    sql_episode_colors = []
    sql_episode_elements = []
    
    episode_id = 1
    
    # Match data across all three sources
    processed_count = 0
    for title in color_data.keys():
        color_info = color_data[title]
        broadcast_info = broadcast_data.get(title, {})
        subject_info = subject_data.get(title, {})
        
        episode_code = generate_episode_code(color_info['season'], color_info['episode'])
        
        # Prepare episode insert
        broadcast_date = broadcast_info.get('date')
        if broadcast_date:
            broadcast_date_sql = f"'{broadcast_date}'"
        else:
            broadcast_date_sql = 'NULL'
        
        special_guest = broadcast_info.get('guest')
        if special_guest:
            escaped_guest = special_guest.replace("'", "''")
            special_guest_sql = f"'{escaped_guest}'"
        else:
            special_guest_sql = 'NULL'
        
        clean_title_text = clean_title(title)
        img_src_sql = f"'{color_info['img_src']}'" if color_info['img_src'] else 'NULL'
        youtube_src_sql = f"'{color_info['youtube_src']}'" if color_info['youtube_src'] else 'NULL'
        
        # Episode insert
        sql_episodes.append(f"""INSERT INTO episodes (episode_id, season, episode, episode_code, title, broadcast_date, painting_index, img_src, youtube_src, num_colors, special_guest)
VALUES ({episode_id}, {color_info['season']}, {color_info['episode']}, '{episode_code}', '{clean_title_text}', {broadcast_date_sql}, {color_info['painting_index']}, {img_src_sql}, {youtube_src_sql}, {color_info['num_colors']}, {special_guest_sql});"""
        )
        
        # Episode colors
        for color_name in color_info['colors']:
            color_name_clean = color_name.strip().replace('\r\n', '').replace('\n', '').replace("'", "''")
            if color_name_clean:
                sql_episode_colors.append(f"""INSERT INTO episode_colors (episode_id, color_id) 
SELECT {episode_id}, color_id FROM colors WHERE color_name = '{color_name_clean}';""")
        
        # Episode elements
        for element in subject_info.get('elements', []):
            sql_episode_elements.append(f"""INSERT INTO episode_elements (episode_id, element_id) 
SELECT {episode_id}, element_id FROM subject_elements WHERE element_name = '{element}';""")
        
        episode_id += 1
        processed_count += 1
    
    # Write SQL files
    print("Writing SQL files...")
    
    with open(f"{base_path}/03_insert_episodes.sql", 'w') as f:
        f.write("-- ============================================================================\n")
        f.write("-- Episode Data Inserts\n")
        f.write("-- ============================================================================\n\n")
        f.write("-- Insert Episodes\n")
        for sql in sql_episodes:
            f.write(sql + "\n\n")
        f.write("COMMIT;\n")
    
    with open(f"{base_path}/04_insert_episode_colors.sql", 'w') as f:
        f.write("-- ============================================================================\n")
        f.write("-- Episode Colors Relationship Data\n")
        f.write("-- ============================================================================\n\n")
        f.write("-- Insert Episode-Color relationships\n")
        for sql in sql_episode_colors:
            f.write(sql + "\n")
        f.write("\nCOMMIT;\n")
    
    with open(f"{base_path}/05_insert_episode_elements.sql", 'w') as f:
        f.write("-- ============================================================================\n")
        f.write("-- Episode Elements Relationship Data\n")
        f.write("-- ============================================================================\n\n")
        f.write("-- Insert Episode-Element relationships\n")
        for sql in sql_episode_elements:
            f.write(sql + "\n")
        f.write("\nCOMMIT;\n")
    
    print(f"Successfully processed {processed_count} episodes")
    print(f"Generated {len(sql_episodes)} episode records")
    print(f"Generated {len(sql_episode_colors)} color relationships")
    print(f"Generated {len(sql_episode_elements)} element relationships")
    print("\nSQL files created:")
    print("- 03_insert_episodes.sql")
    print("- 04_insert_episode_colors.sql") 
    print("- 05_insert_episode_elements.sql")

    # Create a summary report
    with open(f"{base_path}/data_processing_report.txt", 'w') as f:
        f.write("The Joy of Painting Data Processing Report\n")
        f.write("=" * 50 + "\n\n")
        f.write(f"Total episodes processed: {processed_count}\n")
        f.write(f"Total color relationships: {len(sql_episode_colors)}\n")
        f.write(f"Total element relationships: {len(sql_episode_elements)}\n")
        f.write(f"Broadcast dates found: {len(broadcast_data)}\n")
        f.write(f"Color palette entries: {len(color_data)}\n")
        f.write(f"Subject matter entries: {len(subject_data)}\n\n")
        
        # Show episodes with special guests
        guest_episodes = []
        for title, data in broadcast_data.items():
            if data.get('guest'):
                guest_episodes.append(f"- {title}: {data['guest']}")
        
        f.write(f"Episodes with special guests ({len(guest_episodes)}):\n")
        for episode in guest_episodes:
            f.write(episode + "\n")

if __name__ == "__main__":
    process_data_files()
