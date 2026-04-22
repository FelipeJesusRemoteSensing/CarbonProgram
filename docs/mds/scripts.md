# Processos e Scripts

Esta seção detalha em módulos os conjuntos de scripts desenvolvidos para o processamento de dados, modelagem do Century e automação.

```mermaid
flowchart LR
    A[☁️ Downloads GEE] --> B[🗂️ Prep. Imagens R]
    B --> C[📍 Modelagem Pontual] | D[🗺️ Espacialização]
    D --> E[🐍 Validação Python]
```

## Downloads das bases ambientais pelo Google Earth Engine

Estão na pasta `Outros_Scripts` (Arquivos que começam com `GEE`):

- [**GEE - Download Lulc Mapbiomas.txt**](../base_dados/aplicacao/Scripts/Outros_Scripts/GEE%20-%20Download%20Lulc%20Mapbiomas.txt): Script para download de mapas de uso e cobertura do solo do MapBiomas.
    <br>**Principais Etapas:**
    1. Carrega os limites (rasters mascarados) das fazendas.
    2. Importa a base do MapBiomas Coleção 9.
    3. Itera sobre os anos históricos (1985–2023) e fazendas.
    4. Recorta e exporta os dados anuais de uso da terra com resolução de 30m para o Google Drive.
    ??? abstract "Ver Código-Fonte"
        ```javascript
        var fazendas_rasters = ee.ImageCollection('coloque aqui sua image collection');
        var mapbiomas_col9 = ee.Image('projects/mapbiomas-public/assets/brazil/lulc/collection9/mapbiomas_collection90_integration_v1');
        var idsDasFazendas = fazendas_rasters.aggregate_array('system:index').getInfo();
        var anos = ee.List.sequence(1985, 2023);

        idsDasFazendas.forEach(function(id) {
          var fazendaImage = fazendas_rasters.filter(ee.Filter.eq('system:index', id)).first();
          if (fazendaImage) {
            var geometry = fazendaImage.geometry();
            var mascaraFazenda = fazendaImage.gt(0);
            anos.getInfo().forEach(function(ano) {
              var banda_lulc_anual = 'classification_' + ano;
              var lulc_anual_selecionado = mapbiomas_col9.select(banda_lulc_anual);
              var lulcMascarado = lulc_anual_selecionado.clip(geometry).updateMask(mascaraFazenda);
              Export.image.toDrive({
                image: lulcMascarado.rename(banda_lulc_anual),
                description: ano + '_lulc_' + id,
                folder: 'LULC_Serie_Temporal',
                scale: 30, region: geometry.bounds(), maxPixels: 1e13
              });
            });
          }
        });
        ```

- [**GEE - Download Soil Embrapa.txt**](../base_dados/aplicacao/Scripts/Outros_Scripts/GEE%20-%20Download%20Soil%20Embrapa.txt): Script para extração de dados de propriedades do solo da base PronaSolos (Embrapa).
    <br>**Principais Etapas:**
    1. Importa os rasters do PronaSolos (Areia, Silte, Argila, pH, Densidade) para as camadas originais (0-5, 5-15, 15-30cm).
    2. Realiza o cálculo de média ponderada para criar uma variável consolidada para a camada de 0 a 30 cm.
    3. Reamostra a resolução espacial (reduceResolution) para 30 metros para compatibilidade com o projeto.
    4. Itera sobre cada fazenda, recorta e mascara os polígonos.
    5. Exporta os resultados estruturados para o Google Drive.
    ??? abstract "Ver Código-Fonte"
        *(Abaixo está um trecho das funções principais de processamento do script)*
        ```javascript
        var processarSolo = function(band0_5, band5_15, band15_30, outputBandName) {
          var ponderado = band0_5.multiply(1/6).add(band5_15.multiply(2/6)).add(band15_30.multiply(3/6));
          return ponderado.rename(outputBandName).reduceResolution({
            reducer: ee.Reducer.mean(), maxPixels: 65500
          }).reproject({ crs: 'EPSG:4326', scale: 30 });
        };

        var areiaProcessada = processarSolo(
          embrapaSand.select('sand_content_0_5cm_pred_g_kg'),
          embrapaSand.select('sand_content_5_15cm_pred_g_kg'),
          embrapaSand.select('sand_content_15_30cm_pred_g_kg'), 'sand_0-30'
        );
        // Script repete o processamento para as demais variáveis e itera para exportação
        ```

