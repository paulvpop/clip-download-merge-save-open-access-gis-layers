This tutorial will help a user to clip-and-download (using google Earth Engine) or download-and-(merge)-clip (using R and/or QGIS) large open access rasters. Specifically, in this case, data from [Core Stack](https://ee-corestackdev.projects.earthengine.app/view/core-stack-gee-app) and [google Open Buildings](https://sites.research.google/gr/open-buildings/) will be used. This makes the downloads smaller or the data smaller after download, so that unnecessary download and/or storage can be avoided. This will also help in loading the layers in QGIS without it crashing or hanging. Once loaded in QGIS, they can further be merged, clipped to desired area, and then saved. <br>

Many GIS layers are publicly available from [CoRE Stack](https://ee-corestackdev.projects.earthengine.app/view/core-stack-gee-app). 
The download links are available from the [CoRE Stack GEE Layers Links sheet](https://docs.google.com/spreadsheets/d/1xS5d7vgyjyoqqnmmajKDZBx9qS6GqyAdSbNDR62ot2Y/edit?gid=0#gid=0).
The drainage layer available for the entirety of India in the geojson format is 12.37 GB in size. Such large files requires large amount of data to download as well 
as space to retain. It's best to open it in Google Earth Engine, clip it to the area of interest, and then download the lower sized files.

>Requirements:<br>
>QGIS v.3.x installed<br>
>R v.4.x.x installed<br>
>RStudio installed

This workflow has been authored by Paul Pop.

This work was carried out under the BIRD lab, ATREE, Bengaluru (PI: Rajkamal Goswami). <br>

*Version 1.0 - last updated 2026-05-15 <br>
Last update - File size comparison* <br>

View the most current version at https://github.com/paulvpop/clip-download-merge-save-open-access-gis-layers/blob/main/tutorial.md


## Drainage lines in India

The following is a script to download the drainage layer clipped to certain districts of India, with the use of an Indian districts shapefile. District boundaries (and other types of 
administrative boundaries are also available via CoRE Stack). You would just need to convert the geojson to shapefile format (which can be done in QGIS) and then upload as an asset 
in Google Earth Engine. Make sure to create a zip of .shp, .dbf, .shx, and .prj files (nothing more, nothing less) of the this administrative layer before uploading to GEE (it won't
work otherwise).

You can find this as a standalone script to download [here](https://github.com/paulvpop/clip-download-merge-save-open-access-gis-layers/blob/main/GEE_script_clip_to_districts_drainage_lines_in_India_and_download.js).

```
// Load drainage lines
var drainage_lines = ee.FeatureCollection("projects/corestack-datasets/assets/datasets/drainage-line/pan_india_drainage_lines");

// Load the region of interest
var roi = ee.FeatureCollection("projects/ee-birdlab/assets/ap_districts");

// Define drainage color palette. Note that this palette is from the sample code given by CoRE Stack.
var drainagePalette = ee.Dictionary({
  1: '#f7fbff',
  2: '#e4eff9',
  3: '#d1e2f3',
  4: '#bad6eb',
  5: '#9ac8e0',
  6: '#73b2d8',
  7: '#529dcc',
  8: '#3585bf',
  9: '#1d6cb1',
  10: '#08519c',
  11: '#08306b'
});

function prepareDistrictExport(districtName) {
  var district = roi.filter(ee.Filter.eq('District', districtName));
  var districtGeom = district.geometry().simplify(100);  // You can remove the simplify function if you don't want any
  // alteration of the data, but keep it or increase the number to reduce calculation time and the number of requests to the servers
  // of Earth Engine. The function reduces the geometric complexity of the district boundaries by removing vertices while 
  //preserving the overall shape. The 100 is tolerance in meters. So, it removes vertices that are within 100 meters of a
  //straight line between other vertices.
  var districtDrainage = drainage_lines.filterBounds(districtGeom);
  
  // Convert to EE String at function level
  var eeDistrictName = ee.String(districtName);
  
  return districtDrainage.map(function(feature) {
    return feature.set('district', eeDistrictName);
  });
}

// Use the function
// First replace the names given below with the districts you want
var districtsList = ['SIANG', 'UPPER SIANG', 'EAST SIANG'];
districtsList.forEach(function(name) {
  var safeName = name.replace(/[^a-zA-Z0-9]/g, '_');
  var baseName = 'Drainage_' + safeName;
  
  Export.table.toDrive({
    collection: prepareDistrictExport(name),
    description: baseName,
    folder: 'GEE-downloads/Districts',
    fileNamePrefix: baseName.toLowerCase(),
    fileFormat: 'SHP'
  });
  print('Export created for: ' + name);
});

// Add districts to map
var siangDistrict = roi.filter(ee.Filter.eq('District', 'SIANG'));  /// Change the name of district you want to view
Map.addLayer(siangDistrict, {color: 'blue', fillColor: '#0000ff22'}, 'SIANG District') /// Change the display name of district you want to view

// Add sample drainage lines
var sampleDrainage = drainage_lines
  .filterBounds(siangDistrict.geometry())
  .limit(5000)
  .map(function(f) {
    var order = ee.Number(f.get('ORDER'));
    var color = drainagePalette.get(order, '#000000');
    return f.set('style', {color: color, width: 1});
  });

Map.addLayer(sampleDrainage.style({styleProperty: 'style'}), {}, 'Sample Drainage');
Map.centerObject(siangDistrict, 9);

print('=========================================');
print('✓ Tasks created successfully!');
print('Check the Tasks tab to run the exports');
print('=========================================');
```

## Rivers in India

The Rivers geojson from CoRE Stack is 592 MB. It would best to clip the rivers occuring to the area of interest (Arunachal Pradesh in my case). The following R script will help in doing that.

You can find this as a standalone script to download [here](https://github.com/paulvpop/clip-download-merge-save-open-access-gis-layers/blob/main/R_script_to_clip_pan_India_river_file_to_administrative_boundary_and_save.R).

```
# Set the working directory (Ctrl+Shift+H or the following line of code (change the file path to yours)):
setwd("D:/GIS_files/Arunachal")

# The package geojsonsf is faster than sf since it uses rapidjson 
# https://stackoverflow.com/questions/52899355/using-st-read-to-import-large-geojson-in-iterations-r
# Uncomment and install the geojsonsf package if not already installed
#install.packages("geojsonsf")
# Load the libraries
library(geojsonsf)
library(sf)
library(dplyr)

# Assuming that the file is located within the folder 'Drainage-maps'
rivers <- geojsonsf::geojson_sf("./Drainage-maps/River_pan_india.geojson")
# Still takes a bit of time to load (many minutes or maybe half an hour or more)

OR

you can use the st_read function from the sf package
rivers <- st_read("./Drainage-maps/River_pan_india.geojson")
# Reading layer `River_pan_india' from data source 
#   `D:\GIS_files\Arunachal\Drainage-maps\River_pan_india.geojson' using driver `GeoJSON'
# Simple feature collection with 40900 features and 9 fields (with 2 geometries empty)
# Geometry type: GEOMETRY
# Dimension:     XY
# Bounding box:  xmin: 68.5435 ymin: 8.087026 xmax: 97.03884 ymax: 36.44868
# Geodetic CRS:  WGS 84

# Check the different geometries present in the file.
print(st_geometry_type(rivers) %>% table())
# .
# GEOMETRY              POINT         LINESTRING            POLYGON         MULTIPOINT 
# 0                  1                 65              40391                  2 
# MULTILINESTRING       MULTIPOLYGON GEOMETRYCOLLECTION     CIRCULARSTRING      COMPOUNDCURVE 
# 0                170                271                  0                  0 
# CURVEPOLYGON         MULTICURVE       MULTISURFACE              CURVE            SURFACE 
# 0                  0                  0                  0                  0 
# POLYHEDRALSURFACE                TIN           TRIANGLE 
# 0                  0                  0 

# Get the geometry type counts
geom_counts <- table(st_geometry_type(rivers))
print("Original geometry types and counts:")
print(geom_counts)

# Initialize empty list to collect geometries
geom_list <- list()

# Process LINESTRING
if (geom_counts["LINESTRING"] > 0 && !is.na(geom_counts["LINESTRING"])) {
  rivers_linestring <- rivers[st_geometry_type(rivers) == "LINESTRING", ]
  geom_list[["LINESTRING"]] <- rivers_linestring
  print(paste("Added LINESTRING:", nrow(rivers_linestring), "features"))
}
# [1] "Added LINESTRING: 65 features"

# Process MULTILINESTRING (0 features - skipped automatically)
if (geom_counts["MULTILINESTRING"] > 0 && !is.na(geom_counts["MULTILINESTRING"])) {
  rivers_multiline <- rivers[st_geometry_type(rivers) == "MULTILINESTRING", ]
  # Cast MULTILINESTRING to LINESTRING
  rivers_multiline_cast <- st_cast(rivers_multiline, "LINESTRING")
  geom_list[["MULTILINESTRING_cast"]] <- rivers_multiline_cast
  print(paste("Cast MULTILINESTRING to LINESTRING:", nrow(rivers_multiline_cast), "features"))
}

# Process POLYGON
if (geom_counts["POLYGON"] > 0 && !is.na(geom_counts["POLYGON"])) {
  rivers_polygon <- rivers[st_geometry_type(rivers) == "POLYGON", ]
  geom_list[["POLYGON"]] <- rivers_polygon
  print(paste("Added POLYGON:", nrow(rivers_polygon), "features"))
}
# [1] "Added POLYGON: 40391 features"

# Process MULTIPOLYGON
if (geom_counts["MULTIPOLYGON"] > 0 && !is.na(geom_counts["MULTIPOLYGON"])) {
  rivers_multipolygon <- rivers[st_geometry_type(rivers) == "MULTIPOLYGON", ]
  # Cast MULTIPOLYGON to POLYGON
  rivers_multipolygon_cast <- st_cast(rivers_multipolygon, "POLYGON")
  geom_list[["MULTIPOLYGON_cast"]] <- rivers_multipolygon_cast
  print(paste("Cast MULTIPOLYGON to POLYGON:", nrow(rivers_multipolygon_cast), "features"))
}
# [1] "Cast MULTIPOLYGON to POLYGON: 617 features"
# Warning message:
#   In st_cast.sf(rivers_multipolygon, "POLYGON") :
#   repeating attributes for all sub-geometries for which they may not be constant

# Process GEOMETRYCOLLECTION
if (geom_counts["GEOMETRYCOLLECTION"] > 0 && !is.na(geom_counts["GEOMETRYCOLLECTION"])) {
  rivers_collection <- rivers[st_geometry_type(rivers) == "GEOMETRYCOLLECTION", ]
  
  # Method 1: Extract each geometry type separately
  lines_from_collection <- st_collection_extract(rivers_collection, "LINESTRING")
  polygons_from_collection <- st_collection_extract(rivers_collection, "POLYGON")
  points_from_collection <- st_collection_extract(rivers_collection, "POINT")
  
  # Add to geom_list if they have features
  if (nrow(lines_from_collection) > 0) {
    geom_list[["lines_from_collection"]] <- lines_from_collection
    print(paste("Extracted LINESTRING from GEOMETRYCOLLECTION:", nrow(lines_from_collection), "features"))
  }
  
  if (nrow(polygons_from_collection) > 0) {
    geom_list[["polygons_from_collection"]] <- polygons_from_collection
    print(paste("Extracted POLYGON from GEOMETRYCOLLECTION:", nrow(polygons_from_collection), "features"))
  }
  
  if (nrow(points_from_collection) > 0) {
    geom_list[["points_from_collection"]] <- points_from_collection
    print(paste("Extracted POINT from GEOMETRYCOLLECTION:", nrow(points_from_collection), "features"))
  }
}
# [1] "Extracted LINESTRING from GEOMETRYCOLLECTION: 349 features"
# [1] "Extracted POLYGON from GEOMETRYCOLLECTION: 941 features"
# [1] "Extracted POINT from GEOMETRYCOLLECTION: 1 features"

# Process POINT
if (geom_counts["POINT"] > 0 && !is.na(geom_counts["POINT"])) {
  rivers_point <- rivers[st_geometry_type(rivers) == "POINT", ]
  geom_list[["POINT"]] <- rivers_point
  print(paste("Added POINT:", nrow(rivers_point), "features"))
}
# [1] "Added POINT: 1 features"

# Process MULTIPOINT (2 features)
if (geom_counts["MULTIPOINT"] > 0 && !is.na(geom_counts["MULTIPOINT"])) {
  rivers_multipoint <- rivers[st_geometry_type(rivers) == "MULTIPOINT", ]
  # Cast MULTIPOINT to POINT
  rivers_multipoint_cast <- st_cast(rivers_multipoint, "POINT")
  geom_list[["MULTIPOINT_cast"]] <- rivers_multipoint_cast
  print(paste("Cast MULTIPOINT to POINT:", nrow(rivers_multipoint_cast), "features"))
}
# [1] "Cast MULTIPOINT to POINT: 2 features"

# Combine all processed geometries
# For shapefile (can only have one geometry type per file)
# Save separate files for each geometry type

# Save individual shapefiles (best would be to not do this and instead
# save all geometries as one geopackage - shown after this)
output_dir <- "./Drainage-maps/separated_geometries"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# Save each geometry type as separate shapefile
for (name in names(geom_list)) {
  data <- geom_list[[name]]
  
  # Determine geometry type for filename
  if (grepl("LINESTRING", name)) {
    filename <- "rivers_linestring"
  } else if (grepl("POLYGON", name)) {
    filename <- "waterbodies_polygon"
  } else if (grepl("POINT", name)) {
    filename <- "points"
  } else {
    filename <- paste0("rivers_", tolower(gsub("_cast|_exploded", "", name)))
  }
  
  # Save as shapefile
  st_write(data, file.path(output_dir, paste0(filename, ".shp")), delete_layer = TRUE)
  print(paste("Saved:", filename, "-", nrow(data), "features"))
}

# Save ALL geometries combined as GeoPackage (supports multiple geometry types)
all_geometries <- do.call(rbind, geom_list)
st_write(all_geometries, "./Drainage-maps/all_rivers_combined.gpkg", delete_layer = TRUE)
print(paste("Saved combined GeoPackage with:", nrow(all_geometries), "total features"))

# Load in the Arunachal Pradesh district shapefile:
ap_dist <- st_read("./Maps/AP_dsitricts.shp")  

# Instead of intersection to get the rivers within Arunachal, use filter (much faster)
all_geometries_in_arunachal <- all_geometries[ap_dist, ]  # Spatial filtering
# This takes a few minutes

# This keeps original geometries (doesn't clip at district boundaries)
# But only includes features that intersect Arunachal

# Then clip only if necessary (union districts first for faster clipping)
clipped_all_geometries <- st_intersection(all_geometries_in_arunachal, st_union(ap_dist))
# Warning message:
#   attribute variables are assumed to be spatially constant throughout all geometries 

print(paste("Original features:", nrow(all_geometries)))
print(paste("Features in Arunachal:", nrow(all_geometries_in_arunachal)))
print(paste("Clipped features:", nrow(clipped_all_geometries)))

# Save the clipped file
st_write(clipped_all_geometries, "./Drainage-maps/rivers_arunachal.gpkg",
         delete_layer = TRUE)
```

## Buildings

For this tutorial, we will use the data from Google Open Buildings. You can view it at [Indian Open Maps viewer](https://indianopenmaps.com/viewer#source=/google-buildings/&map=7.71/28.345/94.558&terrain=false&base=Google+Hybrid). 

I will show three different methods to carry out merging and clipping - one using only R (moderately to most efficient for large files), another one only using QGIS (the least efficient for large files), and the last using R and QGIS (moderately to most efficient for large files).

### Method A - only using R

The following is an R script to load, clip to study area, merge and save Google Open Buildings data in Parquet form.

You can find this as a standalone script to download [here](https://github.com/paulvpop/clip-download-merge-save-open-access-gis-layers/blob/main/R_script_to_merge_clip_and_save_google_open_buildings_data.R).

```
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

# Load shapefile into DuckDB
clip_boundary_wkt <- st_as_text(st_union(clip_boundary))

# Prepare all the files for processing
all_files <- paste(shQuote(file_paths), collapse = ", ")

# Create a connection to an in-memory DuckDB database:
 con <- dbConnect(duckdb()) # No file is created on disk (in-memory means temporary)
# Install and loads DuckDB's spatial extension
 dbExecute(con, "INSTALL spatial; LOAD spatial;")
# This enables geographic/spatial functions like ST_GeomFromText()
# The extension adds GIS capabilities to DuckDB.

# The following dbExecute()command executes a SQL query within DuckDB that reads multiple CSV files,
# filters buildings within a boundary, and saves the results as a Parquet file.
# Note that in SELECT step, the other fields area_in_meters, confidence, and full_plus_code have not 
# been selected to save computationaltime. You can retain them by adding them to right after longitude, 
# seperated by commas.
dbExecute(con, sprintf("
  COPY (
    SELECT ST_GeomFromText(geometry) AS geom,
           latitude, longitude             
    FROM read_csv_auto([%s])
    WHERE ST_Within(ST_GeomFromText(geometry), ST_GeomFromText('%s'))
  ) TO 'all_buildings_clipped.parquet' WITH (FORMAT PARQUET)
", all_files, clip_boundary_wkt))

# This took around ~3.5 hours with just the geometry, latitude and longitude data for the whole of
# Arunachal Pradesh (which don't have a lot of buildings compared to a lot of other states in India).
```

### Method B - only using QGIS

**Step 1:** Download all the tiles that cover your area of interest from [here](https://sites.research.google/gr/open-buildings/#open-buildings-download ). These are quite large tiles. So, we need to clip them.

**Step 2:** Unzip the files which will have a file name like *375_buildings.csv.gz*. The file size can be very large for some area (like 9 GB) or a very small (a few MB). The folder will contain a csv file.

**Step 3:** Open QGIS.

**Step 4:** Since the file sizes can be very large which can slow down or hang QGIS when multiple files are loaded at once, we will have to convert it to a more efficient and space-saving format i.e. (Geo)parquet. Open of the file by going selecting

```
Layer > Add Layer > Add Delimited Text Layer
```
<img width="743" height="640" alt="image" src="https://github.com/user-attachments/assets/bf133ff3-62ed-4ecd-a4ae-8c995e2785ab" /> <br>

**Step 5:** Click on ... on the right of 'File name' and select on the file.

<img width="996" height="650" alt="image" src="https://github.com/user-attachments/assets/427775bb-fc99-4478-b8a2-e87d77a8d27e" /> <br>

**Step 6:** Change the 'Geometry definition' to 'Well Known Text', and then press 'Add'.

<img width="999" height="660" alt="image" src="https://github.com/user-attachments/assets/4c69839b-867f-4e10-a469-f5bc5fb7fd34" /> <br>

**Step 7:** Right Click on the loaded file > `Export > Save Feature As...`

<img width="585" height="434" alt="image" src="https://github.com/user-attachments/assets/23488cf6-7cc3-4256-ae70-6a9867347134" /> <br>

**Step 8:** Select '(Geo)Parquet from the drop-down list under 'Format'.

<img width="580" height="663" alt="image" src="https://github.com/user-attachments/assets/9901d3e9-e596-4c15-b1e6-3806cf519996" /> <br>

**Step 9:** Give it a name (ideally the same name to keep track) and press 'OK'. Note that a .qmd file will also be saved along with the .parquet file to save metadata.

<img width="589" height="662" alt="image" src="https://github.com/user-attachments/assets/16b2aefa-248b-42cc-b37a-320609963f62" /> <br>

**Step 10:** Since 'Add saved file to map' was turned on in the last step, the GeoParquet files will already be in the QGIS environment. Remove the corresponding CSV file from QGIS to clear valuable memory.

**Step 11:** Repeat steps 2 to 10 for all the csv files containing the buildings in your area of interest.

**Step 12:** In your 'Processing Toolbox', search and select the 'Merge vector layers'.

<img width="1035" height="833" alt="image" src="https://github.com/user-attachments/assets/b87bc06d-9aab-4704-8a25-c54ce2c0ae59" /> <br>

**Step 13:** Under 'Input layers', select all the buildings layers.

<img width="1017" height="165" alt="image" src="https://github.com/user-attachments/assets/0db4e473-ad8a-4630-b7b9-192000e076fc" /> <br>

**Step 14:** Press 'Run'. Merging will take a few minutes (for the size of a large state like Arunachal Pradesh in India) and you can see the progress on the bottom panel. This will produce a 'Merged' file.

<img width="293" height="45" alt="image" src="https://github.com/user-attachments/assets/95d59428-cf38-4bec-9864-cd03650083db" /> <br>

**Step 15:** In your 'Processing Toolbox', search and select the 'Clip' under 'Vector Overlay.

<img width="287" height="392" alt="image" src="https://github.com/user-attachments/assets/1651d5ba-f504-4fc3-a082-4193ca40644a" /> <br>

**Step 16:** Keep the 'Input layer' as 'Merged' and 'Overlay layer' as your area of interest.

<img width="1369" height="756" alt="image" src="https://github.com/user-attachments/assets/9c164ee7-2ef5-4646-bff3-7d7149015895" /> <br>

**Step 17:** Under 'Clipped', click on the  `...` and give a file name for the output to save it permanently.

**Step 18:** Click on 'Run' to produce the desired final clipped output. For the large state of Arunachal Pradesh, this took 5 minutes 27 seconds.

### Method C - Using R and QGIS

The following is an R script to load, and save Google Open Buildings data in Parquet format - individual files will be saved for each corresponding csv. 

This can be found as a standalone script to download [here](https://github.com/paulvpop/clip-download-merge-save-open-access-gis-layers/blob/main/R_script_to_convert_CSV_files_to_Parquet.R).

```
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
```

After running the above script, the outputs would be non-clipped Parquet versions of the original CSVs. These files will be nearly 0.25 to 0.45 times that of the original size, making it easier to load into QGIS without hanging or crashing it.

Load all these individual Parquet files into QGIS and then follow the Steps 12 to 18 in Method B to get the final clipped file.

### File size comparison

Individual file sizes:

| Tile name     | CSV     | Parquet (all columns) | Parquet (selected columns) |
|---------------|---------|-----------------------|----------------------------|
| 371_buildings | 9.6 MB  | 4.26 MB               | 3.33 MB                    |
| 373_buildings | 929 MB  | 302 MB                | 229 MB                     |
| 375_buildings | 8.90 GB | 4.07 GB               | 3.11 GB                    |
| 377_buildings | 41.5 MB | 17.8 MB               | 13.9 MB                    |
| Total         | 9.86 GB | 4.39 GB               | 3.35 GB                    |

This table shows that the original file format (CSV) is bulky and we can reduce the file size by nearly half or one-third by converting it into the Parquet format, the former if keeping all the columns and the latter if selecting the bare necessities (geometry, latitude and longitude).

The final file size of a Parquet file that has only three selected columns containing building polygons for the entirety of Arunachal Pradesh is 81.5 MB. If keep all the columns, it is 106 MB. If saving as a GeoPackage, then it becomes 590 Mb. And shapefile is quite bulky at 1.45 GB (but 105 MB when compressed/zipped).
















