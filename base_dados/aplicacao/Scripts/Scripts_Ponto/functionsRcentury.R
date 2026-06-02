#####################################################################
#####################################################################
#'CENTURY Soil Organic Matter Model Environment
#'Rodar Equilibrio para ponto
#'schEq = agendamento equilibrio
#'schLu = agendamento land use
#'cemEq = arquivo *.100 equilibrio
#'cemLu = arquivo *.100 land use
#'lisEq = arquivo *.lis equilibrio
#'lisLu = arquivo *.lis land use
#'binEq = arquivo *.bin equilibrio
#'binLu = arquivo *.bin land use

#####################################################################
#####################################################################

#Rodar century para o land use com clima medio
runCenturyLuCM <- function(schEqI, cemEqI, schLuI, cemLu){
  pathOr <- getwd()

  file.copy(from = schEqI, to = "century")
  file.rename(gsub("ponto/", "century/", schEqI), "century/eq_site.sch")

  file.copy(from = cemEqI, to = "century")
  file.rename(gsub("ponto/", "century/", cemEqI), "century/eq_site.100")

  file.copy(from = schLuI, to = "century")
  file.rename(gsub("ponto/", "century/", schLuI), "century/lu_site.sch")

  file.copy(from = cemLuI, to = "century")
  file.rename(gsub("ponto/", "century/", cemLuI), "century/lu_site.100")
 
  setwd("century")
  system('century -s eq_site -n eq_site')
  system('century -s lu_site -n lu_site -e eq_site')
  system('list100 eq_site eq_site output.txt')
  system('list100 lu_site lu_site output.txt')
  
  setwd(pathOr)
  file.copy(from = "century/lu_site.lis", to = lisLu[i], overwrite = TRUE)
  file.copy(from = "century/lu_site.bin", to = binLu[i], overwrite = TRUE)
  
  file.copy(from = "century/eq_site.lis", to = lisEq[i], overwrite = TRUE)
  file.copy(from = "century/eq_site.bin", to = binEq[i], overwrite = TRUE)
  
  file.remove("century/eq_site.sch",
              "century/eq_site.100",
              "century/eq_site.bin",
              "century/eq_site.lis",
              "century/lu_site.sch",
              "century/lu_site.100",
              "century/lu_site.lis",
              "century/lu_site.bin")
}

###
###
###

#Rodar century para o land use com clima real
runCenturyLuCR <- function(schEqI, cemEqI, schLuI, cemLuI, wthLuI){
  pathOr <- getwd()
  
  file.copy(from = schEqI, to = "century")
  file.rename(gsub("ponto/", "century/", schEqI), "century/eq_site.sch")
  
  file.copy(from = cemEqI, to = "century")
  file.rename(gsub("ponto/", "century/", cemEqI), "century/eq_site.100")
  
  file.copy(from = schLuI, to = "century")
  file.rename(gsub("ponto/", "century/", schLuI), "century/lu_site.sch")
  
  file.copy(from = cemLuI, to = "century")
  file.rename(gsub("ponto/", "century/", cemLuI), "century/lu_site.100")
  
  file.copy(from = wthLuI, to = "century")
  file.rename(gsub("ponto/", "century/", wthLuI), "century/lu_site.wth")
  
  setwd("century")
  system('century -s eq_site -n eq_site')
  system('century -s lu_site -n lu_site -e eq_site')
  system('list100 eq_site eq_site output.txt')
  system('list100 lu_site lu_site output.txt')
  
  setwd(pathOr)
  file.copy(from = "century/lu_site.lis", to = lisLu[i], overwrite = TRUE)
  file.copy(from = "century/lu_site.bin", to = binLu[i], overwrite = TRUE)
  
  file.copy(from = "century/eq_site.lis", to = lisEq[i], overwrite = TRUE)
  file.copy(from = "century/eq_site.bin", to = binEq[i], overwrite = TRUE)
  
  file.remove("century/eq_site.sch",
              "century/eq_site.100",
              "century/eq_site.bin",
              "century/eq_site.lis",
              "century/lu_site.sch",
              "century/lu_site.100",
              "century/lu_site.lis",
              "century/lu_site.bin",
              "century/lu_site.wth")
}

###
###
###

#Rodar century para o equilibrio
runCenturyEquilibrio <- function(schEqI, cemEqI){
  pathOr <- getwd()
  
  file.copy(from = schEqI, to = "century")
  file.rename(gsub("ponto/", "century/", schEqI), "century/eq_site.sch")
  
  file.copy(from = cemEqI, to = "century")
  file.rename(gsub("ponto/", "century/", cemEqI), "century/eq_site.100")
  
  setwd("century")
  system('century -s eq_site -n eq_site')
  system('list100 eq_site eq_site output.txt')

  setwd(pathOr)
  file.copy(from = "century/eq_site.lis", to = lisEq[i], overwrite = TRUE)
  file.copy(from = "century/eq_site.bin", to = binEq[i], overwrite = TRUE)
  
  file.remove("century/eq_site.sch",
              "century/eq_site.100",
              "century/eq_site.bin",
              "century/eq_site.lis")
}

#####################################################################
#####################################################################

#'alterar parâmetros nos arquivos *.100 por blocos de linhas
changFILES <- function(changeFrom, changeTo, l1, l2){
  newFile <- readLines(changeFrom)
  newFile[l1:l2] <- changeTo
  write.table(newFile, changeFrom, quote = FALSE, row.names = FALSE, col.names = FALSE)
}

###
###
###

#'alterar parâmetros nos arquivos 100 por linhas
changFILES_linhaI <- function(changeFrom, changeTo, linha){
  newFile <- readLines(changeFrom)
  newFile[linha] <- changeTo
  write.table(newFile, changeFrom, quote = FALSE, row.names = FALSE, col.names = FALSE)
}

#####################################################################
#####################################################################