- [**GEE - Download Terraclimate.txt**](../base_dados/aplicacao/Scripts/Outros_Scripts/GEE%20-%20Download%20Terraclimate.txt): Script para aquisição de séries temporais de variáveis climáticas (TerraClimate).
    <br>**Principais Etapas:**
    1. Define os anos de interesse e filtra a coleção TerraClimate anual.
    2. Processa cada variável climática (ex: temperatura mínima `tmmn`), agrupando a média mensal de todos os dias do mês.
    3. Altera a resolução espacial global (reescalona de ~4km para 30m).
    4. Itera sobre cada fazenda, recorta as coleções processadas pela geometria do limite.
    5. Exporta os GeoTIFFs mês a mês para o Google Drive com o prefixo apropriado.
    ??? abstract "Ver Código-Fonte"
        *(Trecho da função de agregação de temperatura mensal)*
        ```javascript
        function processarMesParaAno(mes) {
          mes = ee.Number(mes);
          var colecaoMensal = datasetAnual.filter(ee.Filter.calendarRange(mes, mes, 'month')).select('tmmn');
          var baseImage = ee.Image(colecaoMensal.first());
          
          var mensal = colecaoMensal.mean().round().setDefaultProjection(baseImage.projection());
          var resampled = mensal.reduceResolution({
            reducer: ee.Reducer.mean(), maxPixels: 65536
          }).reproject({ crs: 'EPSG:4326', scale: 30 });
          return resampled;
        }
        ```

## Processamento de preparação de Imagens no Rstudio

Estão na pasta `Outros_Scripts` (Arquivos que começam com `R`):

- [**R - Criar imagem referencia.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Criar%20imagem%20referencia.R): Geração de imagem raster de referência contendo IDs únicos por pixel para a área de estudo.
    <br>**Principais Etapas:**
    1. Define o diretório contendo os rasters originais.
    2. Importa cada raster utilizando o pacote `terra`.
    3. Atribui a cada pixel uma sequência numérica unívoca (de 1 até o número total de células).
    4. Exporta as novas imagens com o prefixo `img_ref_30m_`.
    ??? abstract "Ver Código-Fonte"
        ```R
        library(terra)
        input_folder <- "C:/Users/marco/Downloads/ID-RASTER"
        output_folder <- "C:/Users/marco/Downloads/img_ref"
        tiff_files <- list.files(path = input_folder, pattern = "\\.tif$", full.names = TRUE, ignore.case = TRUE)
        
        for (file_path in tiff_files) {
          original_file_name_with_ext <- basename(file_path)
          original_file_name_no_ext <- tools::file_path_sans_ext(original_file_name_with_ext)
          output_file_name <- paste0("img_ref_30m_", original_file_name_no_ext, ".tif")
          output_file_path <- file.path(output_folder, output_file_name)
          
          r_original <- rast(file_path)
          id_raster <- r_original
          id_raster[] <- 1:ncell(id_raster)
          writeRaster(id_raster, output_file_path, overwrite = TRUE)
        }
        ```

- [**R - Criar imagem referencia individual.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Criar%20imagem%20referencia%20individual.R): Geração de rasters de referência específicos para fazendas ou áreas individuais.
    <br>**Principais Etapas:**
    1. Importa um arquivo `.tif` alvo individual.
    2. Aplica a mesma lógica do script anterior, substituindo todos os valores por um ID sequencial `1:ncell`.
    3. Salva a nova imagem diretamente na mesma pasta de origem.
    ??? abstract "Ver Código-Fonte"
        ```R
        library(terra)
        input_file_path <- "D:/Projetos-Lapig/century/revert/rasters/Fazendas/.../1985_lulc_6-57-7.tif"
        input_folder <- dirname(input_file_path)
        original_file_name_no_ext <- tools::file_path_sans_ext(basename(input_file_path))
        output_file_path <- file.path(input_folder, paste0("img_ref_30m_", original_file_name_no_ext, ".tif"))
        
        r_original <- rast(input_file_path)
        id_raster <- r_original
        id_raster[] <- 1:ncell(id_raster)
        writeRaster(id_raster, output_file_path, overwrite = TRUE)
        ```

