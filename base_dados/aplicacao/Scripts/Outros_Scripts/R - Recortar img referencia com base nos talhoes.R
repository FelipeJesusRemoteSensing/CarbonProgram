# LAPIG - Laboratório de Processamento de Imagens e Geoprocessamento
# Grupo Carbono 
# Script: Criar Raster de Referência (ID)
#
# Data: 2024-06-23
# Marcos Cardoso, Felipe Jesus, Maria Hunter
# 
# Descrição:
# Recorta as imagens referência com base nos shapefiles dos talhões
# --

library(raster)
library(sf)

caminho_raster <- "D:/Projetos-Lapig/century/revert/rasters/Fazendas/GO - Morasha - 35-38-76-34-36-39/img_ref_30m_35-38-76-34-36-39.tif"
caminho_shapefile <- "D:/Projeto_LAPIG/Revert/Centroids Morasha/talhoes_morasha_revert_2.shp"
diretorio_saida <- "D:/Projeto_LAPIG/Revert/Centroids Morasha/Talhoes_Recortados"

if (!dir.exists(diretorio_saida)) {
  dir.create(diretorio_saida, recursive = TRUE)
}

imagem_base <- raster(caminho_raster)
talhoes <- st_read(caminho_shapefile)

if (st_crs(talhoes) != crs(imagem_base)) {
  talhoes <- st_transform(talhoes, crs = crs(imagem_base))
}

for (i in 1:nrow(talhoes)) {
  
  talhao_individual <- talhoes[i, ]
  
  id_talhao <- talhao_individual$layer
  
  raster_recortado <- mask(crop(imagem_base, talhao_individual), talhao_individual)
  
  nome_arquivo_saida <- file.path(diretorio_saida, paste0("img_ref_talhao_", id_talhao, ".tif"))
  
  writeRaster(raster_recortado, filename = nome_arquivo_saida, format = "GTiff", overwrite = TRUE)
  
}