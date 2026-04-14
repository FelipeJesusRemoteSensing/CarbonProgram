//=======================================================================================================================================
//Version name: 
var version = "v7"
//=======================================================================================================================================
//Class variables
var rfNTrees = 500; //#Number of random trees - lesser faster, but worst. 100-500 is the optimal;
var rfBagFraction = 0.5; //#Fraction (10^-2%) of variables in the bag - 0.5/50% is the default;
var rfVarPersplit = 13 //#Number of varibales per tree branch - estimated by the square root of the number of variables used in the feature space;
//=======================================================================================================================================
//Dictionary containing spectral indexes and their formulas
var indexes = {
    'CAI': "(b('B12') / b('B11'))", //Cellulose absorption index
    'NDVI': "(b('B8') - b('B4')) / (b('B8') + b('B4'))", //Normalized Difference Vegetation Index
    'NDWI': "(b('B8') - b('B11')) / (b('B8') + b('B11'))", //Normalized Difference Water/Wetness Index
    'CRI1': "1/(b('B2')) - 1/(b('B3'))", //Carotenoid Reflectance Index 1
    'ARI_1': "(1/b('B3') - 1/b('B5'))*1000", //Anthocyanin Reflectance Index 1
    'RGR': "b('B4')/b('B3')", //Simple Ratio Red/Green Red-Green Ratio
    'PSRI': "(b('B4') - b('B2') )/(b('B6'))", //Plant Senescence Reflectance Index
    'SATVI': "((b('B11') - b('B4'))/(b('B11') + b('B4') + 0.5))*(1*0.5)-(b('B12')/2)*0.0001" //Soil-Adjusted Total Vegetation Index
}
//=======================================================================================================================================
//Function made to estimate spectral indexes for each image in the Image Collection
function spectralFeatures(image) {

    var ndvi = image.expression(indexes["NDVI"]).select([0], ['NDVI']) //Calculates the NDVI
    var ndwi = image.expression(indexes["NDWI"]).select([0], ['NDWI']) //Calculates the NDWI
    var cai = image.expression(indexes["CAI"]).select([0], ['CAI']) //Calculate thes CAI
    var cri1 = image.expression(indexes["CRI1"]).select([0], ['CRI1']) //Calculates the CRI1
    var ari1 = image.expression(indexes["ARI_1"]).select([0], ['ARI_1']) //Calculates the ARI_1
    var rgr = image.expression(indexes["RGR"]).select([0], ['RGR']) //Calculates the RGR
    var psri = image.expression(indexes["PSRI"]).select([0], ['PSRI']) //Calculates the PSRI
    var satvi = image.expression(indexes["SATVI"]).select([0], ['SATVI']) //Calculates the SATVI

    image = image.addBands([ndvi, ndwi, cai, cri1, ari1, rgr, psri, satvi]) //Adds the spectral indexes to the image with the spectral bands

    return image
}
//=======================================================================================================================================
//Function made to reduce all images/band in the collection to their specific reductor, e.g. median.
function temporalFeatures(image) {
    // OTIMIZAÇÃO: O redutor foi combinado para rodar todas as estatísticas de uma só vez.
    // Isso é muito mais eficiente do que chamar .reduce() para cada estatística separadamente.
    var reducers = ee.Reducer.min()
                     .combine({reducer2: ee.Reducer.max(), sharedInputs: true})
                     .combine({reducer2: ee.Reducer.median(), sharedInputs: true})
                     .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true});

    // OTIMIZAÇÃO: Aplica o redutor combinado uma única vez na coleção de imagens.
    var reducedImage = image.reduce(reducers);

    // OTIMIZAÇÃO: Calcula a amplitude a partir do resultado do redutor combinado, sem reprocessar.
    var amp = reducedImage.select('.*_max') //Reduces all bands to the amplitude (max - min) of their values per pixel
        .subtract(reducedImage.select('.*_min'))
        .rename(BandsWetAmp);

    var result = reducedImage.addBands(amp); //Creates an empty image and add the reduced bands to it
    return result;
}
//=======================================================================================================================================
//Function made to reduce all images/band in the collection to their percentiles, e.g. 10%, 25%, 75% and 90%.
function temporalPercs(image) {

    var percs = image.reduce(ee.Reducer.percentile([10, 25, 75, 90]))

    var result = ee.Image().select().addBands([percs])

    return result
}
//=======================================================================================================================================
//Function made to generate the latitude and the longitude of each pixel
function getLatLong(img) {
    //# Gets the projection
    var proj = ee.Image(img).select(0).projection() //Gets the reference projection from one image
    var latlon = ee.Image.pixelLonLat() //Estimates the latitude and longitude for each pixel
    return ee.Image(img).addBands(latlon.select('longitude', 'latitude')) //Adds the latitude and the longitude as a band
}
//=======================================================================================================================================
//Function made to mask cloud and shadows in the images, based on the quality band from Google Cloud Score (cs)
function maskClouds(img) {
    // The threshold for masking; values between 0.50 and 0.65 generally work well.
    // Higher values will remove thin clouds, haze & cirrus shadows.
    var CLEAR_THRESHOLD = 0.50;
    var mask = img.select('cs').gte(CLEAR_THRESHOLD); //Masks the pixels with 50% of chance or more to be clouds.
    return img.updateMask(mask);
}
//=======================================================================================================================================
//Function made to convert deegre image to percent
function radians(img) {
    return img.toFloat().multiply(Math.PI).divide(180)
}

