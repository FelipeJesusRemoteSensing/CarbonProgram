
#############INSTALAÇÃO ##########################################################

#install.packages("rgee")
#install.packages("reticulate")
##EE authenticate error solution: https://gis.stackexchange.com/questions/473730/authentification-error-when-installing-rgee-in-rstudio
##    erro resumidamente: estava dando erro na nova versão do Google API pra resolver tivemos que mudar a versão e colocar uma anterior, 
##          problema disso é que esse versão em algum momento vai para de funcionar. 

#library(reticulate)
#py_config() # see the name of your conda (python) environment, in my case "r-reticulate". From: "pythonhome: C:/Users/user_name/AppData/Local/r-miniconda/envs/r-reticulate"
#reticulate::py_install('earthengine-api==0.1.370', envname='r-reticulate') 

#install.packages("mapview")
library(sf)           # Para manipular shapefiles
library(geojsonio)     # Necessário para conversão GeoJSON
library (rgee)
library(reticulate)
#ee_check()
ee_Initialize()

# Force o uso do seu ambiente específico antes de inicializar
reticulate::use_virtualenv("r-reticulate", required = TRUE)
ee_Initialize()

#MapBiomas = ee$Image('projects/mapbiomas-public/assets/brazil/lulc/collection9/mapbiomas_collection90_integration_v1')
reg = ee$FeatureCollection('projects/ee-polianavieira/assets/Santa_Catarina')
map = ee$Image('projects/ee-polianavieira/assets/transicao_mascara')$clip(reg);
Map$addLayer (map)

classList = c(0,1,1200,1201,1202,1500,1501,1502,2,2100,2101,2102) #Classes que tem na mascara

#############CONTAGEM DE PIXELS ##########################################################
mascara = map

count_pixels = function(LULC_Class){
  class_map = mascara$updateMask(mascara$eq(LULC_Class))
  
  count = class_map$reduceRegion(
    reducer = ee$Reducer$count(), 
    geometry = reg$geometry(), 
    scale = 30,
    maxPixels = 1E13
  )
  
  count_valeu = ee$Number(count$get('remapped'))$int()$getInfo()
  
  cat(paste("Class", LULC_Class, ";", count_valeu, "\n"))
  
  return(count_valeu)
  
}

#Aplicar a função a cada classe na lista e acumular resultados 
counts <- sapply(classList, function(cls) {
  count_pixels(cls)
})

counts = as.numeric(counts)
total_pixels = sum(counts)

table = cbind(classList, counts)
write.csv2(table, "table_pixels_sc_remap.csv")
################CALCULO DA QUANTIDADE DE AMOSTRAS##############################################################
confianca = 0.95
m_erro = 0.08
p = 0.5
Wh_class = counts/total_pixels
Wh_uniforme = c(0.269412006152833,
                0.059150159927343,
                0.155839582117765,
                0.163650221640816,
                0.00879901664264175,
                0.107094020182659,
                0.128052430823009,
                0.00142110832461447,
                0.0020066148748326,
                0.0639213271805,
                0.0390367224003226,
                0.00161678973266348)
#Wh_media_class = (Wh_class+Wh_uniforme)/2
W_2_sh_2_wh =(Wh_class^2*p*(1-p))/Wh_uniforme
sum_W_2_sh_2_wh = sum(W_2_sh_2_wh)
Wh_sh_2 = Wh_class*(p*(1-p))
sum_Wh_sh_2 = sum(Wh_sh_2)
V = (m_erro/qnorm(confianca+(1-confianca)/2))^2
n0 = (1/V)*sum_W_2_sh_2_wh
total_amostras =ceiling(n0/(1+(1/(total_pixels*V))*sum_Wh_sh_2))
amostras_class_val = ceiling(total_amostras*Wh_uniforme)
total_amostras_treinamento = (amostras_class_val*(length(classList))/0.3)
amostras_class = total_amostras_treinamento
#amostras_class = ceiling(rep(total_amostras_treinamento/length(classList), length(classList))) 
sum(amostras_class)

###############SORTEIO DAS AMOSTRAS###########################################################################
samples = map$stratifiedSample(
  numPoints = 0,
  scale = 30,
  region = reg$geometry()$bounds(),
  classValues = classList,
  classPoints = amostras_class,
  tileScale = 16,
  geometries = TRUE
  )

Map$addLayer(samples)
samples_sf <- ee_as_sf(samples, maxFeatures = 12441)
#pontos_ee <- sf_as_ee(samples_UBV_sf)

# Reordenando as linhas aleatoriamente
pontos_sf_aleatorio <- samples_sf[sample(nrow(samples_sf)), ]
# Extraindo as coordenadas (longitude e latitude)
coords <- st_coordinates(pontos_sf_aleatorio)

# Adicionando as colunas de latitude e longitude ao objeto sf
pontos_sf_aleatorio$lon <- coords[, "X"]
pontos_sf_aleatorio$lat <- coords[, "Y"]

# Adicionando uma coluna de ID
pontos_sf_aleatorio$ID <- 1:nrow(pontos_sf_aleatorio)

# Exibindo o resultado
print(pontos_sf_aleatorio)
# Exibindo o resultado
print(pontos_sf_aleatorio)
st_write(pontos_sf_aleatorio, "samples.geojson", driver = "GeoJSON")

#############################################################################
idade = ee$Image('projects/mapbiomas-public/assets/brazil/lulc/collection9/mapbiomas_collection90_pasture_age_v1')$clip(reg)$select('age_2023');
# Extrair valores da imagem para os pontos
valores_extraidos <- idade$sampleRegions(
  collection = samples,     # A FeatureCollection de pontos
  scale = 30,                 # Resolução em metros (ou o valor da escala da imagem)
  geometries = TRUE           # Para manter a geometria dos pontos
)
 
 