- [**R - Recortar img referencia com base nos talhoes.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Recortar%20img%20referencia%20com%20base%20nos%20talhoes.R): Recorte das imagens de referência utilizando os limites vetoriais dos talhões de interesse.
    <br>**Principais Etapas:**
    1. Importa a imagem de referência base (raster) e os polígonos dos talhões (shapefile).
    2. Alinha o sistema de coordenadas (CRS) do vetor com o do raster.
    3. Para cada polígono individual, executa o corte geométrico (`crop`) e aplica a máscara para manter apenas a área exata do talhão.
    4. Salva a camada recortada correspondente a cada ID de talhão.
    ??? abstract "Ver Código-Fonte"
        ```R
        library(raster)
        library(sf)
        caminho_raster <- "D:/.../img_ref_30m.tif"
        caminho_shapefile <- "D:/.../talhoes.shp"
        
        imagem_base <- raster(caminho_raster)
        talhoes <- st_read(caminho_shapefile)
        if (st_crs(talhoes) != crs(imagem_base)) {
          talhoes <- st_transform(talhoes, crs = crs(imagem_base))
        }
        
        for (i in 1:nrow(talhoes)) {
          talhao_individual <- talhoes[i, ]
          id_talhao <- talhao_individual$layer
          raster_recortado <- mask(crop(imagem_base, talhao_individual), talhao_individual)
          nome_arquivo_saida <- file.path(diretorio_saida, paste0("img_ref_talhao_", id_talhao, ".tif"))
          writeRaster(raster_recortado, filename = nome_arquivo_saida, format = "GTiff", overwrite = TRUE)
        }
        ```

- [**R - Recortar raster com base em outro.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Recortar%20raster%20com%20base%20em%20outro.R): Padronização e alinhamento de extensões espaciais entre diferentes camadas rasters.
    <br>**Principais Etapas:**
    1. Define um raster principal de referência (como o uso do solo).
    2. Cria uma máscara lógica na qual as áreas válidas são aquelas diferentes de `NA` ou `0`.
    3. Para cada imagem alvo (ex: clima/precipitação), executa o reamostramento (resample) usando o método `bilinear` para alinhar os pixels.
    4. Aplica a máscara e preenche com zero as áreas sem dados (`ifel(mask_valida, r_chuva_ajustado, 0)`).
    5. Exporta os resultados alinhados.
    ??? abstract "Ver Código-Fonte"
        ```R
        library(terra)
        caminho_referencia <- "D:/.../1985_lulc_AGM.tif"
        pasta_precipitacao <- "C:/.../acm_series_completa"
        
        r_ref <- rast(caminho_referencia)
        mask_valida <- !is.na(r_ref) & (r_ref != 0)
        arquivos_prec <- list.files(pasta_precipitacao, pattern = "\\.tif$", full.names = TRUE)
        
        for (arquivo in arquivos_prec) {
          r_chuva <- rast(arquivo)
          r_chuva_ajustado <- resample(r_chuva, r_ref, method = "bilinear")
          r_final <- ifel(mask_valida, r_chuva_ajustado, 0)
          r_final <- classify(r_final, cbind(NA, 0))
          
          caminho_salvar <- file.path(pasta_saida, basename(arquivo))
          writeRaster(r_final, caminho_salvar, overwrite = TRUE, gdal=c("COMPRESS=LZW"))
        }
        ```

## Modelagem do Century para o ponto amostral

Estão na pasta `Scripts_Ponto`:

- [**1_rodar_simulações_CR_CM.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/1_rodar_simulações_CR_CM.R): Executa as simulações do modelo Century para os pontos de calibração e validação.
    <br>**Principais Etapas:**
    1. Lê os agendamentos (`.sch` e `.100`) para a inicialização e o uso do solo.
    2. Importa o arquivo CSV com a lista de parametrizações para rodar cenários múltiplos.
    3. Itera sobre cada simulação, inserindo as alterações no arquivo de parâmetros base.
    4. Identifica automaticamente a existência de arquivos de Clima Real (`.wth`). Se não houver, roda o Clima Médio.
    5. Dispara as funções de console (`runCentury`) para execução e agrupa os resultados.
    ??? abstract "Ver Código-Fonte"
        *(Devido ao tamanho, abaixo está um trecho da execução condicional do clima)*
        ```R
        for (i in 1:length(lisEq)){
          schEqI <- schEq[i]; cemEqI <- cemEq[i]; schLuI <- schLu[i]; cemLuI <- cemLu[i]
          
          wthLuI <- gsub("\\.sch$", ".wth", schLuI) # Procura o clima real .wth
          if (file.exists(wthLuI)) {
            cat(" [+] Arquivo .wth encontrado. Rodando runCenturyLuCR (Clima Real)\n")
            runCenturyLuCR(schEqI, cemEqI, schLuI, cemLuI, wthLuI)
          } else {
            cat(" [-] Arquivo .wth não encontrado. Rodando runCenturyLuCM (Clima Médio)\n")
            runCenturyLuCM(schEqI, cemEqI, schLuI, cemLuI)
          }
        }
        ```

