import os
import csv
import numpy as np
from osgeo import gdal

# Configurações
pasta_raiz = "."  # Ponto de partida (pasta atual). O script vai descer em todas as subpastas daqui.
arquivo_saida = "relatorio_classes_geral.csv"

def processar_rasters_recursivo():
    with open(arquivo_saida, mode='w', newline='') as csv_file:
        writer = csv.writer(csv_file, delimiter=',')
        # Adicionei uma coluna 'Caminho_Pasta' para você saber de onde veio o arquivo
        writer.writerow(['Pasta', 'Nome_Arquivo', 'Qtd_Classes', 'Valores_Classes'])

        print(f"Iniciando varredura recursiva a partir de: {os.path.abspath(pasta_raiz)}\n")
        
        contador = 0

        # O os.walk viaja por todas as pastas dentro da raiz
        for root, dirs, files in os.walk(pasta_raiz):
            for arquivo in files:
                # Verifica se é TIF (ou TIFF)
                if arquivo.lower().endswith(('.tif', '.tiff')):
                    
                    # Monta o caminho dinâmico (root muda a cada pasta que ele entra)
                    caminho_completo = os.path.join(root, arquivo)
                    
                    try:
                        ds = gdal.Open(caminho_completo)
                        if ds is None:
                            continue

                        banda = ds.GetRasterBand(1)
                        dados = banda.ReadAsArray()
                        
                        # Tratamento de NoData
                        no_data_val = banda.GetNoDataValue()
                        if no_data_val is not None:
                            dados_validos = dados[dados != no_data_val]
                        else:
                            dados_validos = dados

                        # Extrai classes
                        valores_unicos = np.unique(dados_validos)
                        qtd_classes = len(valores_unicos)
                        valores_str = " ".join(map(str, valores_unicos))

                        # Salva no CSV: Pasta de origem, Nome do arquivo, Qtd, Classes
                        writer.writerow([root, arquivo, qtd_classes, valores_str])
                        
                        print(f"[OK] Encontrado em '{root}': {arquivo} -> {qtd_classes} classes")
                        contador += 1

                        ds = None # Limpa memória
                        
                    except Exception as e:
                        print(f"Erro em {caminho_completo}: {e}")

    print(f"\nFinalizado! Total de rasters processados: {contador}")
    print(f"Relatório salvo em: {arquivo_saida}")

if __name__ == "__main__":
    processar_rasters_recursivo()