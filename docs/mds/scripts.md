# Processos e Scripts

Esta seção detalha em módulos os conjuntos de scripts desenvolvidos para o processamento de dados, modelagem do Century e automação.

## Downloads das bases ambientais pelo Google Earth Engine

Estão na pasta `Outros_Scripts` (Arquivos que começam com `GEE`):

- [**GEE - Download Lulc Mapbiomas.txt**](../base_dados/aplicacao/Scripts/Outros_Scripts/GEE%20-%20Download%20Lulc%20Mapbiomas.txt): Script para download de mapas de uso e cobertura do solo do MapBiomas.
- [**GEE - Download Soil Embrapa.txt**](../base_dados/aplicacao/Scripts/Outros_Scripts/GEE%20-%20Download%20Soil%20Embrapa.txt): Script para extração de dados de propriedades do solo da base PronaSolos (Embrapa).
- [**GEE - Download Terraclimate.txt**](../base_dados/aplicacao/Scripts/Outros_Scripts/GEE%20-%20Download%20Terraclimate.txt): Script para aquisição de séries temporais de variáveis climáticas (TerraClimate).

## Processamento de preparação de Imagens no Rstudio

Estão na pasta `Outros_Scripts` (Arquivos que começam com `R`):

- [**R - Criar imagem referencia.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Criar%20imagem%20referencia.R): Geração de imagem raster de referência contendo IDs únicos por pixel para a área de estudo.
- [**R - Criar imagem referencia individual.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Criar%20imagem%20referencia%20individual.R): Geração de rasters de referência específicos para fazendas ou áreas individuais.
- [**R - Recortar img referencia com base nos talhoes.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Recortar%20img%20referencia%20com%20base%20nos%20talhoes.R): Recorte das imagens de referência utilizando os limites vetoriais dos talhões de interesse.
- [**R - Recortar raster com base em outro.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Recortar%20raster%20com%20base%20em%20outro.R): Padronização e alinhamento de extensões espaciais entre diferentes camadas rasters.

## Modelagem do Century para o ponto amostral

Estão na pasta `Scripts_Ponto`:

- [**1_rodar_simulações_CR_CM.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/1_rodar_simulações_CR_CM.R): Executa as simulações do modelo Century para os pontos de calibração e validação.
- [**2_gerar_csv.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/2_gerar_csv.R): Converte os resultados binários das simulações do Century em planilhas CSV para análise.
- [**3_gerar_graficos_avaliacao.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/3_gerar_graficos_avaliacao.R): Cria gráficos e calcula métricas de erro (observado vs. simulado) para avaliar a calibração do modelo.
- [**4_gerar_relatorio.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/4_gerar_relatorio.R): Compila os resultados das avaliações e gráficos em um relatório de performance do modelo.
- [**functionsRcentury.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/functionsRcentury.R): Conjunto de funções auxiliares e dependências em R utilizadas pelos demais scripts de modelagem pontual.

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
- [**01_extract_csv_blocos.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/01_extract_csv_blocos.R): Extrai os dados ambientais dos rasters para formato tabular (CSV), separando o processamento em blocos.
- [**02_run_century-roi_reverte.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/02_run_century-roi_reverte.R): Dispara a execução das simulações do modelo para regiões de interesse (ROIs) ou blocos específicos.
- [**03_csv_to_outsub_raster_reverte_somsc.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/03_csv_to_outsub_raster_reverte_somsc.R): Converte as saídas tabulares do modelo de volta para o formato raster (ex: estoques de carbono no solo - SOMSC).
- [**04_san-csv_to_raster_cerr_somsc.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/04_san-csv_to_raster_cerr_somsc.R): Processamento específico e tratamento de dados de conversão de solo voltados para o bioma Cerrado.
- [**05_mosaic_talhoes.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/05_mosaic_talhoes.R): Mescla os rasters gerados individualmente para compor o mosaico final contínuo de todas as áreas modeladas.

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

---
- [← Requisitos para Modelagem](requisitos_para_modelagem.md)
- [Referências →](referencias.md)