- [**2_gerar_csv.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/2_gerar_csv.R): Converte os resultados binários das simulações do Century em planilhas CSV para análise.
    <br>**Principais Etapas:**
    1. Varre as pastas e subpastas das simulações organizadas em Lotes.
    2. Cruza as informações com o arquivo `resumo_variacoes.csv` se existir.
    3. Para cada saída `.lis` gerada pelo Century, lê os dados numéricos tabelados.
    4. Filtra e extrai os anos de interesse da modelagem (ex: 2015-2025).
    5. Consolida todas as extrações de todas as simulações em um arquivo `resultados_century_simulations.csv`.
    ??? abstract "Ver Código-Fonte"
        *(Abaixo está o loop de processamento do dataframe dos arquivos .lis)*
        ```R
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
        }
        ```

- [**3_gerar_graficos_avaliacao.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/3_gerar_graficos_avaliacao.R): Cria gráficos e calcula métricas de erro (observado vs. simulado) para avaliar a calibração do modelo.
    <br>**Principais Etapas:**
    1. Importa as informações observadas (dados de campo/laboratório).
    2. Calcula os erros estatísticos, como o `RMSE`, para comparar o simulado vs. observado.
    3. Elabora um ranking identificando as "Top 10" melhores parametrizações com menor erro.
    4. Plota os gráficos de dispersão `1:1`, as análises de outliers, e a dinâmica temporal das frações (ativo, lento, passivo).
    5. Exporta todos os gráficos renderizados como imagens de alta resolução em pastas específicas.
    ??? abstract "Ver Código-Fonte"
        *(Nota: Script com mais de 1000 linhas. Abaixo um fragmento representativo do cálculo de RMSE).*
        ```R
        df_merged <- merge(df_simulado, df_observado, by="ID_Amostra")
        df_erro <- df_merged %>%
          mutate(
            Erro = Simulado_SOMSC - Observado_C,
            Erro_Quadrado = Erro^2
          ) %>%
          group_by(Simulation_ID) %>%
          summarise(
            RMSE = sqrt(mean(Erro_Quadrado, na.rm=TRUE)),
            R2 = cor(Simulado_SOMSC, Observado_C, use="complete.obs")^2
          ) %>%
          arrange(RMSE) # Rankeia do menor erro para o maior
        
        top10_simulations <- head(df_erro, 10)
        ```

- [**4_gerar_relatorio.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/4_gerar_relatorio.R): Compila os resultados das avaliações e gráficos em um relatório de performance do modelo.
    <br>**Principais Etapas:**
    1. Instancia o pacote de automação `officer`.
    2. Cria uma apresentação de slides (`.pptx`) com layouts formatados.
    3. Importa a tabela do ranking final e a insere via biblioteca `flextable`.
    4. Concatena os gráficos estatísticos exportados pelo script anterior e posiciona os PNGs em slides individuais.
    5. Exporta o `Apresentacao_Resultados_Century.pptx` na pasta result.
    ??? abstract "Ver Código-Fonte"
        ```R
        library(officer)
        library(flextable)
        ppt <- read_pptx()
        ppt <- add_slide(ppt, layout = "Title Slide", master = "Office Theme")
        ppt <- ph_with(ppt, value = "Resultados da Simulação Century", location = ph_location_type(type = "ctrTitle"))
        
        arquivo_ranking <- "result/ranking_top10_simulacoes.csv"
        if(file.exists(arquivo_ranking)) {
          ppt <- add_slide(ppt, layout = "Title and Content", master = "Office Theme")
          ppt <- ph_with(ppt, value = "Top 10 Simulações (Ranking Final)", location = ph_location_type(type = "title"))
          tabela_rank <- read.csv(arquivo_ranking)
          ft <- flextable(tabela_rank) %>% theme_zebra() %>% autofit() %>% align(align="center", part="all")
          ppt <- ph_with(ppt, value = ft, location = ph_location_type(type = "body"))
        }
        # Inserção das imagens dos gráficos e fechamento
        print(ppt, target = "result/Apresentacao_Resultados_Century.pptx")
        ```

