options(scipen = 9999)

library(tidyverse)
library(stringr)
library(ggplot2)
library(ggrepel)

# =========================================================================
# --- 0. CONFIGURAÇÕES GERAIS ---
# =========================================================================



# Defina aqui o uso para carregar os arquivos automaticamente (ex: "reverte", "pastagem_literatura", "soja_literatura" e "vegetacao_literatura")
dados_observados <- "pastagem_literatura"

# Defina aqui os pontos que deseja ignorar em TODA a análise.
# Para parar de ignorar, basta comentar a linha abaixo com '#' ou deixá-la vazia: c()
pontos_ignorar <- c("CDORC021")

# Defina aqui uma variação ESPECÍFICA para forçar a geração de todos os gráficos apenas para ela.
#combinacao_especifica <- lote_1_sim_1
combinacao_especifica <- NULL #Sem restrição

# Defina aqui o ano padrão para os dados observados caso o CSV não possua a coluna de Amostragem/Ano
ano_generico_observado <- 2017

# Defina aqui o prefixo dos gráficos (ex: "VALIDAÇÃO", "CALIBRAÇÃO", "AVALIAÇÃO").
#prefixo_titulo <- "AVALIAÇÃO"

if(!exists("prefixo_titulo") || is.null(prefixo_titulo) || prefixo_titulo == "") {
  prefixo_titulo <- ""
}

# =========================================================================
# --- 1. LEITURA E LIMPEZA AVANÇADA ---
# =========================================================================

result_century <- read_csv('result/resultados_century_simulations.csv', show_col_types = FALSE)

# Cria o ID único baseado nas pastas para diferenciar as simulações corretamente
result_century <- result_century %>%
  mutate(sim_id = paste(lote_folder, sim_folder, sep = "_"))

arquivo_obs <- paste0("reference_values/somsc_", dados_observados, "_observado.csv")

# 1.1 Tenta ler com ponto-e-vírgula (;). Se der só 1 coluna, lê com vírgula (,)
df_observado <- read_delim(arquivo_obs, delim = ";", col_names = FALSE, show_col_types = FALSE)
if(ncol(df_observado) == 1) {
  df_observado <- read_csv(arquivo_obs, col_names = FALSE, show_col_types = FALSE)
}

# 1.2 Nomeia as colunas de acordo com o que foi encontrado
if(ncol(df_observado) >= 3) {
  names(df_observado)[1:3] <- c("ponto_id", "valor_string", "Amostragem")
} else if(ncol(df_observado) >= 2) {
  names(df_observado)[1:2] <- c("ponto_id", "valor_string")
  df_observado <- df_observado %>% mutate(Amostragem = ano_generico_observado)
  cat("\nAVISO: Coluna de Amostragem ausente. Assumindo o ano de", ano_generico_observado, "para todos os pontos.\n")
} else {
  stop("ERRO FATAL: O arquivo CSV tem apenas 1 coluna! Verifique como o arquivo foi salvo no Excel.")
}

# 1.3 Limpeza pesada (Remove cabeçalhos acidentais, espaços, letras e converte)
df_observado <- df_observado %>%
  filter(!str_detect(tolower(ponto_id), "ponto|id")) %>%
  mutate(
    valor_limpo = str_remove_all(as.character(valor_string), "[^0-9.,]"),
    valor_limpo = str_replace(valor_limpo, ",", "."),
    valor_obs = as.numeric(valor_limpo),
    Amostragem = suppressWarnings(as.numeric(Amostragem)),
    Amostragem = replace_na(Amostragem, ano_generico_observado)
  )

na_gerados <- df_observado %>% filter(is.na(valor_obs))
if(nrow(na_gerados) > 0) {
  cat("\n[!] ALERTA: As seguintes linhas não tinham números válidos e foram ignoradas:\n")
  print(na_gerados)
}

df_observado <- df_observado %>% filter(!is.na(valor_obs))

cat("\n>>> TOTAL DE PONTOS DE CAMPO CARREGADOS COM SUCESSO:", nrow(df_observado), "<<<\n")

if(exists("pontos_ignorar") && length(pontos_ignorar) > 0) {
  result_century <- result_century %>% filter(!ponto %in% pontos_ignorar)
  df_observado <- df_observado %>% filter(!ponto_id %in% pontos_ignorar)
  cat("\nAVISO: Os seguintes pontos foram IGNORADOS na análise:", paste(pontos_ignorar, collapse = ", "), "\n")
}


# =========================================================================
# --- 2. PREPARAÇÃO E CRUZAMENTO ---
# =========================================================================

