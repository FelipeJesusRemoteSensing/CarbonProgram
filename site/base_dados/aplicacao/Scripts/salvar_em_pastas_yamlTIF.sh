#!/bin/bash

PASTA_INICIAL="."
VALOR_NODATA="0" # Altere este valor conforme sua necessidade (0, -9999, nan)

find "$PASTA_INICIAL" -type f -name "*.tif" | while read -r arquivo; do

    # Verifica se o arquivo já foi processado
    if [[ "$arquivo" == *"_salvo.tif" ]]; then
        continue
    fi

    # Prepara nomes
    diretorio=$(dirname "$arquivo")
    nome_completo=$(basename "$arquivo")
    nome_sem_extensao="${nome_completo%.*}"
    arquivo_saida="${diretorio}/${nome_sem_extensao}_salvo.tif"

    echo "Processando com gdalwarp: $arquivo"

    # Executa gdalwarp
    # -srcnodata: Define qual valor na ENTRADA é "vazio"
    # -dstnodata: Define qual valor na SAÍDA será "vazio" (geralmente o mesmo)
    gdalwarp \
        -srcnodata "$VALOR_NODATA" \
        -of GTiff \
        -co COMPRESS=LZW \
        -co TILED=YES \
        -co BIGTIFF=YES \
        "$arquivo" "$arquivo_saida"

done