# Processos e Scripts

Esta seção detalha os scripts desenvolvidos para o processamento de dados, espacialização do modelo Century e automação de downloads no contexto do monitoramento de carbono.

## Scripts de Espacialização

Estes scripts em linguagem R são responsáveis pelo fluxo de execução espacial do modelo Century, desde a extração de dados até a geração de mosaicos finais.

- [**0_f_run_century_spatial_reverte_pasta.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/0_f_run_century_spatial_reverte_pasta.R): Função principal para execução espacializada do Century.
- [**01_extract_csv_blocos.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/01_extract_csv_blocos.R): Extração de dados em formato CSV para processamento por blocos.
- [**02_run_century-roi_reverte.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/02_run_century-roi_reverte.R): Execução do modelo para regiões de interesse específicas (ROIs).
- [**03_csv_to_outsub_raster_reverte_somsc.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/03_csv_to_outsub_raster_reverte_somsc.R): Conversão de saídas CSV para formato raster (SOMSC).
- [**04_san-csv_to_raster_cerr_somsc.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/04_san-csv_to_raster_cerr_somsc.R): Processamento e conversão de dados de solo do Cerrado.
- [**05_mosaic_talhoes.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/05_mosaic_talhoes.R): Geração de mosaicos finais a partir dos talhões processados.

## Outros Scripts e Utilidades

Scripts auxiliares para download de dados via Google Earth Engine (GEE), preparação de imagens de referência e conferência de arquivos.

### Downloads e GEE
- [**GEE - Download Lulc Mapbiomas.txt**](../base_dados/aplicacao/Scripts/Outros_Scripts/GEE%20-%20Download%20Lulc%20Mapbiomas.txt): Script para download de mapas de uso e cobertura do MapBiomas.
- [**GEE - Download Soil Embrapa.txt**](../base_dados/aplicacao/Scripts/Outros_Scripts/GEE%20-%20Download%20Soil%20Embrapa.txt): Script para download de dados de solo da Embrapa.
- [**GEE - Download Terraclimate.txt**](../base_dados/aplicacao/Scripts/Outros_Scripts/GEE%20-%20Download%20Terraclimate.txt): Script para download de variáveis climáticas do TerraClimate.

### Processamento de Imagens (R)
- [**R - Criar imagem referencia.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Criar%20imagem%20referencia.R): Geração de imagem de referência para o projeto.
- [**R - Criar imagem referencia individual.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Criar%20imagem%20referencia%20individual.R): Geração de referências por área específica.
- [**R - Recortar img referencia com base nos talhoes.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Recortar%20img%20referencia%20com%20base%20nos%20talhoes.R): Recorte de imagens utilizando os limites dos talhões.
- [**R - Recortar raster com base em outro.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Recortar%20raster%20com%20base%20em%20outro.R): Padronização de extensões entre rasters.

### Utilidades (Python)
- [**PY - Conferir se há arquivos faltantes nas pastas.py**](../base_dados/aplicacao/Scripts/Outros_Scripts/PY%20-%20Conferir%20se%20há%20arquivos%20faltantes%20nas%20pastas.py): Script para validação da integridade do banco de dados e arquivos processados.
