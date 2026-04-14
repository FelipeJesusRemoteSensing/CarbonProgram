var all_smooth1_geo = ee.Image('projects/guilhermevaz/assets/v6/2024_AllPasture_class_v6_asset_smooth_fmedian_circle_rd2_it1_area1').geometry()
var all_smooth2_geo = ee.Image('projects/guilhermevaz/assets/v6/2024_AllPasture_class_v6_asset_smooth_fmedian_circle_rd2_it1_area2').geometry()

var allpasture1 = ee.Image('projects/guilhermevaz/assets/v6/2024_AllPasture_class_v6_Area1_asset')
  .select('APT')

var allpasture2 = ee.Image('projects/guilhermevaz/assets/v6/2024_AllPasture_class_v6_Area2_asset')
  .select('APT')

var all_smooth1_3x3_median = allpasture1.focalMedian({
  radius:1,
  kernelType:"circle",
  units:"pixels",
  iterations:1,
  //kernel:null,
})

var all_smooth2_3x3_median = allpasture2.focalMedian({
  radius:1,
  kernelType:"circle",
  units:"pixels",
  iterations:1,
  //kernel:null,
})

// Export.image.toAsset({
//     image: all_smooth1_3x3_median,
//     description: '2024_AllPasture_class_v6_asset_smooth_fmedian_circle_rd1_it1_area1',
//     assetId: 'projects/ee-vieiramesquita-mapbiomas/assets/REMAP/Rasters/2024_AllPasture_class_v6_asset_smooth_fmedian_circle_rd1_it1_area1',
//     region: all_smooth1_geo,
//     scale: 10,
//     crs: 'EPSG:4326',
//     maxPixels: 1E13,

// })

// Export.image.toAsset({
//     image: all_smooth2_3x3_median,
//     description: '2024_AllPasture_class_v6_asset_smooth_fmedian_circle_rd1_it1_area2',
//     assetId: 'projects/ee-vieiramesquita-mapbiomas/assets/REMAP/Rasters/2024_AllPasture_class_v6_asset_smooth_fmedian_circle_rd1_it1_area2',
//     region: all_smooth2_geo,
//     scale: 10,
//     crs: 'EPSG:4326',
//     maxPixels: 1E13,

// })

var all_smooth1_3x3 = allpasture1.focalMedian({
  radius:1,
  kernelType:"circle",
  units:"pixels",
  iterations:1,
  //kernel:null,
})

var all_smooth2_3x3 = allpasture2.focalMedian({
  radius:1,
  kernelType:"circle",
  units:"pixels",
  iterations:1,
  //kernel:null,
})

var all_smooth1_3x3_median = ee.Image('projects/ee-vieiramesquita-mapbiomas/assets/REMAP/Rasters/2024_AllPasture_class_v6_asset_smooth_fmedian_circle_rd1_it1_area1')
  .gte(5100)
  .selfMask()
  
var all_smooth2_3x3_median = ee.Image('projects/ee-vieiramesquita-mapbiomas/assets/REMAP/Rasters/2024_AllPasture_class_v6_asset_smooth_fmedian_circle_rd1_it1_area2')
  .gte(5100)
  .selfMask()

var all_smooth1_5x5_median = ee.Image('projects/guilhermevaz/assets/v6/2024_AllPasture_class_v6_asset_smooth_fmedian_circle_rd2_it1_area1')
  .gte(5100)
  .selfMask()

var all_smooth2_5x5_median = ee.Image('projects/guilhermevaz/assets/v6/2024_AllPasture_class_v6_asset_smooth_fmedian_circle_rd2_it1_area2')
  .gte(5100)
  .selfMask()

var all_area1_FMode_1x1_in_NF = allpasture1.gte(5100).selfMask().unmask().focalMode({
  radius:1,
  kernelType:"square",
  units:"pixels",
  iterations:1,
  //kernel:null,
})

var all_area1_FMode_1x1_in_5x5 = all_smooth1_5x5_median.unmask().focalMode({
  radius:1,
  kernelType:"square",
  units:"pixels",
  iterations:1,
  //kernel:null,
})

var all_area2_FMode_1x1_in_NF = allpasture2.gte(5100).selfMask().unmask().focalMode({
  radius:1,
  kernelType:"square",
  units:"pixels",
  iterations:1,
  //kernel:null,
})

var all_area2_FMode_1x1_in_5x5 = all_smooth2_5x5_median.unmask().focalMode({
  radius:1,
  kernelType:"square",
  units:"pixels",
  iterations:1,
  //kernel:null,
})


Export.image.toAsset({
    image: all_area1_FMode_1x1_in_NF,
    description: '2024_AllPasture_class_v6_asset_fMode1_area1',
    assetId: 'projects/ee-vieiramesquita-mapbiomas/assets/REMAP/Rasters/2024_AllPasture_class_v6_asset_fMode1_area1',
    region: all_smooth1_geo,
    scale: 10,
    crs: 'EPSG:4326',
    maxPixels: 1E13,
})

Export.image.toAsset({
    image: all_area1_FMode_1x1_in_5x5,
    description: '2024_AllPasture_class_v6_asset_smooth_fmedian_circle_rd2_it1_fMode1_area1',
    assetId: 'projects/ee-vieiramesquita-mapbiomas/assets/REMAP/Rasters/2024_AllPasture_class_v6_asset_smooth_fmedian_circle_rd1_it2_fMode1_area1',
    region: all_smooth1_geo,
    scale: 10,
    crs: 'EPSG:4326',
    maxPixels: 1E13,
})

Export.image.toAsset({
    image: all_area2_FMode_1x1_in_NF,
    description: '2024_AllPasture_class_v6_asset_fMode1_area2',
    assetId: 'projects/ee-vieiramesquita-mapbiomas/assets/REMAP/Rasters/2024_AllPasture_class_v6_asset_fMode1_area2',
    region: all_smooth1_geo,
    scale: 10,
    crs: 'EPSG:4326',
    maxPixels: 1E13,
})

Export.image.toAsset({
    image: all_area2_FMode_1x1_in_5x5,
    description: '2024_AllPasture_class_v6_asset_smooth_fmedian_circle_rd2_it1_fMode1_area2',
    assetId: 'projects/ee-vieiramesquita-mapbiomas/assets/REMAP/Rasters/2024_AllPasture_class_v6_asset_smooth_fmedian_circle_rd1_it2_fMode1_area2',
    region: all_smooth1_geo,
    scale: 10,
    crs: 'EPSG:4326',
    maxPixels: 1E13,
})