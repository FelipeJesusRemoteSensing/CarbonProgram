# Código da fazenda
###########################################################################################
name_farm <- "BOJ" # MUDAR SEMPRE

# ================================================================
# >>> DEFINA AQUI OS ANOS DE INTERESSE <<<
anos_interesse <- 2020
# Exemplos de uso:
# anos_interesse <- c(2020, 2021, 2022, 2023)
# anos_interesse <- 2000:2025
# ================================================================

suppressWarnings(suppressMessages(library(gtools)))
suppressWarnings(suppressMessages(library(raster)))
suppressWarnings(suppressMessages(library(tidyverse)))
suppressWarnings(suppressMessages(library(lubridate)))
suppressWarnings(suppressMessages(library(terra)))

setwd("C:/Users/anaca/Desktop/codigos_century")
base_path <- "C:/Users/anaca/Nextcloud/century/reverte/rasters/fazendas" # MUDAR UMA UNICA VEZ
folder_match <- list.dirs(base_path, full.names = TRUE, recursive = FALSE)
inputDir <- folder_match[grep(paste0(name_farm, "$"), folder_match)]
outputDir <- "C:/Users/anaca/Desktop/codigos_century/dados/blocos" # MUDAR UMA UNICA VEZ

if(!dir.exists(outputDir)) dir.create(outputDir, recursive = TRUE)

shp_path <- vect("C:/Users/anaca/Nextcloud/century/reverte/shps/talhoes_revert/2026-02-10_ultima_versao/talhoes_revert_final") # MUDAR UMA UNICA VEZ
talhoes <- shp_path[shp_path$Name_Farm == name_farm, ]
name_talhoes <- unique(talhoes$Name)

raster_base_path <- mixedsort(Sys.glob(file.path(inputDir, "*.tif")))[1]
raster_modelo <- rast(raster_base_path)
novos_rasters <- c('2_pasArea_extra', '3_pastAge_extra', '4_PastQly_extra', '5_aptidao_extra')

for (nome_camada in novos_rasters) {
  file_path_out <- file.path(inputDir, paste0(nome_camada, ".tif"))
  if (!file.exists(file_path_out)) {
    r_new <- init(raster_modelo, fun = 2)
    writeRaster(r_new, file_path_out, datatype = "INT2S", overwrite = TRUE)
  }
}

img_lulc <- rast(mixedsort(Sys.glob(file.path(inputDir, "*.tif"))))
names(img_lulc) <- c('cellNumber','pasArea', 'pastAge', 'PastQly', 'aptidao')

f_soil <- mixedsort(Sys.glob(file.path(inputDir, "soil_pronassolos_30m/0-30cm", "*.tif")))
lista_soil <- lapply(f_soil, rast)
img_soil <- lista_soil[[1]]
for (i in 2:length(lista_soil)) {
  img_aligned <- resample(lista_soil[[i]], lista_soil[[1]], method = "near")
  img_soil <- c(img_soil, img_aligned)
}
names(img_soil) <- c('sand', 'silt', 'clay', 'bkrd', 'ph') 

img_ppt <- rast(mixedsort(Sys.glob(file.path(inputDir, "prec_terraclimate_30m", "*.tif"))))
img_tmn <- rast(mixedsort(Sys.glob(file.path(inputDir, "tmin_terraclimate_30m", "*.tif"))))
img_tmx <- rast(mixedsort(Sys.glob(file.path(inputDir, "tmax_terraclimate_30m", "*.tif"))))

DTym <- seq(ymd("1958-01-01"), ymd("2024-12-01"), by = "month")
clim_names <- paste0("X", format(DTym, "%Y.%m.%d"))
names(img_ppt) <- clim_names
names(img_tmn) <- clim_names
names(img_tmx) <- clim_names

for (nome in name_talhoes) {
  message("Processando talhão: ", nome)
  talhao_i <- talhoes[talhoes$Name == nome, ]
  
  if (nrow(talhao_i) == 0) next
  
  val_lulc <- extract(img_lulc, talhao_i)[, -1, drop = FALSE]
  val_soil <- extract(img_soil, talhao_i)[, -1, drop = FALSE]
  val_ppt  <- extract(img_ppt,  talhao_i)[, -1, drop = FALSE]
  val_tmn  <- extract(img_tmn,  talhao_i)[, -1, drop = FALSE]
  val_tmx  <- extract(img_tmx,  talhao_i)[, -1, drop = FALSE]
  
  df_all <- cbind(val_lulc, val_soil, val_ppt, val_tmn, val_tmx)
  outputfile <- file.path(outputDir, paste0(nome, ".csv"))
  write.csv(df_all, outputfile, row.names = FALSE)
}