df_final <- result_century %>%
  mutate(ano = round(time, 0)) %>%
  inner_join(df_observado, by = c("ponto" = "ponto_id", "ano" = "Amostragem")) %>%
  group_by(ponto, lote_folder, sim_folder, sim_id, obs, valor_obs, ano) %>%
  summarise(somsc = mean(somsc, na.rm = TRUE), .groups = 'drop') %>%
  mutate(somsc = somsc / 100)


# =========================================================================
# --- 3. CÁLCULO ESTATÍSTICO GERAL COM NSE ---
# =========================================================================

metricas <- df_final %>%
  group_by(lote_folder, sim_folder, sim_id, obs) %>%
  summarise(
    n = n(),
    r2 = if(sum(!is.na(somsc) & !is.na(valor_obs)) > 1) {
      round(cor(somsc, valor_obs, use = "complete.obs")^2, 4)
    } else { NA_real_ },
    nse = if(sum(!is.na(somsc) & !is.na(valor_obs)) > 1 && var(valor_obs, na.rm=TRUE) != 0) {
      round(1 - (sum((somsc - valor_obs)^2, na.rm = TRUE) / sum((valor_obs - mean(valor_obs, na.rm = TRUE))^2, na.rm = TRUE)), 4)
    } else { NA_real_ },
    M = round(mean(somsc - valor_obs, na.rm = TRUE), 4),
    dentro_25pct = sum(somsc >= (valor_obs * 0.75) & somsc <= (valor_obs * 1.25)),
    pct_acerto = round((dentro_25pct / n) * 100, 2),
    rmse = round(sqrt(mean((somsc - valor_obs)^2, na.rm = TRUE)), 4),
    .groups = 'drop'
  )

# =========================================================================
# --- 4. RANKING TOP 10 COMBINAÇÕES (OU SELEÇÃO ESPECÍFICA) ---
# =========================================================================

norm_01 <- function(x, invert = FALSE) {
  min_x <- min(x, na.rm = TRUE)
  max_x <- max(x, na.rm = TRUE)
  if(max_x == min_x) return(rep(0.5, length(x))) 
  res <- (x - min_x) / (max_x - min_x)
  if(invert) return(1 - res) else return(res)
}

metricas <- metricas %>%
  mutate(
    score_rmse = norm_01(rmse, invert = TRUE),
    score_nse = norm_01(nse, invert = FALSE),
    score_acerto = norm_01(pct_acerto, invert = FALSE),
    score_final = round(score_rmse + score_nse + score_acerto, 4)
  )

# LÓGICA DE SELEÇÃO INSERIDA AQUI (AGORA BASEADA NO SIM_ID)
if (!is.null(combinacao_especifica) && combinacao_especifica != "") {
  cat("\n========================================================")
  cat("\n>>> MODO DE SELEÇÃO ATIVADO: Gerando gráficos apenas para:")
  cat("\n", combinacao_especifica)
  cat("\n========================================================\n")
  
  top_10_combinacoes <- metricas %>% filter(sim_id == combinacao_especifica)
  
  if(nrow(top_10_combinacoes) == 0) {
    stop("ERRO: A combinação especificada não foi encontrada nos dados. Verifique a grafia exata.")
  }
} else {
  top_10_combinacoes <- metricas %>%
    arrange(desc(score_final)) %>%
    slice_head(n = 10)
  
  print("========================================================")
  print("TOP 10 MELHORES SIMULAÇÕES (Rankeado por Score)")
  print("========================================================")
}

tabela_print <- top_10_combinacoes %>% 
  select(Simulacao = sim_id, Obs = obs, Score = score_final, R2 = r2, NSE = nse, RMSE = rmse, Acerto_pct = pct_acerto)

# --- NOVO TRECHO DE PRINT NO CONSOLE ---
if (!is.null(combinacao_especifica) && combinacao_especifica != "") {
  cat("\n======================================================================================\n")
  cat("🎯 MÉTRICAS GERAIS DA SIMULAÇÃO ESPECÍFICA (", combinacao_especifica, ")\n")
  cat("======================================================================================\n")
  print(as.data.frame(tabela_print), row.names = FALSE)
  cat("======================================================================================\n\n")
} else {
  print(as.data.frame(tabela_print), row.names = FALSE)
}
# ---------------------------------------

if(!dir.exists("result")) dir.create("result")
# Só sobrescreve o ranking geral se não estiver no modo específico
if (is.null(combinacao_especifica) || combinacao_especifica == "") {
  write.csv(top_10_combinacoes, "result/ranking_top10_simulacoes.csv", row.names = FALSE)
}

