# Carbon Program - Iniciativa REVERTE®

Este repositório contém a documentação técnica e os protocolos para o programa de **Monitoramento de Carbono**, desenvolvido pelo Laboratório de Sensoriamento Remoto e Geoprocessamento da Universidade Federal de Goiás (**LAPIG/UFG**) em parceria com a **The Nature Conservancy (TNC)** e **Syngenta**.

O objetivo do projeto é apoiar a recuperação de áreas degradadas no Cerrado para cultivo agrícola, monitorando o sequestro de carbono orgânico no solo e a adoção de práticas de agricultura regenerativa.

## 🚀 Documentação Online

A documentação completa, incluindo metodologias, requisitos de modelagem e referências conceituais, está disponível em:
👉 **[https://FelipeJesusRemoteSensing.github.io/CarbonProgram/](https://FelipeJesusRemoteSensing.github.io/CarbonProgram/)**

## 📂 Estrutura do Repositório

- `docs/`: Arquivos fonte da documentação em Markdown.
- `docs/mds/`: Páginas específicas (Contexto, Modelagem, Scripts, etc.).
- `docs/base_dados/`: Imagens e arquivos de suporte.
- `docs/base_dados/aplicacao/Scripts/`: Contém os scripts R, Python e GEE categorizados.
- `mkdocs.yml`: Arquivo de configuração do site de documentação.

## 💻 Scripts e Automação

O projeto conta com scripts automatizados para processamento de dados geoespaciais e execução do modelo Century. Os principais fluxos incluem:

- **Extração de Dados:** Scripts GEE para download de variáveis climáticas e uso da terra.
- **Modelagem para ponto amostral** Rotinas em R para rodar o modelo Century para amostra de solo.
- **Modelagem espacializada para talhão:** Rotinas em R para rodar o modelo Century em escala de talhão.
- **Verificação dos arquivos:** Ferramentas em Python para verificação de integridade do banco de dados.

A lista detalhada e os links para cada script podem ser encontrados na página de **[Processamento e Scripts](https://FelipeJesusRemoteSensing.github.io/CarbonProgram/mds/scripts/)**.


---
**Responsáveis:** Felipe Jesus e Marcos Cardoso
**Instituição:** LAPIG / UFG