- [**functionsRcentury.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/functionsRcentury.R): Conjunto de funções auxiliares e dependências em R utilizadas pelos demais scripts de modelagem pontual.
    <br>**Principais Etapas:**
    1. `runCenturyLuCM`: Orquestra comandos shell do `century.exe` e `list100.exe` em condições padrão de clima.
    2. `runCenturyLuCR`: Executa o executável injetando arquivos `.wth` dinâmicos.
    3. `changFILES`: Funções que sobreescrevem parâmetros de solo do arquivo binário/texto `.100` diretamente via linha antes do início das execuções.
    ??? abstract "Ver Código-Fonte"
        ```R
        runCenturyLuCM <- function(schEqI, cemEqI, schLuI, cemLu){
          pathOr <- getwd()
          # Cópia e renomeio dos arquivos para ambiente de execução da pasta /century
          file.copy(from = schEqI, to = "century"); file.rename(gsub("ponto/", "century/", schEqI), "century/eq_site.sch")
          # ...
          
          setwd("century")
          system('century -s eq_site -n eq_site') # Spin-up (Equilíbrio)
          system('century -s lu_site -n lu_site -e eq_site') # Uso do solo
          system('list100 eq_site eq_site output.txt') # Conversão binário para texto
          system('list100 lu_site lu_site output.txt')
          
          setwd(pathOr)
          file.copy(from = "century/lu_site.lis", to = lisLu[i], overwrite = TRUE)
          # ... limpeza dos dados executados
        }
        ```

A estrutura de pastas recomendada para Simulação por ponto é:

```text
century (arquivos century)
century_parametros (csv com alterações)
ponto (sch e .100)
reference_values (dados de referencia)
resul (resultados)
Projeto R para interligar os scripts e pastas
```

## Modelagem do Century espacializada para o talhão

Estão na pasta `Scripts_Espacialização`:

- [**0_f_run_century_spatial_reverte_pasta.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/0_f_run_century_spatial_reverte_pasta.R): Função principal que orquestra todo o fluxo de execução espacializada do modelo Century.
    <br>**Principais Etapas:**
    1. Define funções para ler arquivos binários (`.bin`) e de texto (`.lis`) gerados pelo executável do Century.
    2. Modifica dinamicamente os parâmetros de clima real `.wth` e atributos de solo (`.100`) para cada pixel/bloco processado.
    3. Executa a rotina `list100` e converte os outputs, integrando variáveis como produtividade, carbono no solo, etc.
    4. Salva o histórico de execução por pixel, gerenciando blocos e otimizando a memória.
    ??? abstract "Ver Código-Fonte"
        *(Abaixo está a definição inicial das variáveis do simulador espacializado)*
        ```R
        runCenturySpatial <- function(out_prefix, id, varName, wthfile_Lu, wthfile_Eq, blockNum, yearMin, yearMax) {
          # Preparação de ambiente para rodar o executável
          schEqI <- "eq_site.sch"
          cemEqI <- "eq_site.100"
          schLuI <- "lu_site.sch"
          cemLuI <- "lu_site.100"
          
          system('century -s eq_site -n eq_site')
          system('century -s lu_site -n lu_site -e eq_site')
          system('list100 lu_site lu_site output.txt')
          
          # Extrai resultados e converte CSV...
        }
        ```

