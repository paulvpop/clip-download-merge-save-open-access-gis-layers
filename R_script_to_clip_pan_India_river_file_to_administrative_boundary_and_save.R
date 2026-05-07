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