# =========================================================================
# --- 5. GRÁFICOS 1:1 ---
# =========================================================================

print("Gerando gráficos 1:1...")
if(!dir.exists("result/graficos_1_1")) dir.create("result/graficos_1_1", recursive = TRUE)

for(i in 1:nrow(top_10_combinacoes)) {
  
  var_atual <- top_10_combinacoes[i, ]
  nome_sim <- var_atual$sim_id
  rank_num <- ifelse(!is.null(combinacao_especifica) && combinacao_especifica != "", "Alvo Específico", paste("Rank", i))
  
  # Condicional para omitir o texto padrão do mutfiles do subtitulo
  texto_obs_sub <- ifelse(!is.na(var_atual$obs) & var_atual$obs != "parametros alterados no multfiles", paste0(" | Obs: ", var_atual$obs), "")
  subtitulo_plot <- paste0("Simulação: ", nome_sim, texto_obs_sub, " | Score: ", round(var_atual$score_final, 2))
  
  dados_plot <- df_final %>% filter(sim_id == nome_sim)
  
  modelo_lm <- lm(somsc ~ valor_obs, data = dados_plot)
  sumario <- summary(modelo_lm)
  
  intercepto <- format(round(coef(modelo_lm)[1], 4), nsmall=4)
  inclinacao <- format(round(coef(modelo_lm)[2], 4), nsmall=4)
  
  r2_val <- format(round(sumario$r.squared, 4), nsmall=4)
  nse_val <- format(round(var_atual$nse, 4), nsmall=4) 
  p_val  <- format.pval(coef(sumario)[2, 4], digits = 4, eps = 0.0001)
  n_val  <- nrow(dados_plot)
  
  dentro_25 <- sum(dados_plot$somsc >= (dados_plot$valor_obs * 0.75) & 
                     dados_plot$somsc <= (dados_plot$valor_obs * 1.25))
  
  max_val <- max(c(dados_plot$valor_obs, dados_plot$somsc), na.rm = TRUE) * 1.1 
  min_val <- 0 
  
  texto_stats <- paste0(
    "y = ", inclinacao, "x + ", intercepto, "\n",
    "R² = ", r2_val, "\n",
    "NSE = ", nse_val, "\n",
    "p = ", p_val, "\n",
    "n = ", n_val
  )
  
  texto_vermelho <- paste0("± 25% = ", dentro_25)
  
  g <- ggplot(dados_plot, aes(x = valor_obs, y = somsc)) +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "black", linewidth = 0.8) +
    geom_smooth(method = "lm", se = FALSE, color = "red", linewidth = 0.8) +
    geom_point(color = "blue", size = 3, alpha = 0.8) +
    annotate("text", x = min_val + (max_val * 0.05), y = max_val * 0.95, 
             label = texto_stats, hjust = 0, vjust = 1, size = 3.5) +
    annotate("text", x = min_val + (max_val * 0.05), y = max_val * 0.60, 
             label = texto_vermelho, hjust = 0, vjust = 1, 
             fontface = "bold", color = "red", size = 3.5) +
    labs(
      title = paste0(prefixo_titulo, ": ", rank_num),
      subtitle = subtitulo_plot,
      x = expression(bold("Mensurado (Mg C ha"^-1*")")),
      y = expression(bold("Simulado (Mg C ha"^-1*")"))
    ) +
    scale_x_continuous(limits = c(min_val, max_val)) +
    scale_y_continuous(limits = c(min_val, max_val)) +
    coord_fixed(ratio = 1) + 
    theme_bw() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 12),
      plot.subtitle = element_text(hjust = 0.5, size = 10),
      axis.title = element_text(size = 10),
      panel.grid.minor = element_blank()
    )
  
  nome_limpo <- gsub("[^A-Za-z0-9]", "_", nome_sim) 
  ggsave(filename = paste0("result/graficos_1_1/plot_1_1_rank_", i, "_", nome_limpo, ".png"), 
         plot = g, width = 5, height = 5, dpi = 300)
}


# =========================================================================
# --- 6. GRÁFICOS OUTLIERS 1:1 ---
# =========================================================================

dir.create("result/graficos_outliers_1_1", showWarnings = FALSE)
cat("\nIniciando geração de gráficos de Outliers 1:1...\n")

