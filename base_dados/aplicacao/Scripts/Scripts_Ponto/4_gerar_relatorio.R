# =========================================================================
# --- GERADOR AUTOMÁTICO DE POWERPOINT ---
# =========================================================================
# Instale os pacotes se ainda não tiver:
# install.packages(c("officer", "flextable", "dplyr", "magrittr"))

library(officer)
library(flextable)
library(dplyr)
library(magrittr)

cat("\nIniciando a criação do PowerPoint...\n")

# 1. Cria um PPT em branco com o tema padrão do Office
ppt <- read_pptx()

# 2. Slide 1: Capa
ppt <- add_slide(ppt, layout = "Title Slide", master = "Office Theme")
ppt <- ph_with(ppt, value = "Resultados da Simulação Century", location = ph_location_type(type = "ctrTitle"))
ppt <- ph_with(ppt, value = "Avaliação de Estoques de Carbono e Dinâmica Temporal\n(Gerado via RStudio)", location = ph_location_type(type = "subTitle"))

# 3. Slide 2: Tabela de Ranking (Lê o CSV salvo pelo seu script)
arquivo_ranking <- "result/ranking_top10_simulacoes.csv"
if(file.exists(arquivo_ranking)) {
  ppt <- add_slide(ppt, layout = "Title and Content", master = "Office Theme")
  ppt <- ph_with(ppt, value = "Top 10 Simulações (Ranking Final)", location = ph_location_type(type = "title"))
  
  # Cria e formata a tabela
  tabela_rank <- read.csv(arquivo_ranking)
  ft <- flextable(tabela_rank) %>%
    theme_zebra() %>% # Estilo listrado para facilitar a leitura
    autofit() %>%     # Ajusta a largura das colunas
    align(align = "center", part = "all")
  
  ppt <- ph_with(ppt, value = ft, location = ph_location_type(type = "body"))
}

# --- FUNÇÃO AUXILIAR PARA INSERIR IMAGENS ---
# Isso facilita colocar várias imagens sem repetir muito código
inserir_slide_imagem <- function(doc, caminho_img, titulo_slide) {
  if(file.exists(caminho_img)) {
    doc <- add_slide(doc, layout = "Title and Content", master = "Office Theme")
    doc <- ph_with(doc, value = titulo_slide, location = ph_location_type(type = "title"))
    # Insere a imagem centralizada e ajustada
    doc <- ph_with(doc, value = external_img(caminho_img), location = ph_location_type(type = "body"))
  }
  return(doc)
}

# 4. Slide 3: Gráfico Combinado (Argila vs Carbono)
ppt <- inserir_slide_imagem(ppt, 
                            "result/graficos_argila_vs_c/argila_vs_c_COMBINADO.png", 
                            "Relação Argila vs Estoques de Carbono (Top 5 vs Observado)")

# 5. Slides 4 e 5: Dinâmica Temporal
ppt <- inserir_slide_imagem(ppt, 
                            "result/graficos_dinamica_temporal/dinamica_media_alvo.png", 
                            "Dinâmica Temporal: Comportamento Médio dos Compartimentos")

ppt <- inserir_slide_imagem(ppt, 
                            "result/graficos_dinamica_temporal/dinamica_facetas_alvo.png", 
                            "Dinâmica Temporal: Quebra por Pontos de Amostragem")

# 6. Slides das Melhores Simulações 1:1 e Outliers
# Como os nomes têm as variáveis da simulação, vamos usar list.files para pegar os primeiros gerados
graficos_1_1 <- list.files("result/graficos_1_1", pattern = "\\.png$", full.names = TRUE)
graficos_out <- list.files("result/graficos_outliers_1_1", pattern = "\\.png$", full.names = TRUE)
graficos_reg <- list.files("result/graficos_regressao_proxima", pattern = "\\.png$", full.names = TRUE)

# Pega apenas a melhor (Rank 1) para não lotar a apresentação
if(length(graficos_1_1) > 0) {
  ppt <- inserir_slide_imagem(ppt, graficos_1_1[1], "Melhor Simulação: Gráfico 1:1 (Simulado vs Mensurado)")
}
if(length(graficos_out) > 0) {
  ppt <- inserir_slide_imagem(ppt, graficos_out[1], "Melhor Simulação: Análise de Outliers")
}
if(length(graficos_reg) > 0) {
  ppt <- inserir_slide_imagem(ppt, graficos_reg[1], "Regressão Mais Próxima da Observada (Argila vs C)")
}

# 7. Salva o arquivo final
nome_arquivo_ppt <- "result/Apresentacao_Resultados_Century.pptx"

# Verifica se a pasta 'result' existe. Se não, cria a pasta automaticamente.
if(!dir.exists("result")) {
  dir.create("result", recursive = TRUE)
  cat("\nPasta 'result/' criada automaticamente.\n")
}

# Salva o PowerPoint
print(ppt, target = nome_arquivo_ppt)

cat("\n✅ SUCESSO! PowerPoint gerado em:", nome_arquivo_ppt, "\n")