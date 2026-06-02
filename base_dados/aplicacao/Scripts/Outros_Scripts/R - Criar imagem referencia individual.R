# LAPIG - Laboratório de Processamento de Imagens e Geoprocessamento
# Script: Criar Raster de Referência (ID)
#
# Data: 2024-06-23
#
# Descrição:
# Este script carrega um arquivo raster .tif específico, cria um novo
# raster onde cada pixel tem um valor de ID sequencial único, e salva
# este novo raster na mesma pasta do arquivo original com um nome modificado.
# --

# Carrega a biblioteca 'terra' para manipulação de dados raster.
# Se não estiver instalada, instale com: install.packages("terra")
library(terra)

input_file_path <- "D:/Projetos-Lapig/century/revert/rasters/Fazendas/MT - Agua Cristal - 6-57-7/lulc_mb_col9_30m/1985_lulc_6-57-7.tif"

tryCatch({
  
  if (!file.exists(input_file_path)) {
    stop("O arquivo de entrada não foi encontrado. Verifique o caminho.")
  }
  
  input_folder <- dirname(input_file_path)
  original_file_name_with_ext <- basename(input_file_path)
  original_file_name_no_ext <- tools::file_path_sans_ext(original_file_name_with_ext)
  
  output_file_name <- paste0("img_ref_30m_", original_file_name_no_ext, ".tif")
  output_file_path <- file.path(input_folder, output_file_name)
  
  print(paste("Processando:", original_file_name_with_ext))
  
  r_original <- rast(input_file_path)
  
  id_raster <- r_original
  
  id_raster[] <- 1:ncell(id_raster)
  
  writeRaster(id_raster, output_file_path, overwrite = TRUE)
  
  print(paste("Arquivo de referência salvo com sucesso em:", output_file_path))
  
}, error = function(e) {
  print(paste("ERRO ao processar o arquivo:", basename(input_file_path)))
  print(paste("Mensagem de erro:", e$message))
})