for(i in 1:nrow(top_10_combinacoes)) {
  
  var_atual <- top_10_combinacoes[i, ]
  nome_sim <- var_atual$sim_id
  rank_num <- ifelse(!is.null(combinacao_especifica) && combinacao_especifica != "", "Alvo Específico", paste("Rank", i))
  
  texto_obs_sub <- ifelse(!is.na(var_atual$obs) & var_atual$obs != "parametros alterados no multfiles", paste0(" | Obs: ", var_atual$obs), "")
  subtitulo_plot <- paste0("Simulação: ", nome_sim, texto_obs_sub)
  
  dados_plot <- df_final %>% filter(sim_id == nome_sim)
  modelo_lm_temp <- lm(somsc ~ valor_obs, data = dados_plot)
  
  dados_outliers <- dados_plot %>%
    mutate(
      residuo_padronizado = rstandard(modelo_lm_temp),
      is_outlier_stat = abs(residuo_padronizado) > 2
    )
  
  max_eixo <- max(c(dados_outliers$valor_obs, dados_outliers$somsc), na.rm = TRUE) * 1.1
  min_eixo <- 0 
  
  g_out <- ggplot(dados_outliers, aes(x = valor_obs, y = somsc)) +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50") +
    geom_point(data = subset(dados_outliers, !is_outlier_stat),
               color = "dodgerblue3", size = 2.5, alpha = 0.6) +
    geom_point(data = subset(dados_outliers, is_outlier_stat),
               color = "red2", size = 4, shape = 18) + 
    ggrepel::geom_text_repel(
      data = subset(dados_outliers, is_outlier_stat),
      aes(label = ponto),
      color = "red2", fontface = "bold", size = 3.5,
      box.padding = 0.5, point.padding = 0.3, max.overlaps = Inf, seed = 123 
    ) +
    labs(
      title = paste0("Outliers (Z-score > 2): ", rank_num),
      subtitle = subtitulo_plot,
      x = expression(bold("Mensurado (Mg C ha"^-1*")")),
      y = expression(bold("Simulado (Mg C ha"^-1*")"))
    ) +
    theme_bw() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 12),
      plot.subtitle = element_text(hjust = 0.5, size = 10),
      panel.grid.minor = element_blank()
    ) +
    scale_x_continuous(limits = c(min_eixo, max_eixo), expand = c(0,0)) +
    scale_y_continuous(limits = c(min_eixo, max_eixo), expand = c(0,0)) +
    coord_fixed(ratio = 1)
  
  nome_limpo <- gsub("[^A-Za-z0-9]", "_", nome_sim) 
  nome_arquivo <- paste0("result/graficos_outliers_1_1/outlier_1_1_rank_", i, "_", nome_limpo, ".png")
  ggsave(filename = nome_arquivo, plot = g_out, width = 6, height = 6, dpi = 300)
}


# =========================================================================
# --- 7. GRÁFICOS ARGILA VS ESTOQUES DE C ---
# =========================================================================

cat("\nIniciando geração de gráficos: Argila vs Estoques de C...\n")
dir.create("result/graficos_argila_vs_c", showWarnings = FALSE)
arquivo_argila <- paste0("complementares/granulometria/Relacao_IDs_", dados_observados, ".csv")

df_argila <- read_delim(arquivo_argila, delim = "\t", show_col_types = FALSE) 

if(ncol(df_argila) == 1) {
  df_argila <- read_csv(arquivo_argila, show_col_types = FALSE)
}

df_argila <- df_argila %>%
  select(ID, CLAY) %>%
  mutate(
    CLAY_pct = CLAY * 100,
    ID_join = str_trim(str_replace_all(ID, "Lu_|Lu |Eq_|Eq ", ""))
  )

df_final_argila <- df_final %>%
  mutate(ponto_join = str_trim(str_replace_all(ponto, "Lu_|Lu |Eq_|Eq ", ""))) %>%
  inner_join(df_argila, by = c("ponto_join" = "ID_join"))

alvos_plot <- top_10_combinacoes$sim_id

