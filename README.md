This repository will help a user to clip-and-download (using google Earth Engine) or download-and-(merge)-clip (using R and/or QGIS) large open access rasters and vectors. Specifically, in this case, data from [Core Stack](https://ee-corestackdev.projects.earthengine.app/view/core-stack-gee-app) and [google Open Buildings](https://sites.research.google/gr/open-buildings/) will be used. This makes the downloads smaller or the data smaller after download, so that unnecessary download and/or storage can be avoided. This will also help in loading the layers in QGIS without it crashing or hanging. Once loaded in QGIS, they can further be merged, clipped to desired area, and then saved.

Many GIS layers are publicly available from [CoRE Stack](https://ee-corestackdev.projects.earthengine.app/view/core-stack-gee-app). 
The download links are available from the [CoRE Stack GEE Layers Links sheet](https://docs.google.com/spreadsheets/d/1xS5d7vgyjyoqqnmmajKDZBx9qS6GqyAdSbNDR62ot2Y/edit?gid=0#gid=0).
The drainage layer available for the entirety of India in the geojson format is 12.37 GB in size. Such large files requires large amount of data to download as well 
as space to retain. It's best to open it in Google Earth Engine, clip it to the area of interest, and then download the lower sized files.

>Requirements:<br>
>QGIS v.3.x installed<br>
>R v.4.x.x installed<br>
>RStudio installed

This workflow has been authored by Paul Pop.

This work was carried out under the BIRD lab, ATREE, Bengaluru (PI: Rajkamal Goswami).


