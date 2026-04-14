#!/bin/bash

#===========================================================================================================================================================================================
#Configuracoes de Entrada e Variaveis Globais
raster_SC="classificacao_pastagem_SC_refinado_4326.tif" # Nome do arquivo raster original que sera processado
NODATA_SAIDA="0" # Valor atribuido aos pixels que nao possuem dados
edicao="4" # Identificador da edicao ou lote de processamento
#===========================================================================================================================================================================================
# Definicao dos Sistemas de Referencia de Coordenadas (CRS)
PROJECAO_D="EPSG:3857" # Projecao de Destino: Web Mercator
PROJECAO_E="EPSG:4326" # Projecao de Origem: WGS 84 (Geografica)
extensao4326="-53.8372027870000025 -29.3551468540000009 -48.3278351499999985 -25.9558319879999999" # Coordenadas da extensao geografica (xmin ymin xmax ymax) em WGS 84
#===========================================================================================================================================================================================
#Definicao dos Caminhos de Arquivos
DIR_SCRIPT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) # Identifica o caminho absoluto da pasta onde o script esta salvo
RASTER_ENTRADA="$DIR_SCRIPT/$raster_SC" # Caminho completo do arquivo raster de entrada
CUTLINE_PADRAO="$DIR_SCRIPT/Tiles_semana_${edicao}/{1}/tiles_*_{1}.shp" # Caminho para os shapefiles de corte. O marcador {1} recebe os nomes da lista
SAIDA_PADRAO="$DIR_SCRIPT/${raster_SC%.tif}_${edicao}_{1}.tif" # Nome e local do arquivo de saida
#===========================================================================================================================================================================================
#Processamento em Paralelo
# parallel: Executa tarefas simultaneas para ganhar velocidade
# -j7: Usa 7 nucleos do processador ao mesmo tempo
# --eta: Mostra o tempo estimado para terminar
# --bar: Mostra uma barra de progresso visual
parallel -j7 --eta --bar \ 
    gdalwarp -s_srs "$PROJECAO_E" \
        -t_srs "$PROJECAO_D" \
        -te_srs "$PROJECAO_E" \
        -te $extensao4326 \
        -cutline "$CUTLINE_PADRAO" \
        -crop_to_cutline \
        -tr 10 10 \
        -tap \
        -srcnodata "$NODATA_SAIDA" \
        -co COMPRESS=LZW \
        "$RASTER_ENTRADA" \
        "$SAIDA_PADRAO" \
::: Ana Carlos Felipe Guilherme Lucas Pamela Taise

# -s_srs seta a projecao do arquivo de entrada (PROJECAO_E)
# -t_srs converte a projecao atual para a desejada (PROJECAO_D)
# -te_srs e usado para definir em qual sistema de coordenadas os numeros que voce digitou na configuracao -te estao escritos
# -te usado para definir os valores numericos dos limites geograficos (a "caixa") do seu arquivo de saida
# -cutline: Usa o shapefile como um molde para o corte
# -crop_to_cutline: Remove as sobras fora do molde do shapefile
# -tr 10 10: Ajusta o tamanho do pixel para 10 metros
# -tap: Alinha os pixels com a grade de coordenadas
# -srcnodata: Identifica o valor nulo no dado de entrada
# -co COMPRESS=LZW: Compacta o arquivo final para ocupar menos espaco