.
# Open Data for InsurTech

High-quality geospatial data for insurtech applications is often constrained by expensive APIs, restrictive licensing, or fragmented and inconsistent formats.

The Geoparse `open-data-insurtech` repository addresses this challenge by providing a centralised, standardised, and open collection of geospatial datasets.

The project integrates data from the following providers:
* [Office for National Statistics (ONS)](https://www.ons.gov.uk/)
* [Ordnance Survey (OS)](https://www.ordnancesurvey.co.uk/)
* [Department for Transport (DfT)](https://www.gov.uk/government/organisations/department-for-transport/about/statistics)
* [Geofabrik](https://www.geofabrik.de/data/)

----
<details>
<summary><h1>Prerequisites</h1></summary>

## DuckDB

This repository uses `DuckDB`, a lightweight, in-process analytical database designed for fast querying of large datasets. Unlike traditional database servers, `DuckDB` runs directly inside your scripts or applications and can query files such as `CSV` and `Parquet` without requiring data to be imported first. It is often described as “SQLite for analytics” due to its simplicity and efficiency for analytical workloads. We use DuckDB to process raw datasets and export them into optimised Parquet format for high-performance analytics.

### Install DuckDB CLI

#### Linux and macOS

```bash
curl https://install.duckdb.org | sh
```

#### Windows
Follow the official installation guide:  
https://duckdb.org/install/?platform=windows&environment=cli

#### Install DuckDB Spatial Extension
After installing DuckDB, you need to install the spatial extension to enable geospatial operations during file processing, such as coordinate transformation (EPSG:27700 → EPSG:4326).
```
duckdb -c "INSTALL spatial;"
```

## GDAL
Before running the scripts in this repository, ensure that [GDAL](https://gdal.org/) is installed on your system. `GDAL` (Geospatial Data Abstraction Library) and `OGR` (OGR Simple Features Library) are essential tools for working with geospatial data. `GDAL` is designed for reading, writing, and processing raster geospatial data, such as satellite images and digital elevation models. It supports a variety of raster formats, including GeoTIFF, JPEG, PNG, and HDF5. On the other hand, `OGR` is specialized in handling vector geospatial data, including points, lines, and polygons, and supports formats like Shapefiles, GeoJSON, KML, PostGIS, and OSM PBF. 

A powerful feature within `GDAL/OGR` is the `ogr2ogr` command-line utility, which is dedicated to vector data manipulation and conversion. `ogr2ogr` allows users to convert vector data between formats (e.g., Shapefile to GeoJSON), filter and subset data using SQL-like queries, and reproject data to different coordinate reference systems (e.g., transforming WGS84 to a local `EPSG` code).

In summary, `GDAL` is tailored for raster data, `OGR` for vector data, and `ogr2ogr` provides versatile tools for converting, filtering, and reprojecting vector datasets.

On Debian-based Systems:
```bash
sudo apt update
sudo apt install gdal-bin

```

On macOS:
```bash
brew update
brew install gdal

```

You can upgrade GDAL on your system if it is already installed.
```bash
brew upgrade gdal    # macOS
sudo apt install --only-upgrade gdal-bin    # Debian

```

After completing the installation, verify it by running the following commands:
```bash
gdalinfo --version
ogrinfo --version

```

Both commands should return output similar to:

`GDAL 3.11.3 "Eganville", released 2025/07/12`

## Pigz (optional)

To save storage space, we automatically compress CSV files after processing. 
The scripts use `pigz` (parallel `gzip`) for faster compression if available, otherwise they fall back to standard `gzip`. 
macOS and all major Linux distributions come pre-installed with `gzip` as part of the standard Unix utilities, so it's always available as a reliable fallback. 
Both tools produce compatible `.gz` files, with `pigz` being significantly faster on multi-core systems while remaining optional.

On Debian-based Systems:

```bash
sudo apt update
sudo apt install pigz

```

On macOS:
```bash
brew update
brew install pigz

```
</details>

# Open Datasets

<details>
<summary><h2>ONS Postcode Directory</h2></summary>

Source: [ONS Postcode Directory](https://www.data.gov.uk/dataset/3793b22f-895a-491e-9388-63060189bcbb/onspd-online-latest-postcode-centroids)

The `ONS Postcode Directory` is a comprehensive dataset from the Office for National Statistics that provides geographic coordinates for every postcode unit across the UK. The dataset covers over 2.7 million postcodes, with approximately 1.8 million currently active.
Each record includes the postcode, its precise location and associated administrative boundary codes such as country, region, county and output area. 
Released under the Open Government Licence, it can be freely used for both commercial and non-commercial purposes with proper attribution.

The following script provides an automated pipeline for downloading, cleansing and converting postcode data into Parquet files.

```bash
./ons-postcode-directory.sh

```

The script automatically:
* Downloads the latest ONS Postcode Directory from ArcGIS Hub
* Cleanses and validates the data
* Converts coordinates to WGS84 (EPSG:4326)
* Outputs to compressed Parquet format

The generated Parquet file contains postcode-level geographic and administrative information with the following structure:

| Column            | Description                                                     |
| ----------------- | --------------------------------------------------------------- |
| **postcode**      | The standard spaced version of the postcode (e.g., “GL4 5EB”).  |
| **intr_date**     | Date (YYYYMM) when the postcode was introduced.                 |
| **term_date**     | Date (YYYYMM) when the postcode was terminated (NaN if active). |
| **user_type**     | User type indicator (0 = small users, 1 = large users).         |
| **country**       | ONS country code.                                               |
| **region**        | ONS region code.                                                |
| **county**        | County code (if applicable).                                    |
| **police_force**  | Police force area code.                                         |
| **msoa**          | Middle Layer Super Output Area 2021 code.                       |
| **lsoa**          | Lower Layer Super Output Area 2021 code.                        |
| **oa**            | Output Area 2021 code.                                          |
| **rural_urban**   | Rural–urban classification code.                                |
| **national_park** | National park area code (if applicable).                        |
| **lat**           | Latitude coordinate (WGS84).                                    |
| **lon**           | Longitude coordinate (WGS84).                                   |

The following sample shows the data structure stored in the Parquet file:


| postcode | intr_date | term_date | user_type | country   | region    | county    | police_force | msoa      | lsoa      | oa        | rural_urban | national_park | lat      | lon       |
| -------- | --------- | --------- | --------- | --------- | --------- | --------- | ------------ | --------- | --------- | --------- | ----------- | ------------- | -------- | --------- |
| GL4 5EB  | 199512    | NaN       | 0         | E92000001 | E12000009 | E10000013 | E23000037    | E02004645 | E01022281 | E00113243 | UN1         | E65000001     | 51.84167 | -2.198833 |
| PL6 5FN  | 201509    | NaN       | 0         | E92000001 | E12000009 | E99999999 | E23000035    | E02003126 | E01015092 | E00181102 | UN1         | E65000001     | 50.41151 | -4.113341 |
| DT2 8DS  | 198001    | NaN       | 0         | E92000001 | E12000009 | E99999999 | E23000039    | E02004266 | E01020490 | E00103879 | RSF1        | E65000001     | 50.67997 | -2.297255 |
| SA3 5EG  | 202303    | NaN       | 0         | W92000004 | W99999999 | W99999999 | W15000003    | W02000196 | W01000882 | W00004684 | UN1         | W31000001     | 51.58912 | -4.008486 |
| GU11 3UW | 199901    | 200009.0  | 1         | E92000001 | E12000008 | E10000014 | E23000030    | E02004812 | E01023117 | E00117455 | UN1         | E65000001     | 51.23632 | -0.760916 |

For more information on additional features included in the original `CSV` dataset, please refer to the User Guide available with the latest ONS Postcode Directory on the [UK Government Open Data Portal](https://www.data.gov.uk/search?q=postcode+directory+2025&filters%5Bpublisher%5D=&filters%5Btopic%5D=&filters%5Bformat%5D=&sort=best). Download the latest data and unzip it to find the User Guide.

</details>


<details>
<summary><h2>ONS UPRN Directory (Unique Property Reference Number)</h2></summary>

Source: [ONS UPRN Directory](https://geoportal.statistics.gov.uk/search?q=PRD_ONSUD&sort=Date%20Created%7Ccreated%7Cdesc)

The **Unique Property Reference Number (UPRN)** is a unique identifier assigned to every addressable location in Great Britain, including buildings, infrastructure and geographic features. It covers over 41 million locations and is maintained by **local authorities**, with national coordination provided by **GeoPlace** and **Ordnance Survey** as part of the [AddressBase](https://www.ordnancesurvey.co.uk/products/addressbase) dataset. A UPRN provides a persistent identifier throughout the entire lifecycle of a property, from creation to demolition, and is widely used as the standard reference for property and location data across the UK public sector.

The **ONS UPRN Directory (ONSUD)** relates each UPRN to a range of current statutory administrative, electoral, health and other statistical geographies. The ONSUD is produced by ONS Geography, who provide geographic support to the Office for National Statistics (ONS) and geographic services used by other organisations. The ONSUD is issued every 6 weeks and is designed to complement the Ordnance Survey AddressBase product.

You can download the latest ONS UPRN Directory dataset from the [Open Geography Portal](https://geoportal.statistics.gov.uk/search?q=PRD_ONSUD&sort=Date%20Created%7Ccreated%7Cdesc) on the Office for National Statistics website. Earlier and later releases can be found under the **UPRNs** tab at the top right of the page.

Alternatively, you can run the script directly:

```bash
./ons-uprn-directory.sh

```
This will download, process, and save the latest ONS UPRN Directory dataset as a `Parquet` file in the `data/ons-uprn-directory/` directory.
The following sample shows the data structure stored in the Parquet file:

| uprn | postcode | country | region | county | local_authority | police_force | msoa | lsoa | country_code | region_code | county_code | local_authority_code | police_force_code | msoa_code | lsoa_code | oa_code | latitude | longitude |
|------|----------|---------|--------|--------|-----------------|--------------|------|------|--------------|-------------|-------------|----------------------|-------------------|-----------|-----------|---------|----------|-----------|
| 1 | BS1 5TR | England | South West | (pseudo) England (UA/MD/LB) | Bristol | Avon and Somerset | Bristol 061 | Bristol 061C | E92000001 | E12000009 | E99999999 | E06000023 | E23000036 | E02006952 | E01033909 | E00178046 | 51.45260710824023 | -2.6020684520374964 |
| 26 | BS11 0YA | England | South West | (pseudo) England (UA/MD/LB) | South Gloucestershire | Avon and Somerset | Bristol 003 | Bristol 003B | E92000001 | E12000009 | E99999999 | E06000025 | E23000036 | E02003014 | E01014498 | E00073219 | 51.52663521970842 | -2.6793564828149075 |
| 27 | BS11 0YA | England | South West | (pseudo) England (UA/MD/LB) | South Gloucestershire | Avon and Somerset | Bristol 003 | Bristol 003B | E92000001 | E12000009 | E99999999 | E06000025 | E23000036 | E02003014 | E01014498 | E00073219 | 51.52663521970842 | -2.6793564828149075 |
| 30 | BS10 7RZ | England | South West | (pseudo) England (UA/MD/LB) | South Gloucestershire | Avon and Somerset | Bristol 003 | Bristol 003B | E92000001 | E12000009 | E99999999 | E06000025 | E23000036 | E02003014 | E01014498 | E00073219 | 51.52131886100828 | -2.6528581344042537 |
| 31 | BS10 7RZ | England | South West | (pseudo) England (UA/MD/LB) | South Gloucestershire | Avon and Somerset | Bristol 003 | Bristol 003B | E92000001 | E12000009 | E99999999 | E06000025 | E23000036 | E02003014 | E01014498 | E00073219 | 51.521237622440935 | -2.6529146245607977 |


</details>

<details>
<summary><h2>ONS Area Codes</h2></summary>

Source: [ONS Postcode Directory](https://www.data.gov.uk/dataset/7db80b46-2bb2-4f15-81e4-159b5b9ff5fd/ons-postcode-directory-august-2025-for-the-uk)
and [ONS UPRN Directory](https://www.data.gov.uk/dataset/a615e841-c79e-4566-a422-0618faca9634/ons-uprn-directory-october-2025-epoch-121)

The following script automates the creation of a comprehensive ONS area codes dictionary by downloading both the Postcode and UPRN directories from ArcGIS Hub, extracting geographic area codes and names from various administrative boundary files (including countries, regions, counties, local authorities, and statistical areas), processing them into standardized CSV formats with proper quoting and deduplication, and finally merging both datasets into a single unified area codes reference file for data analysis and mapping purposes.

```bash
./one-area-codes.sh

```

Here’s a sample of the resulting dataset:

```
"N21000640","Carntogher_D"
"E01034396","Liverpool 010G"
"E02001206","Stockport 020"
"W01000581","Pembrokeshire 003B"
"S01016956","Hillington - 04"
```
</details>


<details>
<summary><h2>ONS Administrative Boundaries</h2></summary>

The Office for National Statistics (ONS) provides administrative boundary data for various geographic levels across the UK, including countries, English regions, counties, local authority districts, parishes, and wards. 
Each boundary dataset is available in multiple spatial resolutions and coastline generalisations to balance spatial accuracy with processing performance. 
Each boundary file includes a suffix such as `BFC`, `BFE`, `BGC`, `BSC`, or `BUC` that indicates both the detail level and whether the boundary is clipped to the coastline or includes the extent of the realm (i.e., offshore areas).
These options let you balance geometric accuracy with file size and performance, depending on your analysis or mapping needs.

Use full resolution versions (BFC/BFE) for analysis or precise overlays, and generalised versions (BGC/BSC/BUC) for visualisation, web mapping, or when handling large datasets.
Choose “clipped” versions when you only need land boundaries, or “extent of realm” when including sea/offshore territories is important.

| Code    | Meaning                                                       | Detail                                                                   |
| ------- | ------------------------------------------------------------- | ------------------------------------------------------------------------ |
| **BFE** | Boundary – Full resolution, *Extent of the Realm*             | Highest-detail geometry including offshore areas and islands.            |
| **BFC** | Boundary – Full resolution, *Clipped to coastline*            | Same high-detail boundary, but trimmed at the mean high-water coastline. |
| **BGC** | Boundary – Generalised (~20 m), *Clipped to coastline*        | Simplified geometry suitable for most mapping and display purposes.      |
| **BSC** | Boundary – Super-generalised (~200 m), *Clipped to coastline* | Coarser generalisation for lightweight, large-scale mapping.             |
| **BUC** | Boundary – Ultra-generalised (~500 m), *Clipped to coastline* | Smallest and simplest file size, least geometric detail.                 |


<details>
<summary><h3>Countries</h3></summary>

Source: [ONS Countries Boundaries](https://geoportal.statistics.gov.uk/search?q=BDY_CTRY%3BDEC_2024&sort=Title%7Ctitle%7Casc)

First, download the five GeoPackage files for all spatial resolutions (BFC, BFE, BGC, BSC, and BUC) from [this link](https://geoportal.statistics.gov.uk/search?q=BDY_CTRY%3BDEC_2024&sort=Title%7Ctitle%7Casc).
Then, run the following scripts to process the data and convert them to Parquet format.

```bash

./ons-admin-country.sh

```
</details>



<details>
<summary><h3>Regions</h3></summary>

Source: [ONS Regions Boundaries](https://geoportal.statistics.gov.uk/search?q=BDY_RGN%3BDEC_2024&sort=Title%7Ctitle%7Casc)

Download the five GeoPackage files for all spatial resolutions (BFC, BFE, BGC, BSC, and BUC) from [this link](https://geoportal.statistics.gov.uk/search?q=BDY_RGN%3BDEC_2024&sort=Title%7Ctitle%7Casc).
Then, run the following scripts to process the data and convert them to Parquet format.

```bash

./ons-admin-region.sh

```
</details>

<details>
<summary><h3>Counties and Unitary Authorities</h3></summary>

Source: [ONS Counties and Unitary Authorities Boundaries](https://geoportal.statistics.gov.uk/search?q=BDY_CTYUA%202024&sort=Title%7Ctitle%7Casc)

Download the five GeoPackage files for all spatial resolutions (BFC, BFE, BGC, BSC, and BUC) from [this link](https://geoportal.statistics.gov.uk/search?q=BDY_CTYUA%202024&sort=Title%7Ctitle%7Casc).
Then, run the following scripts to process the data and convert them to Parquet format.

```bash

./ons-admin-county-ua.sh

```
</details>

</details>


<details>
<summary><h2>ONS Census Boundaries</h2></summary>

Source: [https://www.data.gov.uk/dataset/4a880a9b-b509-4a82-baf1-07e3ce104f4b/output-areas1](https://www.data.gov.uk/dataset/4a880a9b-b509-4a82-baf1-07e3ce104f4b/output-areas1)

`ons-output-area.sh` processes socio-economic data for different geographic layers in England and Wales, following the Office for National Statistics (ONS) spatial hierarchy. The smallest statistical building block is the `Census Output Area (OA)`, representing a compact group of households designed for detailed local analysis. `Lower-layer Super Output Areas (LSOA)` combine multiple OAs to ensure population stability over time, while `Middle-layer Super Output Areas (MSOA)` group several LSOAs to create larger, consistent geographic zones suitable for public reporting and policy analysis.

```bash

./ons-output-area.sh

```
</details>



<details>
<summary><h2>ONS Income Data</h2></summary>

Source: [Income estimates for small areas, England and Wales - Office for National Statistics (ONS)](https://www.ons.gov.uk/employmentandlabourmarket/peopleinwork/earningsandworkinghours/datasets/smallareaincomeestimatesformiddlelayersuperoutputareasenglandandwales)

The Excel file on the above page contains separate sheets for:

* Total annual household income
* Net annual income
* Net income before housing costs
* Net income after housing costs

Data are provided at the `Middle Layer Super Output Area (MSOA)` level for England and Wales.
Each MSOA is represented by three values — the `lower confidence limit`, `mean estimate`, and `upper confidence limit` 
which together form a 95% confidence interval.
A `95% confidence interval` means that we can be 95% confident the true mean household income 
for each area lies between the lower and upper confidence limits. For further details, see the [Technical Report from Office for Natioanl Statistics, page 30.](https://www.ons.gov.uk/file?uri=/employmentandlabourmarket/peopleinwork/earningsandworkinghours/methodologies/smallareaincomeestimatesmodelbasedestimatesofthemeanhouseholdweeklyincomeformiddlelayersuperoutputareas201314technicalreport/householdincometechnicalreport.pdf)

The following script automates the process of downloading and converting income data into Parquet files, processing each sheet individually.

```bash
./ons-income.sh

```
</details>


<details>
<summary><h2>OS Open USRN (Unique Street Reference Number) </h2></summary>

Source: [https://osdatahub.os.uk/downloads/open/OpenUSRN](https://osdatahub.os.uk/downloads/open/OpenUSRN)

Unique Street Reference Number (USRN), is a nationally recognised identifier used in Great Britain to uniquely reference every street, including roads, footpaths, cycleways and alleys. It forms part of the national addressing system and is maintained through the [National Street Gazetteer](https://www.geoplace.co.uk/addresses-streets/street-data-and-services/national-street-gazetteer), which is compiled and updated by local authorities. Much like the Unique Property Reference Number (UPRN) identifies individual properties, the USRN ensures that each street has a consistent reference across different datasets and organisations. This makes it essential for activities such as managing streetworks permits, supporting navigation and transport planning, enabling emergency services, and integrating data across government and utility providers.

You can download the latest USRN dataset from [Ordnance Survey Data Hub](https://osdatahub.os.uk/downloads/open/OpenUSRN) as a `GeoPackage` file. 
The following command displays detailed information about the GeoPackage file's structure and contents.

```bash
ogrinfo -al -so osopenusrn_202510.gpkg

```

**Command Breakdown:**
* `ogrinfo`: GDAL/OGR utility for getting information about geospatial datasets
* `-al`: All layers - shows information about all layers in the dataset
* `-so`: Summary only - shows only the summary (no feature data)
* `osopenusrn_202509.gpkg`: The input GeoPackage file

The following commands downloads the GeoPackage file, process and export it into a Parquet file using `ogr2ogr`.

```bash
./os-open-usrn.sh
```

</details>

<details>
<summary><h2>OS Open Roads</h2></summary>

Source: [https://osdatahub.os.uk/downloads/open/OpenRoads](https://osdatahub.os.uk/downloads/open/OpenRoads)

```bash
./os-open-roads.sh

```

</details>

<details>
<summary><h2>OS Open Greenspace</h2></summary>

Source: [https://osdatahub.os.uk/data/downloads/open/OpenGreenspace](https://osdatahub.os.uk/data/downloads/open/OpenGreenspace)

OS Open Greenspace is a definitive geospatial dataset from Ordnance Survey that provides the location and classification of public parks, sports facilities, and other accessible greenspaces across Great Britain. For the insurance industry, this data is critical for enhancing risk models for property and liability underwriting by precisely quantifying exposure to greenspace-related perils—such as public injury liability in parks, vandalism or theft risk for properties adjacent to open spaces, and subsidence potential influenced by tree root systems from nearby allotments or gardens.

The provided `GeoPackage` file contains two spatial layers: an `access_point` layer with point locations for green space entries and a `greenspace_site` layer with MultiPolygon geometries representing the physical boundaries of those green spaces.
The dataset is available for free under the Open Government License from the OS Data Hub.

The following script processes this data, generating two corresponding `Parquet` files named `access_point.parquet` and `greenspace_site.parquet`.


```bash
./os-open-greenspace.sh

```

</details>


<details>
<summary><h2>OS Open Names</h2></summary>

Source: [https://osdatahub.os.uk/data/downloads/open/OpenNames](https://osdatahub.os.uk/data/downloads/open/OpenNames)

OS Open Names is a dataset from Ordnance Survey that provides the most comprehensive index of place names, road names, and postcodes across Great Britain. This section includes tools and examples for accessing, processing, and analysing OS Open Names data — helping you link locations to coordinates, perform spatial lookups, and integrate authoritative geographic names into your applications or analyses.


```bash
./os-open-names.sh

```
</details>


<details>
<summary><h2>OpenStreetMap (OSM)</h2></summary>

Source: [https://download.geofabrik.de/](https://download.geofabrik.de/)

[OpenStreetMap (OSM)](https://www.openstreetmap.org) is a collaborative, community-driven project that provides freely available geographic data covering the entire world. It includes detailed information about roads, buildings, land use, waterways, and many other physical and human-made features. [Geofabrik](https://www.geofabrik.de/) offers regularly updated regional extracts of OSM data, which are particularly useful for analytical workflows that focus on specific countries or administrative areas.

The following script automatically extracts structured OSM data for the United Kingdom from Geofabrik and converts each layer—such as points, lines, multipolygons, and other relations—into separate Parquet files (e.g., `points.parquet`, `lines.parquet`) for efficient geospatial analysis. A list of other available regions and countries can be found on the [Geofabrik download page](https://download.geofabrik.de/).

```bash
./geofabrik-osm.sh europe united-kingdom

```

This pipeline leverages those extracts to produce lightweight, analysis-ready datasets that can be easily queried, filtered, and joined with other spatial layers, making them ideal for applications in exposure management, urban planning, mobility analytics, and environmental modelling.

</details>

<details>
<summary><h2>DfT Road Traffic</h2></summary>

Source: [https://roadtraffic.dft.gov.uk/downloads](https://roadtraffic.dft.gov.uk/downloads)

This section provides a curated dataset and processing scripts for road traffic statistics in Great Britain. The data is sourced from the UK Department for Transport's (DfT) [public archive](https://roadtraffic.dft.gov.uk/downloads), which offers detailed estimates of vehicle traffic volume, classified by vehicle type and road category. The primary functions of this section are to automate the download of these official statistics, clean and standardize the data, and make it readily accessible for analysis—enabling trends in traffic flow, the impact of policy changes, and regional transportation patterns to be explored efficiently.

This following commands downloads the `CSV` files, process and export them into a `Parquet` files using `DuckDB`.


```bash
./dft-road-traffic.sh
```

</details>


<details>
<summary><h2>DfT Road Safety - STATS19</h2></summary>

Source: [STATS19](https://www.data.gov.uk/dataset/road-accidents-safety-data)

This section provides an automated pipeline for processing UK Department for Transport (DfT) road safety statistics. The script downloads official road safety data from [GOV.UK](https://www.gov.uk/government/statistics/road-safety-data) and converts it from `CSV` to `Parquet` format for efficient storage and analysis. The data covers road collisions, casualties, and vehicle information from 1979 to the latest published year.

The pipeline handles three key datasets: collision data (incident circumstances and locations), casualty data (individual injury records and demographics), and vehicle data (vehicle types and involvement details). The conversion to `Parquet` format significantly reduces file sizes and improves query performance for data analysis.

To use this pipeline, ensure you have `bash`, `wget`, and `DuckDB` installed. Simply run the provided shell script to automatically download the latest data, convert it to `Parquet` format, and organize the files for analysis. The processed data is ideal for road safety research, traffic analysis, and statistical reporting.

```bash
./dft-road-safety.sh

```
</details>


<details>
<summary><h2>UK Police Open Data</h2></summary>

Source: [https://data.police.uk/data/archive/](https://data.police.uk/data/archive/)

This section contains an automated pipeline for downloading, processing, and converting the last 36 months of data from the UK police public archive. The system programmatically retrieves bulk CSV files for crime, outcomes, and stop-and-search data from the structured monthly archives.

The following script automates the downloading of the last three years of data and its subsequent conversion into a partitioned Parquet format. This process ensures efficient storage and prepares the dataset for high-performance analytics.

```bash
./uk-police-data.sh
```

</details>



---
# License
For each dataset, please refer to the licence file located in the corresponding directory.

---
# Support
For issues or questions, feel free to create an issue in the repository or contact the maintainer.

---
# Contributing
Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.