for(alvo in alvos_plot) {
  dados_alvo <- df_final_argila %>% filter(sim_id == alvo)
  if(nrow(dados_alvo) == 0) next
  
  obs_atual <- unique(dados_alvo$obs)[1]
  texto_obs_sub <- ifelse(!is.na(obs_atual) & obs_atual != "parametros alterados no multfiles", paste0(" | Obs: ", obs_atual), "")
  subtitulo_plot <- paste0("Sim: ", alvo, texto_obs_sub)
  
  m_obs <- lm(valor_obs ~ CLAY_pct, data = dados_alvo)
  m_sim <- lm(somsc ~ CLAY_pct, data = dados_alvo)
  
  r2_obs <- format(round(summary(m_obs)$r.squared, 3), nsmall=3)
  eq_obs <- paste0("r² = ", r2_obs, "; Y = ", format(round(coef(m_obs)[2], 3), nsmall=3), "X + ", format(round(coef(m_obs)[1], 3), nsmall=3))
  
  r2_sim <- format(round(summary(m_sim)$r.squared, 3), nsmall=3)
  eq_sim <- paste0("r² = ", r2_sim, "; Y = ", format(round(coef(m_sim)[2], 3), nsmall=3), "X + ", format(round(coef(m_sim)[1], 3), nsmall=3))
  
  dados_long <- dados_alvo %>%
    select(ponto, ano, CLAY_pct, valor_obs, somsc) %>%
    pivot_longer(cols = c(valor_obs, somsc), names_to = "Tipo", values_to = "C_stock") %>%
    mutate(Tipo_Label = factor(ifelse(Tipo == "valor_obs", "Observed soil C stocks", "Simulated soil C stocks"),
                               levels = c("Observed soil C stocks", "Simulated soil C stocks")))
  
  m_int <- lm(C_stock ~ CLAY_pct * Tipo, data = dados_long)
  p_val_slope <- summary(m_int)$coefficients[4, 4] 
  
  texto_p_slope <- ifelse(p_val_slope > 0.05, 
                          paste0("Slopes n.s. (p = ", format(round(p_val_slope, 4), nsmall=4), ")"),
                          paste0("Slopes sign. diff. (p = ", format(round(p_val_slope, 4), nsmall=4), ")"))
  
  g_argila <- ggplot(dados_long, aes(x = CLAY_pct, y = C_stock, color = Tipo_Label, shape = Tipo_Label, linetype = Tipo_Label)) +
    geom_point(size = 3) +
    geom_smooth(method = "lm", se = FALSE, linewidth = 1) +
    scale_color_manual(values = c("Observed soil C stocks" = "black", "Simulated soil C stocks" = "black")) +
    scale_shape_manual(values = c("Observed soil C stocks" = 19, "Simulated soil C stocks" = 1)) + 
    scale_linetype_manual(values = c("Observed soil C stocks" = "solid", "Simulated soil C stocks" = "dotted")) +
    labs(
      title = "Evaluation: relationship between soil clay content and C stocks",
      subtitle = paste0(subtitulo_plot, " | Teste t: ", texto_p_slope),
      x = "Soil clay content (%)",
      y = expression("Soil C stocks (Mg C ha"^-1*")")
    ) +
    annotate("text", x = max(dados_long$CLAY_pct), y = max(dados_long$C_stock) * 0.98, 
             label = eq_obs, hjust = 1, vjust = 1, size = 4, color = "black") +
    annotate("text", x = max(dados_long$CLAY_pct), y = min(dados_long$C_stock) * 1.02, 
             label = eq_sim, hjust = 1, vjust = 0, size = 4, color = "black") +
    theme_classic() +
    theme(
      legend.position = c(0.25, 0.85),
      legend.title = element_blank(),
      legend.background = element_rect(color = "black", fill = "white", linewidth = 0.5),
      plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
      plot.subtitle = element_text(hjust = 0.5, size = 11, color = "darkred")
    )
  
  nome_limpo <- gsub("[^A-Za-z0-9]", "_", alvo) 
  ggsave(filename = paste0("result/graficos_argila_vs_c/argila_vs_c_", nome_limpo, ".png"), 
         plot = g_argila, width = 8, height = 5.5, dpi = 300)
}

# =========================================================================
# --- 7.7 GRÁFICO COMBINADO: TOP 5 + OBSERVADO ---
# =========================================================================

cat("\nGerando gráfico combinado com simulações e dados de campo...\n")

# Ajuste para evitar erro se houver menos de 5 combinações no dataframe atual
n_comb <- min(5, nrow(top_10_combinacoes))
alvos_top_5 <- top_10_combinacoes$sim_id[1:n_comb]

dados_obs_unico <- df_final_argila %>% 
  filter(sim_id == alvos_top_5[1]) %>%
  select(ponto, CLAY_pct, valor_obs) %>%
  mutate(Grupo = "Observed", C_stock = valor_obs)

dados_sim_top5 <- df_final_argila %>%
  filter(sim_id %in% alvos_top_5) %>%
  select(ponto, CLAY_pct, somsc, sim_id) %>%
  mutate(Grupo = sim_id, C_stock = somsc)