- [**01_extract_csv_blocos.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/01_extract_csv_blocos.R): Extrai os dados ambientais dos rasters para formato tabular (CSV), separando o processamento em blocos por fazenda.
    <br>**Principais Etapas:**
    1. Carrega todas as variáveis espaciais (Uso do solo, PronaSolos, TerraClimate).
    2. Lê o polígono (shapefile) correspondente aos talhões da fazenda de interesse.
    3. Garante que existem bandas suficientes para armazenamento de parâmetros extras.
    4. Usa o comando `extract()` do pacote `terra` para puxar os valores de todos os pixels inseridos nos talhões.
    5. Exporta as extrações para arquivos `.csv` (Blocos), reduzindo a carga computacional das simulações seguintes.
    ??? abstract "Ver Código-Fonte"
        ```R
        library(terra)
        # ... configurações de caminhos e leituras de rasters ...
        for (nome in name_talhoes) {
          talhao_i <- talhoes[talhoes$Name == nome, ]
          if (nrow(talhao_i) == 0) next
          
          val_lulc <- extract(img_lulc, talhao_i)[, -1, drop = FALSE]
          val_soil <- extract(img_soil, talhao_i)[, -1, drop = FALSE]
          val_ppt  <- extract(img_ppt,  talhao_i)[, -1, drop = FALSE]
          val_tmn  <- extract(img_tmn,  talhao_i)[, -1, drop = FALSE]
          val_tmx  <- extract(img_tmx,  talhao_i)[, -1, drop = FALSE]
          
          df_all <- cbind(val_lulc, val_soil, val_ppt, val_tmn, val_tmx)
          write.csv(df_all, file.path(outputDir, paste0(nome, ".csv")), row.names = FALSE)
        }
        ```

- [**02_run_century-roi_reverte.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/02_run_century-roi_reverte.R): Dispara a execução das simulações do modelo para regiões de interesse (ROIs) ou blocos específicos.
    <br>**Principais Etapas:**
    1. Importa a função principal construída no script `0_f_...`.
    2. Define o caminho de entrada contendo os CSVs de blocos gerados no passo 1.
    3. Cria arquivos meteorológicos (`.wth`) sob demanda para as execuções do Century baseadas nos dados do pixel.
    4. Dispara a simulação em loop e agrupa os resultados.
    ??? abstract "Ver Código-Fonte"
        *(Resumo do loop principal)*
        ```R
        source("0_f_run_century_spatial_reverte_pasta.R")
        arquivos_blocos <- list.files("dados/blocos", pattern = "\\.csv$", full.names = TRUE)
        
        for(bloco in arquivos_blocos) {
            # Lê CSV de entradas
            dados_entrada <- read.csv(bloco)
            # Aciona a função master de espacialização e grava saída simulada em dados/output/
            runCenturySpatial(out_prefix="out_", id=basename(bloco), varName="somsc", ...)
        }
        ```

- [**03_csv_to_outsub_raster_reverte_somsc.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/03_csv_to_outsub_raster_reverte_somsc.R): Converte as saídas tabulares do modelo de volta para o formato raster (ex: estoques de carbono no solo - SOMSC).
    <br>**Principais Etapas:**
    1. Lê a grade raster base de referência que contém os IDs únicos (`cellNumber`).
    2. Importa o CSV processado (`dados/output/`) contendo as métricas temporais (ex: carbono por pixel para os anos 2010 a 2024).
    3. Executa operações de substituição (`subs()` ou dicionário) mapeando os resultados da tabela de volta para os pixels espaciais.
    4. Exporta arquivos TIFF individuais com os dados mapeados anualmente (ex: `SOMSC_2020.tif`).
    ??? abstract "Ver Código-Fonte"
        ```R
        # Trecho ilustrativo do mapeamento raster-tabela
        raster_id <- rast("dados/referencia_id.tif")
        df_resultados <- read.csv("dados/output/resultados_century.csv")
        
        for(ano_atual in anos_interesse) {
            valores_ano <- df_resultados[df_resultados$time == ano_atual, c("cellNumber", "somsc")]
            # Transfere os valores do CSV de volta para a matriz espacial
            raster_ano <- classify(raster_id, valores_ano)
            writeRaster(raster_ano, paste0("SOMSC_", ano_atual, ".tif"), overwrite=TRUE)
        }
        ```

- [**04_san-csv_to_raster_cerr_somsc.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/04_san-csv_to_raster_cerr_somsc.R): Processamento específico e tratamento de dados de conversão de solo voltados para o bioma Cerrado.
    <br>**Principais Etapas:**
    1. Realiza o mapeamento espacial (CSV > Raster) especificamente para parâmetros do Cerrado (usando máscaras, ou lógicas específicas).
    2. Aplica filtros ou limites numéricos pertinentes aos estoques avaliados na região de interesse.
    ??? abstract "Ver Código-Fonte"
        ```R
        # Estrutura idêntica ao script anterior (03_), porém com parâmetros 
        # voltados para filtragem ou recortes específicos definidos para o 
        # bioma ou projeto "San" / Cerrado.
        ```

