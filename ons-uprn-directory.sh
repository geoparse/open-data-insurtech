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
# Loop through all CSV files in the Data directory
for csv_file in Data/*.csv; do
    # Check if the file exists and is a regular file (not a directory)
    if [ -f "$csv_file" ]; then
        # Get the base filename without extension
        filename=$(basename "$csv_file" .csv)
        
        # Set output path for parquet file
        parquet_file="${filename}.parquet"
        
        echo "Processing: $csv_file -> $parquet_file"
        
        # Use DuckDB to convert CSV to Parquet
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
          FROM read_csv_auto('$csv_file', sample_size=-1)   -- Read entire file for schema detection
        ) TO '$parquet_file' (
          FORMAT 'parquet',
          COMPRESSION 'zstd'
        );                                   -- Output to Parquet format
        "
    fi
done

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
