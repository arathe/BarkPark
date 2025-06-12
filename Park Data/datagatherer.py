#!/usr/bin/env python3
"""
enrich_dog_runs_v1.py
─────────────────────
Download NYC Parks dog-run data and enrich each run with opening hours,
rating, phone, and website from the *Places API (New)*.

Requires
  pip install pandas requests tqdm python-dotenv
  export GOOGLE_PLACES_KEY="YOUR-KEY-HERE"   # v1 Places API key
"""

import os, time, requests, pandas as pd
from tqdm import tqdm
from dotenv import load_dotenv
load_dotenv()

# ────────────────────────── 1. NYC DOG-RUN DATA ──────────────────────────
DATASET = "hxx3-bwgv"
rows = requests.get(
    f"https://data.cityofnewyork.us/resource/{DATASET}.json",
    params={"$limit": 5000}).json()
df = pd.json_normalize(rows)

# tidy up column names and extract lon/lat from any geometry shape ------------
df = df.rename(columns={
    "name": "dogrun_name",
    "the_geom.coordinates": "coords",
    ":@longitude": "lon",
    ":@latitude": "lat",
    "longitude": "lon",
    "latitude": "lat"
})
if "lon" not in df:  # ensure cols exist
    df["lon"] = pd.NA
if "lat" not in df:
    df["lat"] = pd.NA


def first_lon_lat(coords):
    if not isinstance(coords, list):
        return None, None
    stack = [coords]
    while stack:
        item = stack.pop()
        if isinstance(item, list):
            if len(item) == 2 and all(isinstance(n, (int, float)) for n in item):
                return item[0], item[1]
            stack.extend(item)
    return None, None


if "coords" in df:
    lonlat = df["coords"].apply(first_lon_lat).tolist()
    df["lon_from_geom"] = [p[0] for p in lonlat]
    df["lat_from_geom"] = [p[1] for p in lonlat]

df["lon"] = df[["lon", "lon_from_geom"]].bfill(axis=1)
df["lat"] = df[["lat", "lat_from_geom"]].bfill(axis=1)

# ─────────── 2. PLACES API (v1) HELPERS ────────────
API_KEY = os.getenv("GOOGLE_PLACES_KEY")
if not API_KEY:
    raise ValueError(
        "GOOGLE_PLACES_KEY environment variable not set. "
        "Please set it with: export GOOGLE_PLACES_KEY='your-api-key'"
    )
BASE_URL = "https://maps.googleapis.com/maps/api/place"

def places_search(text, lat=None, lon=None, radius=200):
    params = {
        "query": text,
        "key": API_KEY,
        "fields": "place_id"
    }
    
    if pd.notna(lat) and pd.notna(lon):
        params["location"] = f"{float(lat)},{float(lon)}"
        params["radius"] = radius
    
    r = requests.get(
        f"{BASE_URL}/textsearch/json",
        params=params,
        timeout=10,
    )
    r.raise_for_status()
    results = r.json()
    if results.get("status") != "OK":
        return None
    return results.get("results", [None])[0]

DETAIL_FIELDS = (
    "name,opening_hours,rating,user_ratings_total,"
    "formatted_phone_number,website"
)

def place_details(place_id):
    r = requests.get(
        f"{BASE_URL}/details/json",
        params={
            "place_id": place_id,
            "key": API_KEY,
            "fields": DETAIL_FIELDS
        },
        timeout=10,
    )
    r.raise_for_status()
    result = r.json()
    if result.get("status") != "OK":
        return {}
    return result.get("result", {})

# ────────────────────────── 3. ENRICH EACH ROW ───────────────────────────
def enrich(row):
    query = f"{row.dogrun_name} dog run"
    place = places_search(query, row.lat, row.lon)
    if not place:
        return row                      # nothing found

    details = place_details(place["place_id"])

    # flatten what we care about
    hours = details.get("opening_hours", {}).get("weekday_text", [])
    row["g_hours"]   = "\n".join(hours)
    row["g_rating"]  = details.get("rating")
    row["g_reviews"] = details.get("user_ratings_total")
    row["g_phone"]   = details.get("formatted_phone_number")
    row["g_website"] = details.get("website")
    time.sleep(0.02)                   # stay well under QPS limit
    return row


tqdm.pandas(desc="Enriching")
enriched = df.progress_apply(enrich, axis=1)

# ────────────────────────── 4. SAVE CSV ──────────────────────────────────
OUT = "dog_runs_enriched.csv"
enriched.to_csv(OUT, index=False)
print(f"✅  {OUT} written – {len(enriched)} rows")