get_label_eq <- function(df_sub, nome) {
  m <- lm(C_stock ~ CLAY_pct, data = df_sub)
  r2 <- format(round(summary(m)$r.squared, 3), nsmall=3)
  intercepto <- format(round(coef(m)[1], 3), nsmall=3)
  inclinacao <- format(round(coef(m)[2], 3), nsmall=3)
  return(paste0(nome, "\n(y = ", inclinacao, "x + ", intercepto, " | R² = ", r2, ")"))
}

label_obs <- get_label_eq(dados_obs_unico, "Observed soil C stocks")
labels_sim <- sapply(alvos_top_5, function(alvo) {
  get_label_eq(dados_sim_top5 %>% filter(Grupo == alvo), alvo)
})

dados_obs_unico <- dados_obs_unico %>% mutate(Grupo_Label = label_obs)
dados_sim_top5 <- dados_sim_top5 %>% mutate(Grupo_Label = unname(labels_sim[Grupo]))

df_plot_top5 <- bind_rows(
  dados_obs_unico %>% select(ponto, CLAY_pct, C_stock, Grupo_Label),
  dados_sim_top5 %>% select(ponto, CLAY_pct, C_stock, Grupo_Label)
)

niveis_fator <- c(label_obs, unname(labels_sim))
df_plot_top5$Grupo_Label <- factor(df_plot_top5$Grupo_Label, levels = niveis_fator)

cores <- c("black", "firebrick", "dodgerblue3", "forestgreen", "darkorange", "purple")
shapes <- c(19, 1, 2, 0, 3, 4)
linetypes <- c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash")

g_comb <- ggplot(df_plot_top5, aes(x = CLAY_pct, y = C_stock, color = Grupo_Label, shape = Grupo_Label, linetype = Grupo_Label)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 1) +
  scale_color_manual(values = cores[1:(n_comb+1)]) +
  scale_shape_manual(values = shapes[1:(n_comb+1)]) +
  scale_linetype_manual(values = linetypes[1:(n_comb+1)]) +
  labs(
    title = ifelse(!is.null(combinacao_especifica) && combinacao_especifica != "", 
                   "Alvo Específico vs Observed Data", 
                   "Top 5 Simulations vs Observed Data"),
    x = "Soil clay content (%)",
    y = expression("Soil C stocks (Mg C ha"^-1*")")
  ) +
  theme_classic() +
  theme(
    legend.position = "right", 
    legend.title = element_blank(),
    legend.text = element_text(size = 9),
    legend.key.height = unit(1.2, "cm"),
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14)
  )

ggsave(filename = "result/graficos_argila_vs_c/argila_vs_c_COMBINADO.png", 
       plot = g_comb, width = 12, height = 7, dpi = 300)

# =========================================================================
# --- 8. DINÂMICA TEMPORAL DOS COMPARTIMENTOS DE CARBONO ---
# =========================================================================

print("Gerando gráficos da dinâmica temporal com dados observados...")
dir.create("result/graficos_dinamica_temporal", showWarnings = FALSE)

melhor_sim <- top_10_combinacoes$sim_id[1]
var_atual_dinamica <- top_10_combinacoes[1, ]
texto_obs_sub <- ifelse(!is.na(var_atual_dinamica$obs) & var_atual_dinamica$obs != "parametros alterados no multfiles", paste0(" | Obs: ", var_atual_dinamica$obs), "")

df_pools <- result_century %>%
  filter(sim_id == melhor_sim) %>%
  mutate(
    ano = round(time, 0),
    somsc = somsc / 100,
    som1c = som1c.2. / 100, 
    som2c = som2c / 100,
    som3c = som3c / 100
  ) %>%
  select(ponto, ano, Total = somsc, Ativo = som1c, Lento = som2c, Passivo = som3c) %>%
  pivot_longer(cols = c(Total, Ativo, Lento, Passivo), 
               names_to = "Compartimento", 
               values_to = "Estoque_C")

df_pools$Compartimento <- factor(df_pools$Compartimento, levels = c("Total", "Passivo", "Lento", "Ativo"))

df_obs_plot <- df_final %>% 
  filter(sim_id == melhor_sim)

g_facet <- ggplot(df_pools, aes(x = ano, y = Estoque_C, color = Compartimento)) +
  geom_line(linewidth = 0.8) +
  geom_point(data = df_obs_plot, aes(x = ano, y = valor_obs, shape = "Observado"), 
             color = "black", size = 2.5, inherit.aes = FALSE) +
  facet_wrap(~ ponto, scales = "free_y") +
  scale_color_manual(values = c("Total" = "black", "Passivo" = "purple", "Lento" = "dodgerblue", "Ativo" = "firebrick")) +
  scale_shape_manual(name = "", values = c("Observado" = 19)) + 
  labs(
    title = "Dinâmica Temporal dos Estoques de Carbono por Ponto",
    subtitle = paste0(prefixo_titulo, ": ", melhor_sim, texto_obs_sub),
    x = "Ano Simulado",
    y = expression(bold("Estoque de C (Mg C ha"^-1*")"))
  ) +
  theme_bw() +
  theme(
    legend.position = "bottom",
    legend.title = element_blank(),
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5),
    strip.background = element_rect(fill = "grey90"),
    strip.text = element_text(face = "bold")
  )

