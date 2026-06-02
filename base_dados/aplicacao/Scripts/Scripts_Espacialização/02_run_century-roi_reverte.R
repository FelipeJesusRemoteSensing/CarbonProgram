#' run century model

#' Packages, functions and configurations
options(scipen = 9999)

# Define local onde está o código de funções para rodar o century
source("C:/Users/anaca/Desktop/codigos_century/0_f_run_century_spatial_reverte_pasta.R")


suppressWarnings(suppressMessages(library(doBy)))
suppressWarnings(suppressMessages(library(dplyr)))
suppressWarnings(suppressMessages(library(forecast)))
suppressWarnings(suppressMessages(library(gtools)))
suppressWarnings(suppressMessages(library(lubridate)))
suppressWarnings(suppressMessages(library(parallel)))
suppressWarnings(suppressMessages(library(parameters)))
suppressWarnings(suppressMessages(library(stats)))
suppressWarnings(suppressMessages(library(tidyverse)))
suppressWarnings(suppressMessages(library(tools))) # Necessário para file_path_sans_ext

###
#' input parameters

setwd("C:/Users/anaca/Desktop/codigos_century/century")
inputDir <- "C:/Users/anaca/Desktop/codigos_century/dados/blocos"
schDir <- "C:/Users/anaca/Desktop/codigos_century/dados/agendamento"
outputDir <- "C:/Users/anaca/Desktop/codigos_century/dados/output"
pattern <- "*.csv"

ncores <- 6 # Ajuste o número de núcleos conforme a capacidade do seu computador
###

#' output
procRasterBlocks(inputDir = inputDir,
                 schDir = schDir, # Novo argumento para o diretório dos .sch
                 outputDir = outputDir,
                 pattern = pattern,
                 ncores = ncores)

#################################################################