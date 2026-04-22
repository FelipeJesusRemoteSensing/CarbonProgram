##################################################################
#' Claudinei Oliveira dos Santos
#' Biologo | Msc. Ecologia | Dr. Ciências Ambientais
#' LAPIG - UFG
#' claudineisan@pastoepixel.com
##################################################################

#' Leitura e Processamento de Arquivos Century (.lis)
#' Versão: Escolha de anos, Fallback para Eq_, Fallback sem CSV (com texto padrão) e Avisos de Anos

options(scipen = 9999)
library(tidyverse)
library(stringr)

###
#' Parâmetros Iniciais (Anos de interesse para os arquivos Lu_)
ano_inicio_lu <- 2015
ano_fim_lu <- 2025

###
#' Caminhos
path_base_root <- "."
path_results   <- file.path(path_base_root, "result/result_lu_cm")

# Caminho do arquivo de resumo
## -- 

# NÃO É OBRIGATÓRIO ATUALIZAR, APENAS SE QUISER INFORMAR QUAIS PARAMETROS FORAM ALTERADOS (UTILIZE O SCRIPT "XX" PARA GERAR O ARQUIVO) 
path_resumo_csv <- "0_30/resumo_variacoes.csv" 

## -- 

###
#' 1. Carregar Tabela de Resumo (Lote, Simulation, Obs)
has_resumo <- FALSE

if (file.exists(path_resumo_csv)) {
  df_resumo <- read.csv(path_resumo_csv, stringsAsFactors = FALSE) 
  names(df_resumo) <- tolower(names(df_resumo)) 
  
  if("lote" %in% names(df_resumo)) df_resumo$lote <- as.numeric(df_resumo$lote)
  if("simulation" %in% names(df_resumo)) df_resumo$simulation <- as.numeric(df_resumo$simulation)
  
  has_resumo <- TRUE
  print("Arquivo de resumo carregado com sucesso.")
} else {
  message("Aviso: Arquivo resumo_variacoes.csv não encontrado. Os metadados 'lote_folder' e 'sim_folder' serão extraídos das pastas e a coluna 'obs' será preenchida com o texto padrão.")
}

###
#' Listar pastas de Lotes
dirs_lotes <- list.dirs(path_results, full.names = TRUE, recursive = FALSE)
dirs_lotes <- grep("lote_", dirs_lotes, value = TRUE)

df_results_final <- NULL

# --- Loop pelos Lotes ---
for (dir_lote_i in dirs_lotes) {
  
  nome_lote <- basename(dir_lote_i)
  num_lote  <- as.numeric(str_extract(nome_lote, "\\d+"))
  
  print(paste("Processando:", nome_lote))
  
  # --- Loop pelas Simulações ---
  dirs_sims <- list.dirs(dir_lote_i, full.names = TRUE, recursive = FALSE)
  dirs_sims <- grep("simulation", dirs_sims, value = TRUE)
  
  for (dir_sim_j in dirs_sims) {
    
    nome_sim <- basename(dir_sim_j)
    num_sim  <- as.numeric(str_extract(nome_sim, "\\d+"))
    
    # --- LÓGICA DA OBS (Texto Padrão) ---
    obs_text <- "parametros alterados no multfiles"
    
    if (has_resumo) {
      row_match <- df_resumo %>% 
        filter(lote == num_lote & simulation == num_sim)
      
      # Se encontrar correspondência no CSV e o campo não estiver vazio, substitui o texto padrão
      if (nrow(row_match) > 0 && !is.na(row_match$obs[1]) && row_match$obs[1] != "") {
        obs_text <- row_match$obs[1] 
      }
    }
    
    # --- Lógica Lu_ vs Eq_ ---
    lis_files_lu <- Sys.glob(file.path(dir_sim_j, "Lu*.lis"))
    lis_files_eq <- Sys.glob(file.path(dir_sim_j, "Eq*.lis"))
    
    if (length(lis_files_lu) > 0) {
      lis_files <- lis_files_lu
      ano_inicio_filtro <- ano_inicio_lu
      ano_fim_filtro <- ano_fim_lu
      tipo_arquivo_str <- "Lu"
    } else if (length(lis_files_eq) > 0) {
      lis_files <- lis_files_eq
      ano_inicio_filtro <- 9990
      ano_fim_filtro <- 10000
      tipo_arquivo_str <- "Eq"
    } else {
      next 
    }
    
    lis_files_names <- basename(lis_files)
    lis_files_id <- str_remove(str_remove(lis_files_names, "^(Lu_|Eq_)"), "\\.lis$")
    
    nloop <- length(lis_files_id)
    
    for (i in 1:nloop) {
      id_i <- lis_files_id[i]
      file_path <- lis_files[i]
      
      try({
        df_results_i <- read.table(file_path, header = TRUE)
        
        # Identifica os anos presentes no arquivo para caso de erro
        min_ano_disp <- min(df_results_i$time, na.rm = TRUE)
        max_ano_disp <- max(df_results_i$time, na.rm = TRUE)
        
        # Filtro de ano dinâmico
        sub_df_lis_i <- df_results_i[between(df_results_i$time, ano_inicio_filtro, ano_fim_filtro), ]
        
        if (nrow(sub_df_lis_i) > 0) {
          sub_df_lis_i$ponto        <- str_replace(id_i, '/', '_')
          sub_df_lis_i$lote_folder  <- nome_lote
          sub_df_lis_i$sim_folder   <- nome_sim
          sub_df_lis_i$sim_id       <- num_sim
          sub_df_lis_i$obs          <- obs_text
          sub_df_lis_i$tipo_arquivo <- tipo_arquivo_str 
          
          cols_meta <- c("lote_folder", "sim_folder", "ponto", "tipo_arquivo", "obs", "time")
          cols_data <- setdiff(names(sub_df_lis_i), cols_meta)
          
          cols_existentes <- intersect(c(cols_meta, cols_data), names(sub_df_lis_i))
          sub_df_lis_i <- sub_df_lis_i[, cols_existentes]
          
          df_results_final <- rbind(df_results_final, sub_df_lis_i)
        } else {
          # Se não encontrou os anos, emite o alerta no console
          alerta <- sprintf("-> AVISO: Ponto %s (%s/%s | %s) não contém os anos %d a %d. Anos disponíveis: %d a %d", 
                            id_i, nome_lote, nome_sim, tipo_arquivo_str, 
                            ano_inicio_filtro, ano_fim_filtro, 
                            min_ano_disp, max_ano_disp)
          message(alerta)
        }
      }, silent = TRUE)
    }
  }
}

###
#' Output
if (!is.null(df_results_final)) {
  write.csv(df_results_final, 
            file = file.path(path_base_root, 'result/resultados_century_simulations.csv'), 
            row.names = FALSE)
  print("Processamento concluído com sucesso.")
} else {
  print("Nenhum dado válido encontrado para processamento.")
}