function res_bilinear(img) {

    //#Resamples the 20 meters bands to 10m using bilinear resampling method
    var bands = img.select('B5', 'B6', 'B7', 'B8A', 'B11', 'B12'); //Bands to be resampled from 20 to 10 meters

    return img.resample('bilinear').reproject({
        'crs': bands.projection().crs(), //Gets the projection
        'scale': img.select('B8').projection().nominalScale() //Gets the pixel size
    })
}
//=======================================================================================================================================
//Function made to mask some weird black edges which can appear in some Sentinel 2 images
function maskEdges(s2_img) {
    return s2_img.updateMask(
        s2_img.select('B8A').mask().updateMask(s2_img.select('B9').mask())) //Defined
}

var terrain = ee.Algorithms.Terrain(ee.Image("NASA/NASADEM_HGT/001")); //Terrain variables (i.e. elevation, slope, aspect) extraction from the NASADEM 
var elevation = terrain.select('elevation'); //Selection of the elevation band
var slope = (radians(terrain.select('slope'))).expression('b("slope")*100'); //Selection of the slope band and conversion from deegre to percentage

//List of names to rename the bands
var BandsWet = ['blue_wet', 'green_wet', 'red_wet', 'rededge1_wet', 'rededge2_wet', 'rededge3_wet',
    'nir_wet', 'rededge4_wet', 'swir1_wet', 'swir2_wet', 'ndvi_wet', 'ndwi_wet', 'cai_wet',
    'cri1_wet', 'ari1_wet', 'rgr_wet', 'psri_wet', 'satvi_wet'
];

//List of names to rename amplitude bands
var BandsWetAmp = ['blue_wet_amp', 'green_wet_amp', 'red_wet_amp', 'rededge1_wet_amp',
    'rededge2_wet_amp', 'rededge3_wet_amp', 'nir_wet_amp', 'rededge4_wet_amp', 'swir1_wet_amp', 'swir2_wet_amp',
    'ndvi_wet_amp', 'ndwi_wet_amp', 'cai_wet_amp', 'cri1_wet_amp', 'ari1_wet_amp', 'rgr_wet_amp',
    'psri_wet_amp', 'satvi_wet_amp'
];


var rasterarea = ee.Image('projects/ee-felipejesus/assets/reMAP_Santa_Catarina/CPT_Hard_5100_SC');

var mascara = rasterarea.eq(1);

var cartas_ibge = ee.FeatureCollection('projects/ee-felipejesus/assets/reMAP_Santa_Catarina/Cartas_IBGE_Santa_Catarina');

//Field lists for clasification
var class_rules = {
  '3c-mp':{
    classFieldName:'cons2024mp',     // Outros = 0, Pastagem Natural = 1, Pastagem Cultivada = 2
    classList: ['OTH', 'NPT', 'CPT'],
    classValues: [0,1,2],
    outfile_suffix: '2024_MultiProb_class'
  },
  '2c-allpt-npt':{
    classFieldName:'cons2024sl',     //natural vs cultivado, utilizando uma classificação prévia como 'geometria' para a nova class
    classList: ['NPT', 'CPT'],
    classValues: [1,2],
    outfile_suffix: '2024_AllPasture_class'
  },
  '2c-oth-npt':{
    classFieldName:'cons2024na', // Pastagem Natural = 1, Outros e Cultivada = 0
    classList: ['OTH', 'NAPT'],
    classValues: [0,1],
    outfile_suffix: '2024_other_and_naturalPasture_class'
  },
  '2c-oth-cpt':{
    classFieldName:'cons2024cu', // Pastagem Cultivada = 1, Outros e Natural = 0
    classList: ['OTH', 'CUPT'],
    classValues: [0,1],
    outfile_suffix: '2024_other_and_cultivatedPasture_class'
  },
  '2c-oth-na-cu-pt':{     // Pastagem cultivada e Natural 1, Outros 0
    classFieldName:'cons2024nc',
    classList: ['OTH', 'APT'],
    classValues: [0,1],
    outfile_suffix: '2024_natural_and_cultivated_Pasture_class_Versus_Others'
  }
};

