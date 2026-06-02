##################################################################
#' Claudinei Oliveira dos Santos
#' Biologo | Msc. Ecologia | Dr. Ciências Ambientais
#' claudineisan@pastoepixel.com
#' Isabela Nogueira de Macedo
#' Cientista Ambiental
#' belanogueira.ufg@gmail.com
#' Lapig-UFG
##################################################################

#'CENTURY Soil Organic Matter Model Environment
runCenturySpatial <- function(pixel, pixel_info){
  
  # A informação da área (ex: 'MORA1') e o diretório dos .sch são extraídos.
  area_name <- pixel_info$area_name
  sch_dir <- pixel_info$sch_dir
  
  pixel <- as.numeric(pixel)
  ncolOutput <- 12245
  
  if(is.na(pixel[3])){
    OUT <- as.numeric(rep(NA, ncolOutput))
  } else if(pixel[1] < 100){
    OUT <- as.numeric(rep(NA, ncolOutput))
  } else if(pixel[2] == 0){
    OUT <- as.numeric(rep(NA, ncolOutput))
  } else if(!length(pixel) == 2422){
    # A verificação original do comprimento é mantida.
    print("o comprimento do pixel deve ser 2422")
  } else if(length(pixel[is.na(pixel)]) > 200){
    print('muitos dados climaticos ausentes')
    OUT <- as.numeric(rep(NA, ncolOutput))
  } else{
    STi <- Sys.time()    
    
    DTym <- seq.Date(from = ymd('1958-01-01'), 
                     to = ymd('2024-12-01'), 
                     by = 'month')
    
    cellNumber <- pixel[1]
    
    ###
    #'criar arquivo wth
    climateData <- data.frame(
      t(
        rbind(forecast::na.interp(pixel[11:814])/10,
              forecast::na.interp(pixel[815:1618])/10,
              forecast::na.interp(pixel[1619:2422])/10)))
    names(climateData) <- c('prec', 'tmin', 'tmax')
    climateData$ano = year(DTym)
    climateData$mes = month(DTym)
    climateData$tmax <- ifelse(climateData$tmax <= climateData$tmin, 
                               climateData$tmin + 5,
                               climateData$tmax)
    
    ###
    # aplicar fator de correcao
    # fc_ppt <- rep(as.numeric(c(0.9683294,1.0544483,0.9938898,1.2653816,1.8879033,3.0695564,
    #                            2.4951303,1.0147354,0.8256203,0.8182074,0.8720358,0.9031940)),
    #               67)
    # fc_tmmn <- rep(as.numeric(c(-0.9905614,-0.8792807,-0.9414912,-1.1082982,-1.5116491,-1.6695965,
    #                             -1.1313333,0.1141930,0.6289298,0.2567018,-0.4630351,-1.3915789)),
    #                67)
    # fc_tmmx <- rep(as.numeric(c(-1.3098947,-1.2046667,-1.2811053,-0.8786316,-0.9053860,-1.3245088,
    #                             -1.4111579,-1.4057719,-1.6846141,-1.8041228,-1.6634211,-0.8796316)),
    #                67)
    # 
    # climateData$prec <- climateData$prec * fc_ppt
    # climateData$tmin <- climateData$tmin - fc_tmmn
    # climateData$tmax <- climateData$tmax - fc_tmmx
    # 
    ###
    #reshape data (long to wide)
    reshapeClimateData = as.data.frame(
      t(
        stats::reshape(climateData,
                       idvar = c("mes"),
                       v.names = c("prec", "tmin", "tmax"),
                       timevar = "ano", 
                       direction = "wide")
      )
    )
    names(reshapeClimateData) = 1:12
    reshapeClimateData$Var = substr(rownames(reshapeClimateData), 1, 4)
    reshapeClimateData$ano = substr(rownames(reshapeClimateData), 6, 9)
    reshapeClimateData = reshapeClimateData[-1, c(13:14,1:12)]
    
    climateData <- climateData[climateData$ano >= c(pixel[2]-3), ]
    
    # Format rows output to the same number of character
    rowsClimateData = list()
    for (i in 1:nrow(reshapeClimateData))
    {
      linha = reshapeClimateData[i,]
      v_linha = linha
      v_linha[,3:14] = sprintf("%.2f", round(v_linha[,3:14], 2))
      v_linha = as.vector(as.character(v_linha))
      for (j in 3:14) {
        v_linha[j] = ifelse(nchar(v_linha[j]) < 5, 
                            paste0(" ", v_linha[j]), 
                            v_linha[j] )
      }
      v_linha = paste(v_linha, collapse = "  ")
      rowsClimateData[[i]] = v_linha
    }
    dfClimateData = do.call("rbind", rowsClimateData)
    write.table(dfClimateData, 
                file = paste0("lu_site_", cellNumber, ".wth"), 
                row.names = FALSE, 
                col.names = FALSE, 
                sep = "  ", 
                quote = FALSE)
    ###
    #'criar arquivo sch e 100
    meanCD <- doBy::summaryBy(prec + tmin + tmax ~ mes, data = climateData)
    meanCD[,2:4] <- round(meanCD[,2:4] + 0.0000001, 4)
    names(meanCD) <- c('mes', 'prec', 'tmin', 'tmax')
    
    stdCD <- doBy::summaryBy(prec + tmin + tmax ~ mes, data = climateData, FUN = sd)
    stdCD[,2:4] <- round(stdCD[,2:4] + 0.0000001, 4)
    names(stdCD) <- c('mes', 'prec', 'tmin', 'tmax')
    
    pvw_climateData <- tibble(climateData) %>% 
      dplyr::select(mes, prec, ano) %>% 
      tidyr::pivot_wider(names_from = mes,
                         values_from = prec) %>% 
      select(-ano)
    
    skwCD <- describe_distribution(pvw_climateData)
    skwCD[,2:10] <- round(skwCD[,2:10] + 0.0000001, 4)
    skwCD[,'Skewness'] <- replace_na(skwCD[,'Skewness'], 0.0000001)
    
    ###
    #' prepare file land use site.100
    lu_site_100 <- readLines('template/Lu_site.100')
    
    #' ppt mean
    lu_site_100[3] <- gsub('0.000000', meanCD[1, 'prec'], lu_site_100[3])
    lu_site_100[4] <- gsub('0.000000', meanCD[2, 'prec'], lu_site_100[4])
    lu_site_100[5] <- gsub('0.000000', meanCD[3, 'prec'], lu_site_100[5])
    lu_site_100[6] <- gsub('0.000000', meanCD[4, 'prec'], lu_site_100[6])
    lu_site_100[7] <- gsub('0.000000', meanCD[5, 'prec'], lu_site_100[7])
    lu_site_100[8] <- gsub('0.000000', meanCD[6, 'prec'], lu_site_100[8])
    lu_site_100[9] <- gsub('0.000000', meanCD[7, 'prec'], lu_site_100[9])
    lu_site_100[10] <- gsub('0.000000', meanCD[8, 'prec'], lu_site_100[10])
    lu_site_100[11] <- gsub('0.000000', meanCD[9, 'prec'], lu_site_100[11])
    lu_site_100[12] <- gsub('0.000000', meanCD[10, 'prec'], lu_site_100[12])
    lu_site_100[13] <- gsub('0.000000', meanCD[11, 'prec'], lu_site_100[13])
    lu_site_100[14] <- gsub('0.000000', meanCD[12, 'prec'], lu_site_100[14])
    
    #' ppt sd
    lu_site_100[15] <- gsub('0.000000', stdCD[1, 'prec'], lu_site_100[15])
    lu_site_100[16] <- gsub('0.000000', stdCD[2, 'prec'], lu_site_100[16])
    lu_site_100[17] <- gsub('0.000000', stdCD[3, 'prec'], lu_site_100[17])
    lu_site_100[18] <- gsub('0.000000', stdCD[4, 'prec'], lu_site_100[18])
    lu_site_100[19] <- gsub('0.000000', stdCD[5, 'prec'], lu_site_100[19])
    lu_site_100[20] <- gsub('0.000000', stdCD[6, 'prec'], lu_site_100[20])
    lu_site_100[21] <- gsub('0.000000', stdCD[7, 'prec'], lu_site_100[21])
    lu_site_100[22] <- gsub('0.000000', stdCD[8, 'prec'], lu_site_100[22])
    lu_site_100[23] <- gsub('0.000000', stdCD[9, 'prec'], lu_site_100[23])
    lu_site_100[24] <- gsub('0.000000', stdCD[10, 'prec'], lu_site_100[24])
    lu_site_100[25] <- gsub('0.000000', stdCD[11, 'prec'], lu_site_100[25])
    lu_site_100[26] <- gsub('0.000000', stdCD[12, 'prec'], lu_site_100[26])
    
    #' ppt skw
    lu_site_100[27] <- gsub('0.000000', skwCD[1, 'Skewness'], lu_site_100[27])
    lu_site_100[28] <- gsub('0.000000', skwCD[2, 'Skewness'], lu_site_100[28])
    lu_site_100[29] <- gsub('0.000000', skwCD[3, 'Skewness'], lu_site_100[29])
    lu_site_100[30] <- gsub('0.000000', skwCD[4, 'Skewness'], lu_site_100[30])
    lu_site_100[31] <- gsub('0.000000', skwCD[5, 'Skewness'], lu_site_100[31])
    lu_site_100[32] <- gsub('0.000000', skwCD[6, 'Skewness'], lu_site_100[32])
    lu_site_100[33] <- gsub('0.000000', skwCD[7, 'Skewness'], lu_site_100[33])
    lu_site_100[34] <- gsub('0.000000', skwCD[8, 'Skewness'], lu_site_100[34])
    lu_site_100[35] <- gsub('0.000000', skwCD[9, 'Skewness'], lu_site_100[35])
    lu_site_100[36] <- gsub('0.000000', skwCD[10, 'Skewness'], lu_site_100[36])
    lu_site_100[37] <- gsub('0.000000', skwCD[11, 'Skewness'], lu_site_100[37])
    lu_site_100[38] <- gsub('0.000000', skwCD[12, 'Skewness'], lu_site_100[38])
    
    #' tmmn
    lu_site_100[39] <- gsub('0.000000', meanCD[1, 'tmin'], lu_site_100[39])
    lu_site_100[40] <- gsub('0.000000', meanCD[2, 'tmin'], lu_site_100[40])
    lu_site_100[41] <- gsub('0.000000', meanCD[3, 'tmin'], lu_site_100[41])
    lu_site_100[42] <- gsub('0.000000', meanCD[4, 'tmin'], lu_site_100[42])
    lu_site_100[43] <- gsub('0.000000', meanCD[5, 'tmin'], lu_site_100[43])
    lu_site_100[44] <- gsub('0.000000', meanCD[6, 'tmin'], lu_site_100[44])
    lu_site_100[45] <- gsub('0.000000', meanCD[7, 'tmin'], lu_site_100[45])
    lu_site_100[46] <- gsub('0.000000', meanCD[8, 'tmin'], lu_site_100[46])
    lu_site_100[47] <- gsub('0.000000', meanCD[9, 'tmin'], lu_site_100[47])
    lu_site_100[48] <- gsub('0.000000', meanCD[10, 'tmin'], lu_site_100[48])
    lu_site_100[49] <- gsub('0.000000', meanCD[11, 'tmin'], lu_site_100[49])
    lu_site_100[50] <- gsub('0.000000', meanCD[12, 'tmin'], lu_site_100[50])
    
    #' tmmx
    lu_site_100[51] <- gsub('0.000000', meanCD[1, 'tmax'], lu_site_100[51])
    lu_site_100[52] <- gsub('0.000000', meanCD[2, 'tmax'], lu_site_100[52])
    lu_site_100[53] <- gsub('0.000000', meanCD[3, 'tmax'], lu_site_100[53])
    lu_site_100[54] <- gsub('0.000000', meanCD[4, 'tmax'], lu_site_100[54])
    lu_site_100[55] <- gsub('0.000000', meanCD[5, 'tmax'], lu_site_100[55])
    lu_site_100[56] <- gsub('0.000000', meanCD[6, 'tmax'], lu_site_100[56])
    lu_site_100[57] <- gsub('0.000000', meanCD[7, 'tmax'], lu_site_100[57])
    lu_site_100[58] <- gsub('0.000000', meanCD[8, 'tmax'], lu_site_100[58])
    lu_site_100[59] <- gsub('0.000000', meanCD[9, 'tmax'], lu_site_100[59])
    lu_site_100[60] <- gsub('0.000000', meanCD[10, 'tmax'], lu_site_100[60])
    lu_site_100[61] <- gsub('0.000000', meanCD[11, 'tmax'], lu_site_100[61])
    lu_site_100[62] <- gsub('0.000000', meanCD[12, 'tmax'], lu_site_100[62])
    
    #' soil
    soilData <- pixel[6:10]
    soilData[1:3] <- round((soilData[1:3]/1000) + 0.00001, 5)
    soilData[4] <- round((soilData[4]) + 0.00001, 5)
    soilData[5] <- round((soilData[5]) + 0.00001, 5)
    
    lu_site_100[68] <- gsub('0.000000', soilData[1], lu_site_100[68])
    lu_site_100[69] <- gsub('0.000000', soilData[2], lu_site_100[69])
    lu_site_100[70] <- gsub('0.000000', soilData[3], lu_site_100[70])
    lu_site_100[72] <- gsub('1.000000', soilData[4], lu_site_100[72])
    lu_site_100[101] <- gsub('0.000000', soilData[5], lu_site_100[101])
    
    lu_site_100_name <- paste0("lu_site_", cellNumber, ".100")
    write.table(lu_site_100,  
                file = lu_site_100_name, 
                quote = FALSE, 
                row.names = FALSE, 
                col.names = FALSE)
    
    #'prepare file land use site.sch
    # Constrói o caminho para o arquivo .sch específico da área
    source_sch_file <- file.path(sch_dir, paste0("Lu_", area_name, ".sch"))
    
    if (!file.exists(source_sch_file)) {
      stop(paste("Arquivo de agendamento não encontrado:", source_sch_file))
    }
    
    # Lê o conteúdo do arquivo .sch específico da área
    lu_site_sch <- readLines(source_sch_file)
    lu_site_sch_name <- paste0("lu_site_", cellNumber, ".sch")
    
    # ATENÇÃO: As duas linhas abaixo são essenciais. Elas atualizam o arquivo .sch
    # para que ele aponte para os arquivos .100 e .wth corretos para ESTE PIXEL.
    # A primeira referência (ex: 'lu_site.100') no gsub pode precisar de ajuste
    # para corresponder ao que está dentro dos seus arquivos Lu_MORA*.sch.
    lu_site_sch[3] <- gsub('lu_site.100', lu_site_100_name, lu_site_sch[3])
    
    lu_site_sch[25] <- gsub('lu_site.wth', 
                            paste0("lu_site_", cellNumber, ".wth"), 
                            lu_site_sch[25])
    
    # Os blocos que alteravam o ano de conversão foram removidos, conforme solicitado.
    
    write.table(lu_site_sch,  
                file = lu_site_sch_name, 
                quote = FALSE, 
                row.names = FALSE, 
                col.names = FALSE)
    
    ###
    #'prepare file equilibrio site.100 e sch
    eq_site_100 <- lu_site_100
    eq_site_100_name <- paste0("eq_site_", cellNumber, ".100")
    
    write.table(eq_site_100,  
                file = eq_site_100_name, 
                quote = FALSE, 
                row.names = FALSE, 
                col.names = FALSE)
    
    #'prepare file equilibrio site.100 e sch
    eq_site_sch <-  readLines('template/Eq_site.sch')
    eq_site_sch[3] <- gsub('eq_site.100', eq_site_100_name, eq_site_sch[3])
    eq_site_sch_name <- paste0("eq_site_", cellNumber, ".sch")
    
    write.table(eq_site_sch,  
                file = eq_site_sch_name, 
                quote = FALSE, 
                row.names = FALSE, 
                col.names = FALSE)
    
    #'rodar o modelo century
    equilibrio <- paste0('century -s eq_site_', 
                         cellNumber, 
                         ' -n eq_site_', 
                         cellNumber)
    system(equilibrio)
    
    land_use <- paste0('century -s lu_site_', 
                       cellNumber, 
                       ' -n result/lu_site_', 
                       cellNumber, 
                       ' -e eq_site_', 
                       cellNumber)
    system(land_use)
    
    lis_file <- paste0('list100 result/lu_site_', 
                       cellNumber, 
                       ' result/lu_site_', 
                       cellNumber, ' output.txt')
    system(lis_file)
    
    ###
    #' variaveis a serem utilizadas
    #' checar se o arquivo tem 816 linhas;
    lis_lu <- read.table(paste0("result/lu_site_", cellNumber, ".lis"), h = T)
    lis_lu <- lis_lu[lis_lu$time > 1958.00 & lis_lu$time < 2026.01, ]
    lis_lu <- lis_lu[-nrow(lis_lu), ]
    
    if(nrow(lis_lu) < 816){ 
      VecNA <- as.numeric(rep(NA, (816 - nrow(lis_lu))))
      rlwodc <- as.numeric(c(VecNA, lis_lu$rlwodc))
      rleavc <- as.numeric(c(VecNA, lis_lu$rleavc))
      somsc <- as.numeric(c(VecNA, lis_lu$somsc))
      aglivc <- as.numeric(c(VecNA, lis_lu$aglivc))
      bglivc <- as.numeric(c(VecNA, lis_lu$bglivc))
      stdedc <- as.numeric(c(VecNA, lis_lu$stdedc))
      som2c <- as.numeric(c(VecNA, lis_lu$som2c))
      som3c <- as.numeric(c(VecNA, lis_lu$som3c))
      crootc <- as.numeric(c(VecNA, lis_lu$crootc))
      fbrchc <- as.numeric(c(VecNA, lis_lu$fbrchc))
      frootc <- as.numeric(c(VecNA, lis_lu$frootc))
      shrema <- as.numeric(c(VecNA, lis_lu$shrema))
      sdrema <- as.numeric(c(VecNA, lis_lu$sdrema))
      cgrain <- as.numeric(c(VecNA, lis_lu$cgrain))
      som1c2 <- as.numeric(c(VecNA, lis_lu$som1c.2.))
    } else if(nrow(lis_lu) > 816){ 
      lis_lu <- lis_lu[1:816,]
      rlwodc <- as.numeric(lis_lu$rlwodc)
      rleavc <- as.numeric(lis_lu$rleavc)
      somsc <- as.numeric(lis_lu$somsc)
      aglivc <- as.numeric(lis_lu$aglivc)
      bglivc <- as.numeric(lis_lu$bglivc)
      stdedc <- as.numeric(lis_lu$stdedc)
      som2c <- as.numeric(lis_lu$som2c)
      som3c <- as.numeric(lis_lu$som3c)
      crootc <- as.numeric(lis_lu$crootc)
      fbrchc <- as.numeric(lis_lu$fbrchc)
      frootc <- as.numeric(lis_lu$frootc)
      shrema <- as.numeric(lis_lu$shrema)
      sdrema <- as.numeric(lis_lu$sdrema)
      cgrain <- as.numeric(lis_lu$cgrain)
      som1c2 <- as.numeric(lis_lu$som1c.2.)
    } else {
      rlwodc <- as.numeric(lis_lu$rlwodc)
      rleavc <- as.numeric(lis_lu$rleavc)
      somsc <- as.numeric(lis_lu$somsc)
      aglivc <- as.numeric(lis_lu$aglivc)
      bglivc <- as.numeric(lis_lu$bglivc)
      stdedc <- as.numeric(lis_lu$stdedc)
      som2c <- as.numeric(lis_lu$som2c)
      som3c <- as.numeric(lis_lu$som3c)
      crootc <- as.numeric(lis_lu$crootc)
      fbrchc <- as.numeric(lis_lu$fbrchc)
      frootc <- as.numeric(lis_lu$frootc)
      shrema <- as.numeric(lis_lu$shrema)
      sdrema <- as.numeric(lis_lu$sdrema)
      cgrain <- as.numeric(lis_lu$cgrain)
      som1c2 <- as.numeric(lis_lu$som1c.2.)
    }
    
    OUT <- as.numeric(c(pixel[c(1:5)], rlwodc, rleavc, somsc, aglivc, bglivc, stdedc, som2c,
                        som3c, crootc, fbrchc, frootc, shrema, sdrema, cgrain, som1c2))
    
    ###
    #' remove files
    Sys.sleep(1)
    file.remove( paste0("eq_site_", cellNumber, ".100"),
                 paste0("eq_site_", cellNumber, ".sch"),
                 paste0("eq_site_", cellNumber, ".bin"),
                 paste0("lu_site_", cellNumber, ".sch"),
                 paste0("lu_site_", cellNumber, ".100"),
                 paste0("result/lu_site_", cellNumber, ".bin"),
                 paste0("result/lu_site_", cellNumber, ".lis"),
                 paste0("lu_site_", cellNumber, ".wth")
    )
    print(Sys.time() - STi)
  }
  
  return(OUT)
}


