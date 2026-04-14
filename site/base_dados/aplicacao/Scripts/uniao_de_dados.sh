#!/bin/bash

##################################################################################################################################
#Listar todos os tifs de uma pasta com subpastas
find AUDITORIAS-SC -name "*_salvo.tif" > lista_tifs_auditados.txt

######################################################################################################################################
#Gerar .vrt CASO NAO TENHA PROBLEMA NA EXTENSAO
# Teste converter um ponto ou par de coordenadas
gdalbuildvrt -srcnodata 0 -input_file_list lista_tifs_auditados.txt class_SC_auditado.vrt

gdal_translate -ot Int16 class_SC_auditado.vrt classificacao_pastagem_SC_auditado.tif -co COMPRESS=LZW
#####################################################################################################################################
##Teste 1 usando o comando que pega as coordenadas exatas do arquivo CORRETO (Moda)
gdalinfo -json Classificação_Pasture_Moda.tif

##Reprojetar para EPSG:4326
gdalwarp -overwrite \
    -t_srs EPSG:4326 \
    -tr 0.000089831528412 0.000089831528412 \
    -te -53.8974797427167 -29.4032067 -48.2833685 -25.643397932004277 \
    -r near \
    -co COMPRESS=LZW \
    class_SC_auditado.vrt\
    classificacao_auditado_ALINHADO.tif

##Visualizar mais rapido
gdaladdo class_SC_auditado_beta3.tif 2 4 8 16
####################################################################################################################################
