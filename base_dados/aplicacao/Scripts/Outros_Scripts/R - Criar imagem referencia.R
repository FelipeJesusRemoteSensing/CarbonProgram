# LAPIG - Grupo Carbono
#
# 2025-05-30
# Marcos Cardoso; Maria Hunter
#
# --


library(terra)

input_folder <- "C:/Users/marco/Downloads/ID-RASTER"
output_folder <- "C:/Users/marco/Downloads/img_ref"

if (!dir.exists(output_folder)) {
  dir.create(output_folder, showWarnings = FALSE, recursive = TRUE)
  print(paste("Pasta de saída criada:", output_folder))
}

tiff_files <- list.files(path = input_folder, pattern = "\\.tif$", full.names = TRUE, ignore.case = TRUE)

if (length(tiff_files) == 0) {
  stop(paste("Nenhum arquivo .tif foi encontrado na pasta de entrada:", input_folder))
} else {
  print(paste("Encontrados", length(tiff_files), "arquivos .tif para processar da pasta:", input_folder))
}

for (file_path in tiff_files) {
  tryCatch({
    original_file_name_with_ext <- basename(file_path)
    original_file_name_no_ext <- tools::file_path_sans_ext(original_file_name_with_ext)
    
    output_file_name <- paste0("img_ref_30m_", original_file_name_no_ext, ".tif")
    output_file_path <- file.path(output_folder, output_file_name)
    
    print(paste("Processando:", original_file_name_with_ext))
    
    r_original <- rast(file_path)
    id_raster <- r_original
    id_raster[] <- 1:ncell(id_raster)
    
    writeRaster(id_raster, output_file_path, overwrite = TRUE)
    
    print(paste("Salvo em:", output_file_path))
    
  }, error = function(e) {
    print(paste("Erro ao processar o arquivo", basename(file_path), ":", e$message))
  })
}

print(paste("Processamento concluído! Arquivos salvos em:", output_folder))