- [**05_mosaic_talhoes.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/05_mosaic_talhoes.R): Mescla os rasters gerados individualmente para compor o mosaico final contínuo de todas as áreas modeladas.
    <br>**Principais Etapas:**
    1. Varre o diretório de outputs buscando todos os arquivos gerados no passo 03/04 de todos os talhões.
    2. Agrupa a lista de imagens por ano e pela variável modelada (ex: todos os `SOMSC_2020` de todos os blocos).
    3. Utiliza a função `mosaic()` do pacote `terra` ou `raster` para agrupar fisicamente as imagens num único mapa contínuo.
    4. Grava o raster consolidado e otimizado no disco, que pode ser importado para o QGIS ou relatórios.
    ??? abstract "Ver Código-Fonte"
        ```R
        library(terra)
        arquivos_para_mosaico <- list.files("outputs/temporais", pattern = "SOMSC_2024", full.names = TRUE)
        lista_rasters <- lapply(arquivos_para_mosaico, rast)
        
        # Constrói o mosaico unindo todos os recortes com a média dos valores de intersecção
        mosaico_final <- do.call(mosaic, c(lista_rasters, fun="mean"))
        writeRaster(mosaico_final, "outputs/MOSAICO_SOMSC_2024.tif", overwrite=TRUE)
        ```

A estrutura de pastas recomendada para Simulação espacializada é:

```text
century (arquivos century)
dados 
 - agendamento (arquivo sch e .100)
 - blocos (dados ambientais extraidas dos rasters por pixel)
 - output
Projeto R para interligar os scripts e pastas
```

## Extras

Estão na pasta `Outros_Scripts` (Arquivos que começam com `Py`):

- [**PY - Conferir se há arquivos faltantes nas pastas.py**](../base_dados/aplicacao/Scripts/Outros_Scripts/PY%20-%20Conferir%20se%20há%20arquivos%20faltantes%20nas%20pastas.py): Script utilitário para validação da integridade estrutural, verificando se existem arquivos faltantes nas pastas antes da execução da modelagem.
    <br>**Principais Etapas:**
    1. Define funções que montam as "sequências esperadas" de arquivos (ex: uma série climática deve ter dados de `1958_01` até `2024_12`).
    2. Acessa as pastas físicas que contêm os rasters extraídos das fazendas.
    3. Itera pasta por pasta (`lulc`, `soil`, clima) conferindo os nomes dos arquivos presentes contra as listas de verificação ideais.
    4. Gera alertas no console indicando exatamente qual mês/ano está faltando para qual fazenda, além de um sumário geral das fazendas defeituosas.
    ??? abstract "Ver Código-Fonte"
        ```python
        import os

        def gerar_sequencia_ano_mes(ano_inicio, mes_inicio, ano_fim, mes_fim):
            sequencia = set()
            for ano in range(ano_inicio, ano_fim + 1):
                start_month = mes_inicio if ano == ano_inicio else 1
                end_month = mes_fim if ano == ano_fim else 12
                for mes in range(start_month, end_month + 1):
                    sequencia.add(f"{ano}_{mes:02d}")
            return sequencia

        def verificar_arquivos_nas_pastas(pasta_base_Fazendas):
            # ... Inicialização das sequências esperadas ...
            for nome_pasta_fazenda in os.listdir(pasta_base_Fazendas):
                caminho_pasta_fazenda = os.path.join(pasta_base_Fazendas, nome_pasta_fazenda)
                if os.path.isdir(caminho_pasta_fazenda):
                    # Loop pelas subpastas (LULC, SOIL, CLIMA) e extração dos padrões numéricos nos nomes
                    # Comparação de conjuntos (Set Difference): esperados - presentes
                    # Print dos alertas de erro e sumário final
                    pass # Estrutura resumida
        
        if __name__ == "__main__":
            pasta_alvo = r"D:\Projetos-Lapig\century\revert\rasters\Fazendas"
            verificar_arquivos_nas_pastas(pasta_alvo)
        ```

---
- [← Requisitos para Modelagem](requisitos_para_modelagem.md)
- [Referências →](referencias.md)
