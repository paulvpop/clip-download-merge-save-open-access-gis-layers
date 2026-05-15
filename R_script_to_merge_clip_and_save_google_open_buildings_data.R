# The following is an R script to load, clip to study area, and save Google Open Buildings data

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

# Install some more necessary packages and load them (uncomment below to do it)
# install.packages(c("arrow","duckdb"))
library(arrow)
library(duckdb)

# Load shapefile into DuckDB
clip_boundary_wkt <- st_as_text(st_union(clip_boundary))

# Prepare all the files for processing
all_files <- paste(shQuote(file_paths), collapse = ", ")

# Read CSV with arrow and convert WKT to geometry in Parquet
 con <- dbConnect(duckdb())
 dbExecute(con, "INSTALL spatial; LOAD spatial;")

# The following dbExecute()command executes a SQL query within DuckDB that reads multiple CSV files,
# filters buildings within a boundary, and saves the results as a Parquet file.
dbExecute(con, sprintf("
  COPY (
    SELECT ST_GeomFromText(geometry) AS geom,
           latitude, longitude             # Note that in this step, the other fields area_in_meters, confidence,
     # and full_plus_code have not been selected to save computational
     # time. You can retain them by adding them to right after longitude, seperated by commas
    FROM read_csv_auto([%s])
    WHERE ST_Within(ST_GeomFromText(geometry), ST_GeomFromText('%s'))
  ) TO 'all_buildings_clipped.parquet' WITH (FORMAT PARQUET)
", all_files, clip_boundary_wkt))

# This took around ~3.5 hours with just the geometry, latitude and longitude data for the whole of
# Arunachal Pradesh (which don't have a lot of buildings compared to a lot of other states in India).
