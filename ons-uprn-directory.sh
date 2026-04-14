#!/bin/bash
# ------------------------------------------------------------------------------
# Script: ons-postcode-directory.sh
# Description:
#   Downloads the latest ONS postcode directory,
#   cleans up, converts selected fields to Parquet (EPSG:4326).
# ------------------------------------------------------------------------------

# Strict mode: exit on error, undefined variables, and pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Prepare working directory
# ------------------------------------------------------------------------------
DATA_DIR="data/ons-uprn-directory"
mkdir -p "$DATA_DIR"  # Create directory if it doesn't exist
cd "$DATA_DIR"  # Change to data directory

# ------------------------------------------------------------------------------
# 2. Download and extract the ONS UPRN directory dataset
# ------------------------------------------------------------------------------
echo
echo "Downloading and Extracting ONS UPRN directory dataset..."
echo "For latest data please check: https://geoportal.statistics.gov.uk/search?q=PRD_ONSUD&sort=Date%20Created%7Ccreated%7Cdesc"
echo
echo
# Download the dataset from ArcGIS Hub
curl -L https://www.arcgis.com/sharing/rest/content/items/cf1e4c08e78d48e387bcfab837f4e1d0/data -o ons-uprn-directory.zip

# Extract the zip file ($_ represents the last argument from previous command)
unzip -o $_ "Data/*"

# Remove the zip file after extraction to save space
rm *.zip
echo

# ------------------------------------------------------------------------------
# 3. Convert CSV to Parquet using DuckDB
# ------------------------------------------------------------------------------

# Find the first CSV file in Data directory
first_csv=$(ls Data/ONSUD_*.csv 2>/dev/null | head -n 1)

# Check if any CSV file exists
if [ -z "$first_csv" ]; then
    echo "Error: No CSV files found in Data/ directory matching pattern ONSUD_*.csv"
    exit 1
fi

# Extract filename from path
filename=$(basename "$first_csv")

# Parse month, year, and area from filename format: ONSUD_$month_$year_$area.csv
# Example: ONSUD_DEC_2025_LN.csv
month=$(echo "$filename" | cut -d'_' -f2)
year=$(echo "$filename" | cut -d'_' -f3)

# Convert month to camel case (e.g., DEC -> Dec)
month=$(echo "$month" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')

# Create the output filename: ons-uprn-Dec-2025.parquet
parquet_file="ons-uprn-${month}-${year}.parquet"
echo "Processing ${month} ${year} UPRN dataset in Data/ -> $parquet_file"

# Use DuckDB to combine all CSVs and convert to single Parquet
area_codes_file="../ons-area-codes/ons-area-codes.parquet"
duckdb -c "
LOAD spatial;
SET geometry_always_xy = true;

COPY (
  WITH area_codes AS (
    SELECT * FROM read_parquet('${area_codes_file}')
  ),
  transformed AS (
    SELECT
      UPRN,
      PCDS,
      CTRY25CD,
      RGN25CD,
      CTY25CD,
      LAD25CD,
      PFA23CD,
      msoa21cd,
      lsoa21cd,
      OA21CD,
      ST_Transform(
        ST_MakePoint(GRIDGB1E, GRIDGB1N),
        'EPSG:27700',
        'EPSG:4326',
        true
      ) as geom
    FROM read_csv_auto('Data/*.csv', sample_size=-1)
  )
  SELECT
    t.UPRN as uprn,                     -- Unique Property Reference Number
    trim(t.PCDS) as postcode,           -- Postcode string with spaces removed from ends
    c.name as country,
    r.name as region,
    ct.name as county,
    la.name as local_authority,
    pf.name as police_force,
    m.name as msoa,                     -- Middle Layer Super Output Area
    l.name as lsoa,                     -- Lower Layer Super Output Area
    t.CTRY25CD as country_code,
    t.RGN25CD as region_code,
    t.CTY25CD as county_code,
    t.LAD25CD as local_authority_code,
    t.PFA23CD as police_force_code,
    t.msoa21cd as msoa_code,
    t.lsoa21cd as lsoa_code,
    t.OA21CD as oa_code,                -- Output Area
    ST_Y(t.geom) as latitude,
    ST_X(t.geom) as longitude
  FROM transformed t
  LEFT JOIN area_codes c ON t.CTRY25CD = c.code
  LEFT JOIN area_codes r ON t.RGN25CD = r.code
  LEFT JOIN area_codes ct ON t.CTY25CD = ct.code
  LEFT JOIN area_codes la ON t.LAD25CD = la.code
  LEFT JOIN area_codes pf ON t.PFA23CD = pf.code
  LEFT JOIN area_codes m ON t.msoa21cd = m.code
  LEFT JOIN area_codes l ON t.lsoa21cd = l.code
  ORDER BY t.UPRN ASC
) TO '${parquet_file}' (
  FORMAT 'parquet',
  COMPRESSION 'ZSTD'                    -- Zstandard compression
);
"
echo "Conversion complete! Output saved to: $parquet_file"
echo

echo "Compress the original CSV files to save disk space"
# Check if pigz is available (parallel gzip), otherwise use regular gzip
if command -v pigz &> /dev/null; then
    # Use pigz for faster parallel compression of the entire Data directory
    pigz -r Data
else
    # Fall back to regular gzip if pigz is not available
    gzip -r Data
fi

# ------------------------------------------------------------------------------
# 4. Display results
# ------------------------------------------------------------------------------
echo
echo "Conversion complete. Generated files:"
ls -lh  # List files with human-readable sizes (KB, MB, GB)

# ------------------------------------------------------------------------------
# 5. Return to project root directory
# ------------------------------------------------------------------------------
cd - >/dev/null  # Return to previous directory, suppress output with /dev/null
echo
echo "Done."