ggsave(filename = "result/graficos_dinamica_temporal/dinamica_facetas_alvo.png", 
       plot = g_facet, width = 12, height = 8, dpi = 300)

df_pools_resumo <- df_pools %>%
  group_by(ano, Compartimento) %>%
  summarise(
    Media_C = mean(Estoque_C, na.rm = TRUE),
    SD_C = sd(Estoque_C, na.rm = TRUE),
    .groups = "drop"
  )

g_media <- ggplot(df_pools_resumo, aes(x = ano, y = Media_C)) +
  geom_ribbon(aes(ymin = Media_C - SD_C, ymax = Media_C + SD_C, fill = Compartimento), alpha = 0.2, color = NA) +
  geom_line(aes(color = Compartimento), linewidth = 1.2) +
  geom_point(data = df_obs_plot, aes(x = ano, y = valor_obs, shape = "Observado"), 
             color = "black", size = 2.5, alpha = 0.7, inherit.aes = FALSE) +
  scale_color_manual(values = c("Total" = "black", "Passivo" = "purple", "Lento" = "dodgerblue", "Ativo" = "firebrick")) +
  scale_fill_manual(values = c("Total" = "grey50", "Passivo" = "purple", "Lento" = "dodgerblue", "Ativo" = "firebrick")) +
  scale_shape_manual(name = "", values = c("Observado" = 19)) +
  labs(
    title = "Comportamento Médio dos Compartimentos de C vs Dados Observados",
    subtitle = paste0(prefixo_titulo, ": ", melhor_sim, texto_obs_sub, " | Faixa = ± 1 SD | Pontos = Amostras de Campo"),
    x = "Ano Simulado",
    y = expression(bold("Estoque de C (Mg C ha"^-1*")"))
  ) +
  theme_classic() +
  theme(
    legend.position = "right",
    legend.title = element_blank(),
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
    plot.subtitle = element_text(hjust = 0.5, color = "darkred")
  )

ggsave(filename = "result/graficos_dinamica_temporal/dinamica_media_alvo.png", 
       plot = g_media, width = 10, height = 6, dpi = 300)


# =========================================================================
# --- 9. RANKING E GRÁFICOS DAS REGRESSÕES MAIS PRÓXIMAS DA OBSERVADA ---
# =========================================================================

cat("\nCalculando similaridade das regressões (Simulado vs Observado)...\n")
dir.create("result/graficos_regressao_proxima", showWarnings = FALSE)

lista_coeficientes <- list()
todas_combinacoes <- unique(df_final_argila$sim_id)

for(alvo in todas_combinacoes) {
  dados_alvo <- df_final_argila %>% filter(sim_id == alvo)
  if(nrow(dados_alvo) < 3) next 
  
  obs_atual <- unique(dados_alvo$obs)[1]
  
  m_obs <- lm(valor_obs ~ CLAY_pct, data = dados_alvo)
  m_sim <- lm(somsc ~ CLAY_pct, data = dados_alvo)
  
  coef_obs <- coef(m_obs)
  coef_sim <- coef(m_sim)
  
  diff_slope <- abs(coef_obs[2] - coef_sim[2])
  diff_intercept <- abs(coef_obs[1] - coef_sim[1])
  
  lista_coeficientes[[alvo]] <- data.frame(
    sim_id = alvo,
    obs = obs_atual,
    slope_obs = coef_obs[2],
    slope_sim = coef_sim[2],
    intercept_obs = coef_obs[1],
    intercept_sim = coef_sim[1],
    diff_slope = diff_slope,
    diff_intercept = diff_intercept
  )
}

df_coeficientes <- bind_rows(lista_coeficientes) %>%
  mutate(
    norm_diff_slope = norm_01(diff_slope, invert = TRUE),        
    norm_diff_intercept = norm_01(diff_intercept, invert = TRUE), 
    score_regressao = round(norm_diff_slope + norm_diff_intercept, 4)
  ) %>%
  arrange(desc(score_regressao))


