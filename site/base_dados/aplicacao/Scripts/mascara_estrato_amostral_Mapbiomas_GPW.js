//filtro de classes(Campestre, Mosaicos de uso, Pastagem e outros usos MapBiomas
var ano = 2022
var lulc = ee.Image('projects/mapbiomas-public/assets/brazil/lulc/collection9/mapbiomas_collection90_integration_v1')
          .select('classification_'+ano)
    
    lulc = lulc.remap({
      from: [15,21,12],
      to: [15,21,12],
      defaultValue: 0,
      
    })      

//Aplicar a mascara do MU sobre a classe de natural and semi/natural do GPW
var gpwclasses = ee.ImageCollection('projects/global-pasture-watch/assets/ggc-30m/v1/grassland_c')
                .filterDate('2022-01-01', '2023-01-01') //Filtrar o periodo desejado
                .first()
                .unmask()

//Transicao.Inserir área de estudo
var sc = ee.FeatureCollection('projects/ee-polianavieira/assets/Santa_Catarina')
var transicao = lulc.multiply(100).add(gpwclasses).clip(sc)
var histogram = transicao.reduceRegion({
  reducer: ee.Reducer.frequencyHistogram(),
  geometry: sc.geometry(),
  scale: 30,
  maxPixels: 1e15})
print(histogram)

Map.addLayer(transicao)
Map.centerObject(sc)

//Exportar máscara de estrato amostral como asset
Export.image.toAsset({
      image: transicao,
      description: 'transicao_mascara',
      region:sc.geometry().bounds(),
      scale:30,
      maxPixels: 1e9 ,

})
