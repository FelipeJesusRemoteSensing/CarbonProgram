library(terra)

# --- 1. CONFIGURAÇÃO ---
caminho_referencia <- "D:/Projetos-Lapig/century/reverte/rasters/fazendas/MT - AGM/lulc_mb_col10_30m/1985_lulc_AGM.tif"
pasta_precipitacao <- "C:/Users/marco/Downloads/acm_series_completa/acm_series_completa"
pasta_saida <- file.path(pasta_precipitacao, "recortados_zeros_v2")

if (!dir.exists(pasta_saida)) dir.create(pasta_saida)

# --- 2. PREPARAÇÃO DA MÁSCARA (OTIMIZAÇÃO) ---
cat("Carregando referência e criando máscara lógica...\n")
r_ref <- rast(caminho_referencia)

# Define a condição de validade baseada APENAS no LULC:
# O pixel é válido se: NÃO for NA "E" for diferente de 0
mask_valida <- !is.na(r_ref) & (r_ref != 0)

# Carrega lista de arquivos
arquivos_prec <- list.files(pasta_precipitacao, pattern = "\\.tif$", full.names = TRUE)

# --- 3. PROCESSAMENTO ---
for (arquivo in arquivos_prec) {
  
  nome_arquivo <- basename(arquivo)
  cat(paste("Processando:", nome_arquivo, "...\n"))
  
  r_chuva <- rast(arquivo)
  
  # 1. Alinha a chuva com a grade do LULC (Geometria 30m)
  r_chuva_ajustado <- resample(r_chuva, r_ref, method = "bilinear")
  
  # 2. Aplica a Lógica Condicional:
  # Onde a mask_valida for TRUE, usa a chuva. Onde for FALSE, usa 0.
  r_final <- ifel(mask_valida, r_chuva_ajustado, 0)
  
  # 3. Limpeza final:
  # A função acima garante 0 onde o LULC não tem info.
  # Mas se a CHUVA for NA dentro da área válida, isso garante que vire 0 também (opcional, mas seguro).
  r_final <- classify(r_final, cbind(NA, 0))
  
  # --- 4. SALVAR ---
  caminho_salvar <- file.path(pasta_saida, nome_arquivo)
  writeRaster(r_final, caminho_salvar, overwrite = TRUE, gdal=c("COMPRESS=LZW"))
}

cat("--- Processamento concluído! ---\n")