# LÓGICA DE SELEÇÃO DE REGRESSÃO
if (!is.null(combinacao_especifica) && combinacao_especifica != "") {
  top_3_regressoes <- df_coeficientes %>% filter(sim_id == combinacao_especifica)
  print("========================================================")
  print("REGRESSÃO DA SIMULAÇÃO ESPECÍFICA SOLICITADA")
  print("========================================================")
} else {
  top_3_regressoes <- df_coeficientes %>% slice_head(n = 3)
  print("========================================================")
  print("TOP 3 SIMULAÇÕES COM REGRESSÕES MAIS PRÓXIMAS À OBSERVADA")
  print("========================================================")
}

# --- NOVO TRECHO: Trazendo as métricas de R2, NSE, RMSE para as Top 3 ---
top_3_com_metricas <- top_3_regressoes %>%
  left_join(metricas, by = c("sim_id", "obs")) %>%
  select(
    Simulacao = sim_id, 
    Obs = obs,
    Score_Reg = score_regressao, 
    Diff_Slope = diff_slope, 
    Diff_Intercept = diff_intercept,
    R2 = r2,
    NSE = nse,
    RMSE = rmse,
    Acerto_pct = pct_acerto
  )

print(as.data.frame(top_3_com_metricas), row.names = FALSE)
# ------------------------------------------------------------------------

for(i in 1:nrow(top_3_regressoes)) {
  alvo <- top_3_regressoes$sim_id[i]
  obs_atual <- top_3_regressoes$obs[i]
  
  texto_obs_sub <- ifelse(!is.na(obs_atual) & obs_atual != "parametros alterados no multfiles", paste0("\nObs: ", obs_atual), "")
  
  dados_alvo <- df_final_argila %>% filter(sim_id == alvo)
  
  dados_long <- dados_alvo %>%
    select(ponto, ano, CLAY_pct, valor_obs, somsc) %>%
    pivot_longer(cols = c(valor_obs, somsc), names_to = "Tipo", values_to = "C_stock") %>%
    mutate(Tipo_Label = factor(ifelse(Tipo == "valor_obs", "Observed soil C stocks", "Simulated soil C stocks"),
                               levels = c("Observed soil C stocks", "Simulated soil C stocks")))
  
  m_obs <- lm(valor_obs ~ CLAY_pct, data = dados_alvo)
  m_sim <- lm(somsc ~ CLAY_pct, data = dados_alvo)
  
  eq_obs <- paste0("Obs: Y = ", format(round(coef(m_obs)[2], 3), nsmall=3), "X + ", format(round(coef(m_obs)[1], 3), nsmall=3))
  eq_sim <- paste0("Sim: Y = ", format(round(coef(m_sim)[2], 3), nsmall=3), "X + ", format(round(coef(m_sim)[1], 3), nsmall=3))
  
  titulo_grafico <- ifelse(!is.null(combinacao_especifica) && combinacao_especifica != "", 
                           "Regressão Específica (Argila vs C)", 
                           paste0("Top ", i, " Regressão Mais Próxima (Argila vs C)"))
  
  g_reg <- ggplot(dados_long, aes(x = CLAY_pct, y = C_stock, color = Tipo_Label, shape = Tipo_Label, linetype = Tipo_Label)) +
    geom_point(size = 3, alpha = 0.7) +
    geom_smooth(method = "lm", se = FALSE, linewidth = 1.2) +
    scale_color_manual(values = c("Observed soil C stocks" = "black", "Simulated soil C stocks" = "firebrick")) +
    scale_shape_manual(values = c("Observed soil C stocks" = 19, "Simulated soil C stocks" = 17)) + 
    scale_linetype_manual(values = c("Observed soil C stocks" = "solid", "Simulated soil C stocks" = "dashed")) +
    labs(
      title = titulo_grafico,
      subtitle = paste0("Simulação: ", alvo, texto_obs_sub, "\n", eq_obs, " | ", eq_sim),
      x = "Soil clay content (%)",
      y = expression("Soil C stocks (Mg C ha"^-1*")")
    ) +
    theme_classic() +
    theme(
      legend.position = "top",
      legend.title = element_blank(),
      plot.title = element_text(hjust = 0.5, face = "bold", size = 13),
      plot.subtitle = element_text(hjust = 0.5, size = 11, color = "grey30")
    )
  
  nome_limpo <- gsub("[^A-Za-z0-9]", "_", alvo) 
  ggsave(filename = paste0("result/graficos_regressao_proxima/top_", i, "_regressao_", nome_limpo, ".png"), 
         plot = g_reg, width = 8, height = 6, dpi = 300)
}

cat("\nProcesso finalizado com sucesso!\n")