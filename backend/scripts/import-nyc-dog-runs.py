#!/usr/bin/env python3
"""
Import NYC dog runs data from CSV to PostgreSQL
Converts the dog_runs_enriched.csv data into SQL INSERT statements
"""

import pandas as pd
import re
import json
from datetime import time

def parse_hours(hours_str):
    """Parse Google hours format into opening/closing times"""
    if pd.isna(hours_str) or not hours_str:
        return None, None
    
    # Extract first day's hours as a representative schedule
    # Format: "Monday: 6:00 AM – 9:00 PM\nTuesday: ..."
    lines = hours_str.split('\n')
    if not lines:
        return None, None
    
    first_day = lines[0]
    # Extract time range using regex
    time_pattern = r'(\d{1,2}:\d{2})\s*([AP]M)\s*[–-]\s*(\d{1,2}:\d{2})\s*([AP]M)'
    match = re.search(time_pattern, first_day)
    
    if not match:
        return None, None
    
    try:
        open_time = match.group(1)
        open_ampm = match.group(2)
        close_time = match.group(3)
        close_ampm = match.group(4)
        
        # Convert to 24-hour format
        open_hour, open_min = map(int, open_time.split(':'))
        if open_ampm == 'PM' and open_hour != 12:
            open_hour += 12
        elif open_ampm == 'AM' and open_hour == 12:
            open_hour = 0
            
        close_hour, close_min = map(int, close_time.split(':'))
        if close_ampm == 'PM' and close_hour != 12:
            close_hour += 12
        elif close_ampm == 'AM' and close_hour == 12:
            close_hour = 0
        
        return f"{open_hour:02d}:{open_min:02d}:00", f"{close_hour:02d}:{close_min:02d}:00"
    except:
        return None, None

def clean_string(s):
    """Clean string for SQL insertion"""
    if pd.isna(s):
        return None
    return str(s).replace("'", "''").strip()

def borough_name(code):
    """Convert borough code to full name"""
    mapping = {
        'B': 'Brooklyn',
        'X': 'Bronx', 
        'Q': 'Queens',
        'M': 'Manhattan',
        'R': 'Staten Island'
    }
    return mapping.get(code, code)

def generate_amenities(row):
    """Generate amenities array from available data"""
    amenities = []
    
    if not pd.isna(row.get('surface')) and row['surface']:
        amenities.append(f"{row['surface']} surface")
    
    if row.get('seating') == 'Yes':
        amenities.append('Seating available')
    
    if not pd.isna(row.get('g_rating')) and float(row['g_rating']) >= 4.5:
        amenities.append('Highly rated')
        
    return amenities

def main():
    # Read CSV data
    df = pd.read_csv('/Users/austinrathe/Documents/Developer/BarkPark/Park Data/dog_runs_enriched.csv')
    
    print(f"Processing {len(df)} dog runs...")
    
    # Generate SQL statements
    sql_statements = []
    sql_statements.append("-- NYC Dog Runs Import")
    sql_statements.append("-- Generated from dog_runs_enriched.csv")
    sql_statements.append("")
    
    for idx, row in df.iterrows():
        name = clean_string(row['dogrun_name'])
        if not name:
            continue
            
        # Basic info
        description = f"NYC Parks Department dog run in {borough_name(row.get('borough', ''))}"
        address = f"{name}, New York, NY {row.get('zipcode', '')}"
        
        # Location
        lat = row.get('lat')
        lon = row.get('lon')
        if pd.isna(lat) or pd.isna(lon):
            continue
            
        # Hours
        hours_open, hours_close = parse_hours(row.get('g_hours'))
        
        # Amenities
        amenities = generate_amenities(row)
        amenities_sql = "'{" + ','.join([f'"{a}"' for a in amenities]) + "}'" if amenities else "NULL"
        
        # New fields
        website = clean_string(row.get('g_website'))
        phone = clean_string(row.get('g_phone'))
        rating = row.get('g_rating') if not pd.isna(row.get('g_rating')) else None
        review_count = int(row.get('g_reviews')) if not pd.isna(row.get('g_reviews')) else None
        surface_type = clean_string(row.get('surface'))
        has_seating = None
        if row.get('seating') == 'Yes':
            has_seating = True
        elif row.get('seating') == 'No':
            has_seating = False
        zipcode = clean_string(row.get('zipcode'))
        borough = borough_name(row.get('borough', ''))
        
        # Build INSERT statement
        sql = f"""INSERT INTO dog_parks (
    name, description, address, latitude, longitude, amenities, rules,
    hours_open, hours_close, website, phone, rating, review_count,
    surface_type, has_seating, zipcode, borough, created_at, updated_at
) VALUES (
    '{name}',
    '{description}',
    '{address}',
    {lat},
    {lon},
    {amenities_sql},
    'Please follow NYC Parks Department rules and regulations',
    {f"'{hours_open}'" if hours_open else 'NULL'},
    {f"'{hours_close}'" if hours_close else 'NULL'},
    {f"'{website}'" if website else 'NULL'},
    {f"'{phone}'" if phone else 'NULL'},
    {rating if rating else 'NULL'},
    {review_count if review_count else 'NULL'},
    {f"'{surface_type}'" if surface_type else 'NULL'},
    {has_seating if has_seating is not None else 'NULL'},
    {f"'{zipcode}'" if zipcode else 'NULL'},
    '{borough}',
    NOW(),
    NOW()
);"""
        
        sql_statements.append(sql)
        sql_statements.append("")
    
    # Write to file
    output_file = '/Users/austinrathe/Documents/Developer/BarkPark/backend/scripts/import-nyc-dog-runs.sql'
    with open(output_file, 'w') as f:
        f.write('\n'.join(sql_statements))
    
    print(f"Generated SQL import script: {output_file}")
    print(f"Ready to import {len(df)} NYC dog runs")

if __name__ == "__main__":
    main()