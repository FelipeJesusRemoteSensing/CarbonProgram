#!/bin/bash

#logica de substituicao de valores caso encontrar valor fora do esperado
gdal_calc.py -A raster_resultado.tif \
    --outfile="class_pastagem_guilherme_mod.tif" \
    --calc="(A == 0)*0 + (A == 1)*1 + ( A == 10)*1 + ( A == 11)*1 + ( A == 12)*1 + ( A == 21)*1 + (A == 4)*2 + (A == 20)*2 + ( A == 22)*2" \
    --co="COMPRESS=LZW" \
    --co="BIGTIFF=YES" \
    --co="TILED=YES"
