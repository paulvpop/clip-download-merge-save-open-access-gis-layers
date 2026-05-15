# Author: Paul Pop
# Affiliation: BIRD Lab, ATREE, Bengaluru (PI: Rajkamal Goswami)
--------------------------------------------------------------------------------------------------------------------------------------------------------------

# This an R script to load, and save Google Open Buildings data in Parquet format - individual files will be saved for each corresponding csv. 

# First set your working directory
# Ctrl+Shift+H
# OR 
# setwd("D:/GIS_files/Arunachal")
# Change the path to your directory path if using

# Load required libraries
library(sf)
library(dplyr)
library(purrr)

# Read and merge multiple csv files (csv is the default format when downloading
# from here https://sites.research.google/gr/open-buildings/#open-buildings-download)

# For the multiple tiles that you have, list the file paths (this should also work if it is one file)
file_paths <- list.files(path = "D:/GIS_files/Arunachal/Google-open-buildings", 
                         pattern = "_buildings\\.csv$", 
                         full.names = TRUE,
                         recursive = TRUE) %>%
  purrr::keep(~!file.info(.x)$isdir) # This step is to ensure that the path to the 
  # csv file is captured instead of the folder with the same name (which is the case
  # with the unzipped google open buildings data)

# Load shapefile and get its bounding box (using Arunachal boundary in this case)
clip_boundary <- st_read("D:/GIS_files/Arunachal/arunachal_shapefile/Arunachal_Pradesh.shp")
# Reading layer `Arunachal_Pradesh' from data source 
#   `D:\GIS_files\Arunachal\arunachal_shapefile\Arunachal_Pradesh.shp' using driver `ESRI Shapefile'
# Simple feature collection with 1 feature and 12 fields
# Geometry type: POLYGON
# Dimension:     XYZ
# Bounding box:  xmin: 91.54646 ymin: 26.65084 xmax: 97.4115 ymax: 29.46173
# z_range:       zmin: 0 zmax: 0
# Geodetic CRS:  WGS 84

# Install one more necessary package and load them (uncomment below to do it)
# install.packages("duckdb")
library(duckdb)
# DuckDB is an embedded SQL database optimized for analytical queries.

# Create a connection to an in-memory DuckDB database:
 con <- dbConnect(duckdb()) # No file is created on disk (in-memory means temporary)
# Install and loads DuckDB's spatial extension
 dbExecute(con, "INSTALL spatial; LOAD spatial;")
# This enables geographic/spatial functions like ST_GeomFromText()
# The extension adds GIS capabilities to DuckDB.

# The following loop converts text geometries to binary geometry objects,
# and processes files individually, creating one .parquet file per input .csv file.
# Note that in the SELECT step, the other fields area_in_meters, confidence,
# and full_plus_code have not been selected to save computational time. You can
# retain them by adding them to right after longitude, seperated by commas
# A loop to process each file
for (f in file_paths) {
  output_name <- gsub("\\.csv$", ".parquet", basename(f))
  dbExecute(con, sprintf("
    COPY (
      SELECT ST_GeomFromText(geometry) AS geom,
             latitude, longitude 
      FROM read_csv_auto('%s')
    ) TO '%s' WITH (FORMAT PARQUET)
  ", f, output_name))
}

# Based on the saving time, it took a few seconds for a 9.16 MB CSV file to be processed,
# ~17 min for a 929 MB file, ~2 hr 56 min for a 3.11 GB file, and less than a minute for a
# 41.5 MB file to be processed.
