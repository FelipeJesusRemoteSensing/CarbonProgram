##################################################################
# Script 4 – Rasterização SOMSC (por talhão)
##################################################################

# ================================================================
# >>> DEFINA AQUI OS ANOS DE INTERESSE <<<
# Para detectar todos os anos automaticamente, deixe como NULL
anos_interesse <- NULL
# Para selecionar manualmente apenas um ano, descomente a linha abaixo:
# anos_interesse <- 2025
# ================================================================

options(scipen = 9999)

suppressWarnings(suppressMessages(library(terra)))
suppressWarnings(suppressMessages(library(tidyverse)))
suppressWarnings(suppressMessages(library(data.table)))
suppressWarnings(suppressMessages(library(gtools)))

###
# Diretório raiz dos outputs do Century
if (exists("outputDir")) {
  output_root <- outputDir
} else {
  output_root <- "C:/Users/anaca/Desktop/codigos_century/dados/output"
}

###
# Diretório base das fazendas (rasters modelo)
if (exists("base_path")) {
  base_fazendas <- base_path
} else {
  base_fazendas <- "C:/Users/anaca/Nextcloud/century/reverte/rasters/fazendas"
}

###
# Lista de pastas de fazendas (ex: "GO - BOJ")
fazendas_dirs <- list.dirs(
  base_fazendas,
  full.names = TRUE,
  recursive = FALSE
)

###
# Lista de talhões (pastas dentro do output)
talhoes_dirs <- list.dirs(
  path = output_root,
  full.names = TRUE,
  recursive = FALSE
)

###
# Detecta anos disponíveis automaticamente se anos_interesse = NULL
if (is.null(anos_interesse)) {
  anos_detectados <- c()
  for (talhao_path in talhoes_dirs) {
    pastas_somsc <- list.dirs(talhao_path, full.names = FALSE, recursive = FALSE)
    anos_talhoes <- pastas_somsc[grepl("^out_sub_somsc_", pastas_somsc)] %>%
      str_remove("^out_sub_somsc_")
    anos_detectados <- c(anos_detectados, anos_talhoes)
  }
  anos_detectados <- unique(anos_detectados)
  anos_interesse <- as.numeric(anos_detectados)
  cat("Anos detectados automaticamente:", paste(anos_interesse, collapse = ", "), "\n")
}

###
# LOOP POR ANO
for (ano in anos_interesse) {
  
  anos_label <- paste(ano, collapse = "_")
  
  cat("\n==============================\n")
  cat("Processando ano:", ano, "\n")
  
  # ------------------------------------------------------------
  # LOOP POR TALHÃO
  for (talhao_path in talhoes_dirs) {
    
    talhao_name <- basename(talhao_path)
    cat("\n------------------------------------------------------------\n")
    cat("Processando talhão:", talhao_name, "\n")
    
    # 1) Código da fazenda = 3 primeiras letras do talhão
    fazenda_codigo <- substr(talhao_name, 1, 3)
    
    # 2) Encontrar pasta da fazenda que termina com o código
    fazenda_dir <- fazendas_dirs[
      grepl(paste0(fazenda_codigo, "$"), basename(fazendas_dirs))
    ]
    
    if (length(fazenda_dir) == 0) {
      cat("[AVISO] Fazenda não encontrada para talhão:", talhao_name, "\n")
      next
    }
    
    if (length(fazenda_dir) > 1) {
      cat(
        "[AVISO] Múltiplas pastas encontradas para o código",
        fazenda_codigo, "- usando a primeira\n"
      )
      fazenda_dir <- fazenda_dir[1]
    }
    
    # 3) Raster modelo da fazenda (primeiro .tif da pasta)
    tifs_fazenda <- mixedsort(list.files(fazenda_dir, pattern = "\\.tif$", full.names = TRUE))
    
    if (length(tifs_fazenda) == 0) {
      cat("[AVISO] Nenhum raster encontrado em:", fazenda_dir, "\n")
      next
    }
    
    raster_base_path <- tifs_fazenda[1]
    img <- rast(raster_base_path)
    cat("Raster modelo da fazenda:", basename(raster_base_path), "\n")
    
    # 4) Diretório de entrada SOMSC
    input_dir <- file.path(
      talhao_path,
      paste0("out_sub_somsc_", anos_label)
    )
    
    if (!dir.exists(input_dir)) {
      cat("Ignorando talhão (sem out_sub_somsc_", anos_label, "):", talhao_name, "\n")
      next
    }
    
    csv_files <- mixedsort(list.files(input_dir, pattern = "\\.csv$", full.names = TRUE))
    
    if (length(csv_files) == 0) {
      cat("[AVISO] Nenhum CSV SOMSC encontrado para talhão:", talhao_name, "\n")
      next
    }
    
    dta <- map_dfr(csv_files, read_csv) %>% drop_na()
    
    # 5) Rasterização
    tmp_img <- img
    tmp_img[] <- NA
    tmp_img[dta$cellNumber] <- dta$somsc_mean / 100
    
    out_raster <- file.path(
      input_dir,
      paste0("talhao_", talhao_name, "_somsc_", anos_label, "_mean.tif")
    )
    
    # Remove o arquivo antigo se existir
    if (file.exists(out_raster)) {
      cat("[INFO] Arquivo já existe. Removendo:", out_raster, "\n")
      file.remove(out_raster)
    }
    
    writeRaster(tmp_img, out_raster, overwrite = TRUE)
    cat("Raster SOMSC salvo em:", out_raster, "\n")
  }
}

cat("\nScript 4 finalizado com sucesso.\n")
