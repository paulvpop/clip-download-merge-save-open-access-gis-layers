Many GIS layers are publicly available from [CoRE Stack](https://ee-corestackdev.projects.earthengine.app/view/core-stack-gee-app). 
The download links are available from the [CoRE Stack GEE Layers Links sheet](https://docs.google.com/spreadsheets/d/1xS5d7vgyjyoqqnmmajKDZBx9qS6GqyAdSbNDR62ot2Y/edit?gid=0#gid=0).
The drainage layer available for the entirety of India in the geojson format is 12.37 GB in size. Such large files requires large amount of data to download as well 
as space to retain. It's best to open it in Google Earth Engine, clip it to the area of interest, and then download the lower sized files.

The following is a script to download the drainage layer clipped to certain districts of India, with the use of an Indian districts shapefile. District boundaries (and other types of 
administrative boundaries are also available via CoRE Stack. You would just need to convert the geojson to shapefile format (which can be done in QGIS) and then upload as an asset 
in Google Earth Engine. Make sure to create a zip of .shp, .dbf, .shx, and .prj files (nothing more, nothing less) of the this administrative layer before uploading to GEE (it won't
work otherwise).

```
// Load drainage lines
var drainage_lines = ee.FeatureCollection("projects/corestack-datasets/assets/datasets/drainage-line/pan_india_drainage_lines");

// Load the region of interest
var roi = ee.FeatureCollection("projects/ee-paulpop/assets/ap_districts");

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
var districtsList = ['SIANG', 'UPPER SIANG', 'EAST SIANG'];
for (var i = 0; i < districtsList.length; i++) {
  var name = districtsList[i];
  var collection = prepareDistrictExport(name);
  var count = collection.size().getInfo();
  
  if (count > 0) {
    var safeName = name.replace(/[^a-zA-Z0-9]/g, '_');
    Export.table.toDrive({
      collection: collection,
      description: 'Drainage_' + safeName,
      folder: 'Paul-GEE-downloads/Districts',
      fileNamePrefix: 'drainage_' + safeName,
      fileFormat: 'SHP'
    });
    print('Export created for: ' + name + ' (' + count + ' features)');
  }
}

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
