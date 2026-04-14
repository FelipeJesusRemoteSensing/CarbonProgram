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
- **Espacialização:** Rotinas em R para rodar o modelo Century em escala de talhão.
- **Validação:** Ferramentas em Python para verificação de integridade do banco de dados.

A lista detalhada e os links para cada script podem ser encontrados na página de **[Processos (Scripts)](https://FelipeJesusRemoteSensing.github.io/CarbonProgram/mds/scripts/)**.

## 🛠️ Como rodar localmente

Para visualizar a documentação em seu computador:

1. Instale o Python (se não o tiver).
2. Instale o MkDocs e o tema ReadTheDocs:
   ```bash
   pip install mkdocs mkdocs-readthedocs-theme
   ```
3. No terminal, dentro da pasta do projeto, execute:
   ```bash
   mkdocs serve
   ```
4. Acesse `http://127.0.0.1:8000/` no seu navegador.

---
**Responsável:** Felipe Jesus  
**Instituição:** LAPIG / UFG