##################################################################

procRasterBlocks <- function(inputDir, schDir, outputDir, pattern, ncores = NULL) {
  STTot <- Sys.time()
  
  ncores <- ifelse(is.null(ncores), detectCores(), ncores)
  print(paste("Ncores =", ncores))
  
  clusterPool <- makeCluster(ncores)
  clusterEvalQ(clusterPool, {
    require(doBy)
    require(dplyr)
    require(forecast)
    require(lubridate)
    require(tidyr)
    require(parameters)
    require(tools) 
  })
  
  list_of_files <- mixedsort(Sys.glob(file.path(inputDir, pattern = pattern)))
  
  for (file_path in list_of_files){
    STBloco <-  Sys.time()
    
    # Extrai o nome base (ex: 'MORA1')
    area_name <- tools::file_path_sans_ext(basename(file_path))
    
    sch_file_to_use <- file.path(schDir, paste0("Lu_", area_name, ".sch"))
    print(paste(">>> PROCESSANDO ÁREA:", area_name))
    print(paste("   1. Lendo CSV (Bloco):", file_path))
    print(paste("   2. Usando SCH       :", sch_file_to_use))
    
    blockData <- read.csv(file_path)
    
    # Filtros de qualidade
    blockData <- blockData[!is.na(blockData$bkrd), ]
    blockData <- blockData[!blockData$`X2024.12.01.2`%in% 0, ]
    print(dim(blockData))
    
    if(nrow(blockData) == 0){
      
      print(paste('No valid pixels in this area:', area_name))
      
    } else {
      
      ###
      # Configuração de datas
      DTym <- seq.Date(from = ymd('1958-01-01'),
                       to = ymd('2025-12-01'),
                       by = 'month')[-817] 
      
      colNames <- c(paste0("rlwodc_", DTym),
                    paste0("rleavc_", DTym),
                    paste0("somsc_", DTym),
                    paste0("aglivc_", DTym),
                    paste0("bglivc_", DTym),
                    paste0("stdedc_", DTym),
                    paste0("som2c_", DTym),
                    paste0("som3c_", DTym),
                    paste0("crootc_", DTym),
                    paste0("fbrchc_", DTym),
                    paste0("frootc_", DTym),
                    paste0("shrema_", DTym),
                    paste0("sdrema_", DTym),
                    paste0("cgrain_", DTym),
                    paste0("som1c2_", DTym))
      
      centurySpatial <- blockData[ ,1:5]
      centurySpatial[ , 6:(length(colNames)+5)] <- NA
      colnames(centurySpatial)[6:(length(colNames)+5)] <- colNames
      
      # Cria lista de info auxiliar
      pixel_info <- list(area_name = area_name, sch_dir = schDir)
      
      # Exporta para o cluster
      clusterExport(clusterPool, varlist = c("runCenturySpatial", "pixel_info"), envir = environment())
      
      # Execução paralela
      result_matrix <- t(parApply(cl = clusterPool, blockData, 1, function(row) runCenturySpatial(row, pixel_info)))
      
      centurySpatial[ ,1:ncol(centurySpatial)] <- as.data.frame(result_matrix)
      
      ###
      # Write results (CRIAÇÃO DE PASTA)
      ###
      area_output_folder <- file.path(outputDir, area_name)
      
      if (!dir.exists(area_output_folder)) {
        dir.create(area_output_folder, recursive = TRUE)
      }
      
      outputfile <- file.path(area_output_folder, paste0('centurySpatial_block_', area_name, '.csv'))
      
      write.csv(centurySpatial, outputfile, row.names = FALSE)
      
      totSTBloco <- paste0("Time to execute area = ", area_name, " = ", Sys.time() - STBloco)
      print(totSTBloco)
      
      rm(centurySpatial, blockData, result_matrix)
      gc(reset = TRUE)
    }
  }
  print(paste0("Time to execute all areas = ", Sys.time() - STTot))
  stopCluster(clusterPool)
}