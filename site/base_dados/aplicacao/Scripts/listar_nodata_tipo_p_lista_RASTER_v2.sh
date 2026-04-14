#!/bin/bash

###################################################################################################
##                                             OBSERVACAO
##USAR AS SEGUINTES LINHAS CASO O TERMINAL LINUX TENHA DIFICULDADE AO IDENTIFICAR O "-r"

##sed -i 's/\r$//' auditoria_dna_final.sh
##chmod +x auditoria_dna_final.sh
##./auditoria_dna_final.sh
###################################################################################################
export LC_ALL=C

# --- CONFIGURAÇÕES DO USUÁRIO ---
OUTPUT_CSV="metadados_imagens.csv" ##NOME DO ARQUIVO DE SAIDA EM CSV
LISTA_ARQUIVOS="metadados_imagens.txt" ##NOME DO ARQUIVO DE SAIDA EM TXT
PASTA_P_LER="gdrive" ##PASTA BASE ONDE OCORRERÁ A VARREDURA
NOME_ARQUIVOS="*.tif" ##NOME DOS ARQUIVOS ".TIF" QUE SERAM LIDOS

# 1. Cabeçalho com PONTO E VÍRGULA (;) para o Excel entender as colunas
echo "Arquivo;Tamanho(GB);EPSG;Tipo_Dados;NoData;DNA_Origin_X;DNA_Origin_Y;DNA_Pixel_X;DNA_Pixel_Y;Xmin;Ymin;Xmax;Ymax" > "$OUTPUT_CSV"

echo "Gerando lista de arquivos em $PASTA_P_LER..."
# O find procura dentro da pasta definida e salva os caminhos completos
find "$PASTA_P_LER" -name "$NOME_ARQUIVOS" > "$LISTA_ARQUIVOS"

if [ ! -s "$LISTA_ARQUIVOS" ]; then
    echo "Nenhum arquivo encontrado na pasta $PASTA_P_LER com o padrao $NOME_ARQUIVOS."
    exit 1
fi

# Loop para ler arquivo por arquivo
while IFS= read -r raster; do
  
  echo "Processando DNA de: $raster"
  ARQUIVO="$raster"

  # --- TAMANHO (GB) ---
  # Calcula e já converte ponto para vírgula
  TAMANHO=$(du -k "$raster" | awk '{printf "%.5f", $1/1048576}' | sed 's/\./,/g')

  # --- EXTRAÇÃO DO JSON ---
  JSON_OUTPUT=$(gdalinfo -json "$raster")

  # --- PYTHON EMBUTIDO PARA FORMATAR PADRÃO BRASILEIRO ---
  # O Python fará o trabalho sujo de formatar flutuantes e trocar ponto por vírgula
  LINHA_DADOS=$(python3 -c "
import sys, json

try:
    data = json.loads(sys.argv[1])
    
    # 1. DNA da Geometria (GeoTransform)
    # gt[0]=OrigemX, gt[3]=OrigemY, gt[1]=PixelX, gt[5]=PixelY
    gt = data.get('geoTransform', [0,0,0,0,0,0])
    
    # 2. Extensão (Bounding Box)
    corners = data.get('cornerCoordinates', {})
    ll = corners.get('lowerLeft', [0,0])
    ur = corners.get('upperRight', [0,0])
    
    # 3. Metadados Gerais
    epsg = 'Nao_Definido'
    if 'stac' in data and 'proj:epsg' in data['stac']:
        epsg = data['stac']['proj:epsg']
    elif 'coordinateSystem' in data and 'wkt' in data['coordinateSystem']:
        if 'ID[\"EPSG\",' in data['coordinateSystem']['wkt']:
            wkt = data['coordinateSystem']['wkt']
            epsg = wkt.split('ID[\"EPSG\",')[1].split(']')[0]

    # Tipo de dado e NoData
    bands = data.get('bands', [{}])
    dtype = bands[0].get('type', 'Unknown')
    nodata = bands[0].get('noDataValue', 'N/A')

    # --- FUNÇÃO DE FORMATAÇÃO BRASILEIRA ---
    def fmt(val):
        # Formata com 12 casas decimais fixas (evita E-05) e troca ponto por vírgula
        return f'{val:.12f}'.replace('.', ',')

    # Monta a linha CSV separada por PONTO E VÍRGULA
    # Ordem: EPSG;TYPE;NODATA;OriginX;OriginY;PixelX;PixelY;Xmin;Ymin;Xmax;Ymax
    saida = f\"{epsg};{dtype};{nodata};{fmt(gt[0])};{fmt(gt[3])};{fmt(gt[1])};{fmt(gt[5])};{fmt(ll[0])};{fmt(ll[1])};{fmt(ur[0])};{fmt(ur[1])}\"
    print(saida)

except Exception as e:
    # Caso o arquivo esteja corrompido
    print(\"Erro;Erro;N/A;0;0;0;0;0;0;0;0\")
" "$JSON_OUTPUT")

  # --- SALVA NO CSV ---
  echo "$ARQUIVO;$TAMANHO;$LINHA_DADOS" >> "$OUTPUT_CSV"

done < "$LISTA_ARQUIVOS"

echo "Concluído! O arquivo '$OUTPUT_CSV' foi gerado com sucesso."