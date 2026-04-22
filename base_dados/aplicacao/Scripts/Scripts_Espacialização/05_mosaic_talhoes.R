###############################################
# Script 5 – Organização e mosaico SOMSC por fazenda
###############################################

options(scipen = 9999)

suppressWarnings(suppressMessages(library(terra)))
suppressWarnings(suppressMessages(library(tidyverse)))
suppressWarnings(suppressMessages(library(gtools)))

###
# ================================================================
# >>> ANOS DE INTERESSE <<<
# Se quiser pegar todos os anos disponíveis, deixe como NULL
anos_interesse <- NULL  

# Se quiser selecionar apenas um ano específico, descomente e defina:
# anos_interesse <- 2025
# ================================================================

###
# Diretório raiz dos outputs por talhão
if (exists("outputDir")) {
  output_root <- outputDir
} else {
  output_root <- "C:/Users/anaca/Desktop/codigos_century/dados/output"
  cat("[INFO] outputDir não encontrado na sessão. Usando padrão:", output_root, "\n")
}

###
# Diretório base para organizar os resultados espacializados
base_espacializado <- "C:/Users/anaca/Desktop/codigos_century/fazendas_espacializadas"
if (!dir.exists(base_espacializado)) dir.create(base_espacializado, recursive = TRUE)

###
# Lista todas as pastas de talhões
talhoes_dirs <- list.dirs(
  path = output_root,
  full.names = TRUE,
  recursive = FALSE
)

# Remove possíveis pastas antigas de mosaico da lista
talhoes_dirs <- talhoes_dirs[basename(talhoes_dirs) != "mosaicos"]

###
# Detecta anos disponíveis automaticamente, se anos_interesse = NULL
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
  
  ###
  # Encontra TODOS os rasters SOMSC dos talhões para este ano
  rasters_somsc <- map(
    talhoes_dirs,
    ~ list.files(
      file.path(.x, paste0("out_sub_somsc_", anos_label)),
      pattern = paste0("_somsc_", anos_label, "_mean\\.tif$"),
      full.names = TRUE
    )
  ) %>% unlist()
  
  if (length(rasters_somsc) == 0) {
    cat("[AVISO] Nenhum raster SOMSC encontrado para o ano", ano, "\n")
    next
  }
  
  ###
  # Cria tabela com raster + código da fazenda + caminho do talhão
  df_rasters <- tibble(
    raster_path = rasters_somsc,
    talhao_dir = dirname(rasters_somsc),
    talhao_name = basename(dirname(dirname(rasters_somsc)))
  ) %>%
    mutate(
      codigo_fazenda = substr(talhao_name, 1, 3)
    )
  
  ###
  # LOOP POR FAZENDA
  for (codigo in unique(df_rasters$codigo_fazenda)) {
    
    cat("\n--------------------------------------------------\n")
    cat("Processando fazenda:", codigo, "| Ano:", ano, "\n")
    
    # Cria pasta da fazenda
    pasta_fazenda <- file.path(base_espacializado, codigo)
    if (!dir.exists(pasta_fazenda)) dir.create(pasta_fazenda, recursive = TRUE)
    
    # Cria subpastas mosaico e talhoes
    pasta_mosaico <- file.path(pasta_fazenda, "mosaico")
    pasta_talhoes <- file.path(pasta_fazenda, "talhoes")
    if (!dir.exists(pasta_mosaico)) dir.create(pasta_mosaico)
    if (!dir.exists(pasta_talhoes)) dir.create(pasta_talhoes)
    
    # -----------------------------
    # 1) Mosaico da fazenda
    rasters_fazenda <- df_rasters %>%
      filter(codigo_fazenda == codigo) %>%
      pull(raster_path)
    
    if (length(rasters_fazenda) == 0) {
      cat("[AVISO] Nenhum raster encontrado para a fazenda", codigo, "\n")
    } else {
      rast_list <- lapply(rasters_fazenda, rast)
      mosaico <- do.call(mosaic, rast_list)
      
      out_mosaic <- file.path(pasta_mosaico, paste0(ano, "_somsc_", codigo, ".tif"))
      
      if (file.exists(out_mosaic)) file.remove(out_mosaic)
      writeRaster(mosaico, out_mosaic, overwrite = TRUE)
      cat("Mosaico salvo em:", out_mosaic, "\n")
    }
    
    # -----------------------------
    # 2) Copiar talhões para pasta talhoes
    talhoes_fazenda <- df_rasters %>%
      filter(codigo_fazenda == codigo) %>%
      pull(talhao_dir) %>%
      unique()
    
    for (talhao_path in talhoes_fazenda) {
      nome_talhoes <- basename(talhao_path)
      dest_path <- file.path(pasta_talhoes, nome_talhoes)
      
      if (!dir.exists(dest_path)) {
        dir.create(dest_path, recursive = TRUE)
      }
      
      # Copia todos os CSVs e rasters do talhão para a pasta
      arquivos_talhoes <- list.files(talhao_path, full.names = TRUE)
      file.copy(arquivos_talhoes, dest_path, overwrite = TRUE, recursive = TRUE)
      cat("Talhão copiado para:", dest_path, "\n")
    }
  }
}

cat("\nOrganização espacializada finalizada com sucesso.\n")
