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
echo "Downloading and Extracting the latest ONS UPRN directory dataset from ArcGIS Hub..."
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
echo "Processing all CSV files in Data/ -> $parquet_file"

# Use DuckDB to combine all CSVs and convert to single Parquet
duckdb -c "
COPY (
  SELECT
    UPRN as uprn,                    -- Unique Property Reference Number
    GRIDGB1E as easting,             -- Easting coordinate (OSGB36)
    GRIDGB1N as northing,            -- Northing coordinate (OSGB36)
    trim(PCDS) as postcode,          -- Postcode string with spaces removed from ends
    CTRY25CD as country,             -- Country code (E92...)
    RGN25CD as region,               -- Region code (E12...)
    CTY25CD as county,               -- County code
    LAD25CD as local_authority,      -- Local Authority District
    PFA23CD as police_force,         -- Police force area code
    msoa21cd as msoa,                -- Middle Layer Super Output Area code
    lsoa21cd as lsoa,                -- Lower Layer Super Output Area code
    OA21CD as oa                     -- Output Area code
  FROM read_csv_auto('Data/*.csv', sample_size=-1)   -- Read ALL CSV files
) TO '$parquet_file' (
  FORMAT 'parquet',
  COMPRESSION 'ZSTD'                       -- Zstandard compression
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
