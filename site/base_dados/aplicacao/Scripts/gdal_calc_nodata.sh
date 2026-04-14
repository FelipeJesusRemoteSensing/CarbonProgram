#!/bin/bash

# Inicia um loop: para cada arquivo encontrado que termina em _salvo.tif...
for entrada in *_salvo.tif; do

    # Verifica se o arquivo existe mesmo (previne erros se não houver arquivos)
    [ -e "$entrada" ] || continue

    # Cria o nome do arquivo de saída
    # Pega o nome "teste_salvo.tif", remove ".tif" e adiciona "_v2.tif"
    final="${entrada%.tif}_v2.tif"

    echo "Processando: $entrada -> $final"

    # Executa o gdal_calc
    # Note que removi o espaço em --outfile e coloquei aspas nas variáveis
    gdal_calc.py -A "$entrada" \
        --type=Int16 \
        --outfile="$final" \
        --calc="(A==1)*1 + (A==2)*2 \
        --NoDataValue=0 \
        --co="COMPRESS=LZW" \
        --co="BIGTIFF=YES" \
        --co="TILED=YES"

done