//=======================================================================================================================================
//Main function, responsible to execute the classification. Accept as parameters the chart name (e.g. 'SE-22-X-A') and the year (e.g. 2022)
function run_classficiation(class_type, region_name) {
  //=====================================================================================================================================
  
  //=====================================cl==================================================================================================
  //Polygons
  
  var region = mascara
  
  var region_buffer = region.geometry().buffer(100000)

  //print(region_name)
  
//=====================================================================================================================================
//FeatureCollection with the areas

    //=====================================================================================================================================
    //Filter date
    var START_DATE = ee.Date('2023-07-01'); //Start date to filter the image collection (usually six months before the main year)
    var END_DATE = ee.Date('2025-06-30'); //End date to filter the image collection (usually six months after the main year)
      
    //=====================================================================================================================================
    //select Sentinel 2 images
    var s2 = ee.ImageCollection("COPERNICUS/S2_HARMONIZED") //Selects the Sentinel 2 TOA Harmonized time series 
        .filterBounds(region_buffer) //Filters the images that intersects with the main and neighbor charts
        .filterDate(START_DATE, END_DATE) //Filters the images by the range of dates (start and end)


    var csPlus = (ee.ImageCollection('GOOGLE/CLOUD_SCORE_PLUS/V1/S2_HARMONIZED') //Selects the Google Sentinel 2 AI Cloud Score +, the best cloud and shadow mask from Sentinel 2
        .filterBounds(region_buffer) //Filters the images that intersects with the main and neighbor charts
        .filterDate(START_DATE, END_DATE)); //Filters the images by the range of dates (start and end)

    var csPlusBands = csPlus.first().bandNames(); //Get the band names of the Cloud Score+ bands

    var s2CloudMasked = (s2.linkCollection(csPlus, csPlusBands) //Link the Sentinel collection with the CloudScore+
        .filter(ee.Filter.lte('CLOUDY_PIXEL_PERCENTAGE', 80)) //Filter the images with more than 80% of cloud
        .map(maskEdges) //Applies the filter to mask fault edges
        .map(maskClouds) //Applies the filter to mask cloud and shadows
        .map(res_bilinear)); //Applies the bilinear resampling on the lower resolution images (i.e. 20 meters)
    
    //print('Number of images used in Region: '+ region_name, s2.size())
    
    //=====================================================================================================================================
    //Applies the spectral index calculations and selects the bands to be used
    var spectralDataNei = (s2CloudMasked
        .map(spectralFeatures)
        .select(['B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'B8', 'B8A','B11', 'B12', 'NDVI', 'NDWI', 'CAI', 'CRI1', 'ARI_1', 'RGR','PSRI', 'SATVI']));
    
    //Calculates the 25% NDVI percentile to use as a noise mask
    var wetThresholdNei = (spectralDataNei
      .select("NDVI")
      .reduce(ee.Reducer.percentile([15])));
      
    //Function made to get the image NDVI and mask it according to the 25% NDVI percentile
    function onlyWetSeasonNei(image) {
        var seasonMask = image.select("ndvi_wet").gte(wetThresholdNei);
        return image.mask(seasonMask);
    }
  
    //Applies the 25% NDVI percentile mask to each image in the collection
    var wetSpectralDataNei = (spectralDataNei
        .select(spectralDataNei.first().bandNames(), BandsWet)
        .map(onlyWetSeasonNei));
      
    //Applies the functions to calculate percentiles, get latitude and longitude, calculate the temporal reducers and adds the elevation and slope data.
     var temporalData = temporalPercs(wetSpectralDataNei)
       .addBands([temporalFeatures(wetSpectralDataNei),elevation, slope]);
        
    var ndvi_3x3 = temporalData.select(['ndvi_wet_stdDev','ndvi_wet_median'])
        .focalMedian({radius:3,kernelType:"square",units:"pixels"})
        .rename(['ndvi_stdDev_3x3','ndvi_median_3x3'])
        
    var featureSpace = ee.Image(temporalData.addBands(ndvi_3x3));
    
    //print(featureSpace.bandNames())
    
    //===================================================================================================================================== 
    //Defines the name of the column to be used as training reference
    var classFieldName = class_rules[class_type]['classFieldName'];
       
    //Training samples used in the Pasture Mapping approach with Landsat
    var trainSamples_main = ee.FeatureCollection('projects/ee-felipejesus/assets/reMAP_Santa_Catarina/Samples_Com_Single_Layer');
//print(trainSamples_main)
    var trainSamples = trainSamples_main.select(classFieldName)

    //====================================================================================================================================
    if (class_type == '2c-allpt-npt'){
    var allpasture = ee.Image('projects/ee-felipejesus/assets/reMAP_Santa_Catarina/CPT_Hard_5100_SC')
      .select('CPT_hard')
      .eq(1)
      .selfMask()
    //extra_waters_samples = ee.FeatureColelction([])
    featureSpace = featureSpace.updateMask(allpasture)
  }
    
   
    //Creates and define the classifier parameters
    var classifier = ee.Classifier.smileRandomForest(rfNTrees, rfVarPersplit, 1, rfBagFraction, null, 2024);

    //Sets the classifier to the Probability Mode
     classifier = classifier.setOutputMode('MULTIPROBABILITY');
      
     //Crosses the training samples with the feature space variables to associate the information with the classes
    var trainSamplesFeeded = (featureSpace.sampleRegions({
        'collection': trainSamples.filterBounds(region_buffer).filter(ee.Filter.neq(classFieldName, null)),
        'properties': [classFieldName],
        'scale': 10,
        'tileScale': 16
    }));
      
    //Trains the classifier using the training samples asociated with the feature space information
    classifier = classifier.train(trainSamplesFeeded, classFieldName);
    
    //=====================================================================================================================================
    //Calculates the feature/variable importance for the classifier
    var importance = ee.Dictionary(classifier.explain().get('importance'));
    
    //Do something to rank/sort the importance of the features from highest to lowest
    var keys = importance.keys().sort(importance.values()).reverse()
    var values = importance.values(keys);

    var rows = keys.zip(values).map(function(list) {
        return {
            c: ee.List(list).map(function(n) {
                return {
                    v: n
                };
            })
        }
    })

    var dataTable = {
        cols: [{
                id: 'band',
                label: 'Band',
                type: 'string'
            },
            {
                id: 'importance',
                label: 'Importance',
                type: 'number'
            }
        ],
        rows: rows
    };
    
    //Prints the ranked feature importance
 //   print('Feature importance of Region: '+ region_name,keys.zip(values))
    
    //=====================================================================================================================================
    // CRIA A CLASSIFICAÇÃO
    var classification = ee.Image(featureSpace.classify(classifier))
      .arrayFlatten([class_rules[class_type]['classList']])
    
    // Nome do arquivo baseado no tipo de classificação
    var fileName = class_rules[class_type]['outfile_suffix'] + '_' + version + '_'+region_name;
    var folder = 'lapig_pasture_mapping_s2_SC' + '_' + version; // Define a pasta de exportação
    
//    Map.addLayer(featureSpace.clip(region),{min: 0, max: 1, bands: ['ndvi_wet_max', 'ndvi_wet_median', 'ndvi_wet_min']},'Mosaic - ' + region_name)
//    Map.addLayer(classification.clip(region),{min:0,max: 1},'Classification Probability '  + region_name)
//    Map.addLayer(classification.gte(0.51).selfMask().clip(region),{palette:['gold']},'Classification Hard Class '  + region_name)
 //   Map.addLayer(region,null,'Region ' + region_name)

    //Save in drive and asset
/*    Export.image.toDrive({
        image: classification.multiply(10000).int16().clip(region), 
        crs: "EPSG:4326",
        region: region.geometry().bounds(),
        description: fileName,
        folder: folder,
        scale: 10,
        maxPixels: 1e13,
    });
  */  
    Export.image.toAsset({
        image: classification.multiply(10000).int16(),
        description: class_rules[class_type]['outfile_suffix'] + '_' + version + '_'+region_name + "_asset",
        assetId: fileName + "_asset",
        region: region.geometry().bounds(),
        scale: 10,
        crs: "EPSG:4326",
        maxPixels: 1e13,
    });
}
//==============================================================================================================================
//run classification
var types_class = ['2c-allpt-npt'];

var regions = [
  'SG-22-X-D', 'SG-22-Z-B', 'SG-22-Z-D', 'SG-22-Z-A', 'SG-22-Z-C',
  'SH-22-X-A', 'SG-22-Y-D', 'SG-22-Y-B', 'SG-22-Y-C', 'SG-22-Y-A',
  'SH-22-X-B', 'SH-22-X-D'
];

//regions = ['SG-22-X-D']

regions.forEach(function(region){
  types_class.forEach(function(class_type){
    run_classficiation(class_type,region);
  });
});