# ================================================================
# >>> ANOS DE INTERESSE – puxados do Script 1 <<<
# Se o Script 1 não foi executado, define manualmente:
if (!exists("anos_interesse")) {
  anos_interesse <- 2025
  # anos_interesse <- c(2020, 2021, 2022, 2023)
}
anos_label <- paste(anos_interesse, collapse = "_")
padrao_somsc <- paste0("somsc_", anos_interesse)
# ================================================================

#' Packages, functions and configurations
options(scipen = 9999)

suppressWarnings(suppressMessages(library(gtools)))
suppressWarnings(suppressMessages(library(raster)))
suppressWarnings(suppressMessages(library(tidyverse)))
suppressWarnings(suppressMessages(library(data.table)))

###
#' CONFIGURAÇÃO PRINCIPAL – caminhos herdados do Script 1
if (exists("outputDir")) {
  root_dir <- outputDir
} else {
  root_dir <- "C:/Users/anaca/Desktop/codigos_century/dados/output"
}

cat("Total de talhões encontrados na pasta:", root_dir, "\n")
cat("Iniciando processamento...\n\n")

# Lista todas as subpastas (cada uma = um talhão/bloco)
all_dirs <- list.dirs(
  path = root_dir,
  full.names = TRUE,
  recursive = FALSE
)

cat("Total de talhões encontrados:", length(all_dirs), "\n")
cat("Iniciando processamento...\n\n")

###
#' LOOP PRINCIPAL – TALHÃO POR TALHÃO
for (talhao_path in all_dirs) {
  
  talhao_name <- basename(talhao_path)
  
  # Lista apenas CSVs diretamente dentro do talhão
  csv_files <- list.files(
    talhao_path,
    pattern = "\\.csv$",
    full.names = TRUE
  ) %>% mixedsort()
  
  if (length(csv_files) > 0) {
    
    cat('--------------------------------------------------\n')
    cat('PROCESSANDO TALHÃO:', talhao_name, '\n')
    cat('  -> Arquivos encontrados:', length(csv_files), '\n')
    
    # Diretório de saída por talhão
    out_dir <- file.path(talhao_path, paste0("out_sub_somsc_", anos_label))
    if (!dir.exists(out_dir)) {
      dir.create(out_dir)
      cat('  -> Diretório de saída criado:', out_dir, '\n')
    }
    
    for (file_path in csv_files) {
      
      file_name <- basename(file_path)
      
      # Segurança: não reprocessar arquivos de output
      if (grepl("out_sub_somsc", file_path)) next
      
      cat('  -> Lendo:', file_name, '\n')
      
      tryCatch({
        
        temp_csv <- fread(file_path) %>%
          select(
            cellNumber,
            matches(paste(padrao_somsc, collapse = "|"))
          )
        
        cols_somsc <- names(temp_csv)[str_detect(
          names(temp_csv),
          paste(padrao_somsc, collapse = "|")
        )]
        
        if (length(cols_somsc) > 0) {
          
          temp_csv_all <- temp_csv %>%
            mutate(
              somsc_mean = rowMeans(
                select(., all_of(cols_somsc)),
                na.rm = TRUE
              )
            ) %>%
            select(cellNumber, somsc_mean) %>%
            as_tibble()
          
          # Salvar CSV
          new_filename <- str_replace(
            file_name,
            "\\.csv$",
            paste0("_", anos_label, ".csv")
          )
          
          write_csv(
            temp_csv_all,
            file.path(out_dir, new_filename)
          )
          
          # --- QC VISUAL ---
          mean_val <- mean(temp_csv_all$somsc_mean, na.rm = TRUE)
          
          p <- ggplot(temp_csv_all, aes(x = somsc_mean)) +
            geom_histogram(bins = 30, fill = "#404080", color = "white") +
            geom_vline(
              xintercept = mean_val,
              color = "red",
              linetype = "dashed"
            ) +
            labs(
              title = paste("QC – somsc (", anos_label, ") | Talhão:", talhao_name),
              subtitle = paste(
                "Arquivo:", new_filename,
                "| Média:", round(mean_val, 2)
              ),
              x = "somsc",
              y = "Frequência"
            ) +
            theme_light()
          
          ggsave(
            filename = file.path(
              out_dir,
              str_replace(new_filename, "\\.csv$", "_QC.png")
            ),
            plot = p,
            width = 6,
            height = 4,
            dpi = 100
          )
          
        } else {
          cat("     [AVISO] Nenhuma coluna somsc encontrada para os anos definidos.\n")
        }
        
      }, error = function(e) {
        cat("     [ERRO]", conditionMessage(e), "\n")
      })
      
      rm(temp_csv)
      if (exists("temp_csv_all")) rm(temp_csv_all)
      if (exists("p")) rm(p)
      gc(FALSE)
    }
  }
}

cat("\nProcessamento finalizado com sucesso!\n")
