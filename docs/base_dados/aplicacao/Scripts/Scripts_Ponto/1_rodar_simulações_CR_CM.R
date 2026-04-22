# ----
# RODAR SIMULAÇÕES CENTURY
# 
# O script irá identificar automaticamente se será clima médio ou clima real (.wth)
# ----
source("functionsRcentury.R")

schEq <- Sys.glob(file.path("ponto", "E*.sch"))
cemEq <- Sys.glob(file.path("ponto", "E*.100"))
schLu <- Sys.glob(file.path("ponto", "Lu*.sch"))
cemLu <- Sys.glob(file.path("ponto", "Lu*.100"))

lisEq <- gsub("100", "lis", gsub("ponto/", "result/result_lu_cm/", cemEq))
binEq <- gsub("100", "bin", gsub("ponto/", "result/result_lu_cm/", cemEq))
lisLu <- gsub("100", "lis", gsub("ponto/", "result/result_lu_cm/", cemLu))
binLu <- gsub("100", "bin", gsub("ponto/", "result/result_lu_cm/", cemLu))

file100 <- Sys.glob(file.path("century", "*.100"))

dir_csvs <- "century_parametros"
lista_arquivos_csv <- list.files(
  path = dir_csvs, 
  pattern = "simulation_multfiles_(\\d+|test)\\.csv", 
  full.names = TRUE
)

total_arquivos <- length(lista_arquivos_csv)

if(total_arquivos == 0) {
  stop("Nenhum arquivo 'simulation_multfiles' (numérico ou test) encontrado no diretório.")
}

start_time <- Sys.time()

for (idx_arquivo in 1:total_arquivos) {
  
  csv_path <- lista_arquivos_csv[idx_arquivo]
  arquivos_restantes <- total_arquivos - idx_arquivo
  nome_arquivo <- basename(csv_path)
  id_lote <- gsub("simulation_multfiles_|.csv", "", nome_arquivo)
  
  cat("\n#####################################################\n")
  cat(sprintf("ARQUIVO ATUAL: %d de %d | %s (ID Lote: %s)\n", idx_arquivo, total_arquivos, nome_arquivo, id_lote))
  cat(sprintf("FALTAM PROCESSAR: %d arquivo(s)\n", arquivos_restantes))
  
  if (idx_arquivo > 1) {
    elapsed_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    avg_time <- elapsed_time / (idx_arquivo - 1)
    eta_secs <- avg_time * (arquivos_restantes + 1)
    eta_formatted <- sprintf("%02d:%02d:%02d", eta_secs %/% 3600, (eta_secs %% 3600) %/% 60, round(eta_secs %% 60))
    cat(sprintf("TEMPO ESTIMADO RESTANTE: %s\n", eta_formatted))
  } else {
    cat("TEMPO ESTIMADO RESTANTE: Calculando após o primeiro arquivo...\n")
  }
  cat("#####################################################\n")
  
  toSimulation <- read.csv(csv_path)
  simulations <- unique(toSimulation$simulation)
  
  for (p in 1:length(simulations)){
    cat("  -> Simulation", p, "do Lote", id_lote, "\n")
    toSimulationI <- toSimulation[toSimulation$simulation == p, ]
    
    for(l in 1:nrow(toSimulationI)){
      f100ToChange <- grep(as.character(unique(toSimulationI$arquivo[l])), file100, value = TRUE)
      f100Change <- as.character(toSimulationI[l, 1])
      linhaI <- toSimulationI[l, "linha"]
      
      changFILES_linhaI(changeFrom = f100ToChange , changeTo = f100Change, linha = linhaI)
    }
    
    for (i in 1:length(lisEq)){
      schEqI <- schEq[i]
      cemEqI <- cemEq[i]
      schLuI <- schLu[i]
      cemLuI <- cemLu[i]
      
      # Constroi o caminho esperado para o arquivo .wth correspondente a esta amostra
      wthLuI <- gsub("\\.sch$", ".wth", schLuI)
      
      # Verifica se o arquivo .wth existe no diretório
      if (file.exists(wthLuI)) {
        cat("     [+] Arquivo .wth encontrado. Rodando runCenturyLuCR (Clima Real) para", basename(schLuI), "\n")
        runCenturyLuCR(schEqI, cemEqI, schLuI, cemLuI, wthLuI)
      } else {
        cat("     [-] Arquivo .wth não encontrado. Rodando runCenturyLuCM (Clima Médio) para", basename(schLuI), "\n")
        runCenturyLuCM(schEqI, cemEqI, schLuI, cemLuI)
      }
    }
    
    dir_lote <- paste0("result/result_lu_cm/lote_", id_lote)
    if(!dir.exists(dir_lote)){
      dir.create(dir_lote, recursive = TRUE)
    }
    
    dir_final <- paste0(dir_lote, "/simulation", p)
    if(!dir.exists(dir_final)){
      dir.create(dir_final)
    }
    
    file.copy(from = c(Sys.glob("result/result_lu_cm/*.lis")), to = dir_final, overwrite = TRUE)
    file.copy(from = c(Sys.glob("result/result_lu_cm/*.bin")), to = dir_final, overwrite = TRUE)
    
    file.remove(Sys.glob("result/result_lu_cm/*.bin"),
                Sys.glob("result/result_lu_cm/*.lis"))
  }
}

tempo_total <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
tempo_total_fmt <- sprintf("%02d:%02d:%02d", tempo_total %/% 3600, (tempo_total %% 3600) %/% 60, round(tempo_total %% 60))
cat(sprintf("\nTodas as simulações concluídas! Tempo total de execução: %s\n", tempo_total_fmt))