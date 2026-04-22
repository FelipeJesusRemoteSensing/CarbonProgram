# Processos e Scripts

Esta seção detalha em módulos os conjuntos de scripts desenvolvidos para o processamento de dados, modelagem do Century e automação.

## Downloads das bases ambientais pelo Google Earth Engine

Estão na pasta `Outros_Scripts` (Arquivos que começam com `GEE`):

- [**GEE - Download Lulc Mapbiomas.txt**](../base_dados/aplicacao/Scripts/Outros_Scripts/GEE%20-%20Download%20Lulc%20Mapbiomas.txt)
- [**GEE - Download Soil Embrapa.txt**](../base_dados/aplicacao/Scripts/Outros_Scripts/GEE%20-%20Download%20Soil%20Embrapa.txt)
- [**GEE - Download Terraclimate.txt**](../base_dados/aplicacao/Scripts/Outros_Scripts/GEE%20-%20Download%20Terraclimate.txt)

## Processamento de preparação de Imagens no Rstudio

Estão na pasta `Outros_Scripts` (Arquivos que começam com `R`):

- [**R - Criar imagem referencia.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Criar%20imagem%20referencia.R)
- [**R - Criar imagem referencia individual.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Criar%20imagem%20referencia%20individual.R)
- [**R - Recortar img referencia com base nos talhoes.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Recortar%20img%20referencia%20com%20base%20nos%20talhoes.R)
- [**R - Recortar raster com base em outro.R**](../base_dados/aplicacao/Scripts/Outros_Scripts/R%20-%20Recortar%20raster%20com%20base%20em%20outro.R)

## Modelagem do Century para o ponto amostral

Estão na pasta `Scripts_Ponto`:

- [**1_rodar_simulações_CR_CM.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/1_rodar_simulações_CR_CM.R)
- [**2_gerar_csv.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/2_gerar_csv.R)
- [**3_gerar_graficos_avaliacao.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/3_gerar_graficos_avaliacao.R)
- [**4_gerar_relatorio.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/4_gerar_relatorio.R)
- [**functionsRcentury.R**](../base_dados/aplicacao/Scripts/Scripts_Ponto/functionsRcentury.R)

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

- [**0_f_run_century_spatial_reverte_pasta.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/0_f_run_century_spatial_reverte_pasta.R)
- [**01_extract_csv_blocos.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/01_extract_csv_blocos.R)
- [**02_run_century-roi_reverte.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/02_run_century-roi_reverte.R)
- [**03_csv_to_outsub_raster_reverte_somsc.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/03_csv_to_outsub_raster_reverte_somsc.R)
- [**04_san-csv_to_raster_cerr_somsc.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/04_san-csv_to_raster_cerr_somsc.R)
- [**05_mosaic_talhoes.R**](../base_dados/aplicacao/Scripts/Scripts_Espacialização/05_mosaic_talhoes.R)

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

- [**PY - Conferir se há arquivos faltantes nas pastas.py**](../base_dados/aplicacao/Scripts/Outros_Scripts/PY%20-%20Conferir%20se%20há%20arquivos%20faltantes%20nas%20pastas.py)

---
- [← Requisitos para Modelagem](requisitos_para_modelagem.md)
- [Referências →](referencias.md)
