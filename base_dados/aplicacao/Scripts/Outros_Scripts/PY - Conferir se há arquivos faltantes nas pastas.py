import os

def gerar_sequencia_ano_mes(ano_inicio, mes_inicio, ano_fim, mes_fim):
    """Gera um conjunto de strings no formato 'ANO_MES'."""
    sequencia = set()
    for ano in range(ano_inicio, ano_fim + 1):
        start_month = mes_inicio if ano == ano_inicio else 1
        end_month = mes_fim if ano == ano_fim else 12
        for mes in range(start_month, end_month + 1):
            sequencia.add(f"{ano}_{mes:02d}")
    return sequencia

def gerar_sequencia_lulc(ano_inicio, ano_fim):
    """Gera um conjunto de strings no formato 'ANO_lulc'."""
    sequencia = set()
    for ano in range(ano_inicio, ano_fim + 1):
        sequencia.add(f"{ano}_lulc") # Gera "1985_lulc", "1986_lulc", etc.
    return sequencia

def verificar_arquivos_nas_pastas(pasta_base_Fazendas):
    """
    Verifica a contagem de arquivos e sequências ausentes em subpastas,
    com tratamento especial para pastas 'lulc' e 'soil', e um resumo final.
    """
    print(f"Iniciando verificação na pasta base: {pasta_base_Fazendas}\n")

    sequencia_padrao_ano_mes = gerar_sequencia_ano_mes(1958, 1, 2024, 12)
    sequencia_lulc_esperada = gerar_sequencia_lulc(1985, 2023)
    
    fazendas_com_problemas = set() # Para rastrear fazendas com arquivos ausentes

    if not os.path.exists(pasta_base_Fazendas):
        print(f"ERRO: A pasta base '{pasta_base_Fazendas}' não foi encontrada.")
        return

    for nome_pasta_fazenda in os.listdir(pasta_base_Fazendas):
        caminho_pasta_fazenda = os.path.join(pasta_base_Fazendas, nome_pasta_fazenda)

        if os.path.isdir(caminho_pasta_fazenda):
            print(f"--- Fazenda: {nome_pasta_fazenda} ---")
            
            for nome_subpasta_dados in os.listdir(caminho_pasta_fazenda):
                caminho_subpasta_dados = os.path.join(caminho_pasta_fazenda, nome_subpasta_dados)

                if os.path.isdir(caminho_subpasta_dados):
                    print(f"  Subpasta de Dados: {nome_subpasta_dados}")

                    arquivos_na_subpasta = [
                        f for f in os.listdir(caminho_subpasta_dados)
                        if os.path.isfile(os.path.join(caminho_subpasta_dados, f))
                    ]
                    contagem_arquivos = len(arquivos_na_subpasta)
                    print(f"    Contagem de arquivos: {contagem_arquivos}")

                    # Lógica específica para 'lulc_mb_col9_30m'
                    if nome_subpasta_dados == "lulc_mb_col9_30m":
                        if contagem_arquivos == 0:
                            if sequencia_lulc_esperada: # Verifica se a sequência esperada não é vazia
                                print(f"    Todos os {len(sequencia_lulc_esperada)} arquivos da sequência LULC (1985_lulc a 2023_lulc) estão ausentes.")
                                fazendas_com_problemas.add(nome_pasta_fazenda)
                            else:
                                print(f"    Nenhum arquivo encontrado e nenhuma sequência LULC definida para verificar.")
                        else: # contagem_arquivos > 0
                            arquivos_lulc_presentes_formatados = set()
                            for nome_arquivo in arquivos_na_subpasta:
                                nome_base, _ = os.path.splitext(nome_arquivo)
                                partes_nome_base = nome_base.split('_')
                                if len(partes_nome_base) >= 2 and \
                                   partes_nome_base[0].isdigit() and len(partes_nome_base[0]) == 4 and \
                                   partes_nome_base[1].lower() == "lulc":
                                    ano_lulc_extraido = f"{partes_nome_base[0]}_{partes_nome_base[1].lower()}"
                                    arquivos_lulc_presentes_formatados.add(ano_lulc_extraido)
                            
                            arquivos_lulc_ausentes = sorted(list(sequencia_lulc_esperada - arquivos_lulc_presentes_formatados))
                            if arquivos_lulc_ausentes:
                                print(f"    Arquivos ausentes na sequência LULC (1985_lulc a 2023_lulc):")
                                limite_mostrar_ausentes = 20
                                for i, ausente in enumerate(arquivos_lulc_ausentes):
                                    if i < limite_mostrar_ausentes:
                                        print(f"      - {ausente}")
                                    elif i == limite_mostrar_ausentes:
                                        print(f"      ... e mais {len(arquivos_lulc_ausentes) - limite_mostrar_ausentes} outros.")
                                        break
                                fazendas_com_problemas.add(nome_pasta_fazenda)
                            else:
                                print(f"    Sequência LULC (1985_lulc a 2023_lulc) está completa.")
                    
                    # Lógica específica para 'soil_pronassolos_30m'
                    elif nome_subpasta_dados == "soil_pronassolos_30m":
                        if contagem_arquivos > 0:
                            print(f"    Arquivos presentes (identificador e nome completo):")
                            for nome_arquivo in arquivos_na_subpasta:
                                identificador_arquivo = nome_arquivo.split('_')[0] 
                                print(f"      - Identificador: \"{identificador_arquivo}\", Arquivo: \"{nome_arquivo}\"")
                        # else: (Nenhuma mensagem específica se 0 arquivos para soil, pois já foi impresso "Contagem de arquivos: 0")
                    
                    # Lógica padrão para outras subpastas de dados
                    else:
                        if contagem_arquivos == 0:
                            if sequencia_padrao_ano_mes: # Verifica se a sequência esperada não é vazia
                                print(f"    Todos os {len(sequencia_padrao_ano_mes)} arquivos da sequência padrão (1958_01 a 2024_12) estão ausentes.")
                                fazendas_com_problemas.add(nome_pasta_fazenda)
                            else:
                                print(f"    Nenhum arquivo encontrado e nenhuma sequência padrão definida para verificar.")
                        else: # contagem_arquivos > 0
                            arquivos_ano_mes_presentes = set()
                            for nome_arquivo in arquivos_na_subpasta:
                                nome_base, _ = os.path.splitext(nome_arquivo)
                                partes_nome_base = nome_base.split('_')
                                if len(partes_nome_base) >= 2 and \
                                   partes_nome_base[0].isdigit() and len(partes_nome_base[0]) == 4 and \
                                   partes_nome_base[1].isdigit() and len(partes_nome_base[1]) == 2:
                                    ano_mes_extraido = f"{partes_nome_base[0]}_{partes_nome_base[1]}"
                                    arquivos_ano_mes_presentes.add(ano_mes_extraido)
                            
                            arquivos_ano_mes_ausentes = sorted(list(sequencia_padrao_ano_mes - arquivos_ano_mes_presentes))
                            if arquivos_ano_mes_ausentes:
                                print(f"    Arquivos ausentes na sequência padrão (1958_01 a 2024_12):")
                                limite_mostrar_ausentes = 20
                                for i, ausente in enumerate(arquivos_ano_mes_ausentes):
                                    if i < limite_mostrar_ausentes:
                                        print(f"      - {ausente}")
                                    elif i == limite_mostrar_ausentes:
                                        print(f"      ... e mais {len(arquivos_ano_mes_ausentes) - limite_mostrar_ausentes} outros.")
                                        break
                                fazendas_com_problemas.add(nome_pasta_fazenda)
                            else:
                                print(f"    Sequência padrão (1958_01 a 2024_12) está completa.")
            print("") 
    
    # Resumo Final
    print("\n--- RESUMO FINAL DA VERIFICAÇÃO ---")
    if not fazendas_com_problemas:
        print("Tudo OK! Todas as fazendas parecem ter as sequências de arquivos completas onde aplicável.")
    else:
        print("ATENÇÃO! As seguintes fazendas apresentaram problemas (arquivos ausentes em sequências):")
        for nome_fazenda_problematica in sorted(list(fazendas_com_problemas)):
            print(f"  - {nome_fazenda_problematica}")
    print("-----------------------------------")


if __name__ == "__main__":
    pasta_alvo = r"D:\Projetos-Lapig\century\revert\rasters\Fazendas"
    verificar_arquivos_nas_pastas(pasta_alvo)
    # A mensagem "Verificação concluída." agora faz parte do resumo dentro da função.

    