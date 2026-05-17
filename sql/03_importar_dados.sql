-- ============================================================
-- 03_import_data_examples.sql
-- Projeto: Judicialização da Saúde na Bahia
-- Objetivo:
--   Exemplificar a importação dos arquivos CSV tratados para as
--   tabelas staging e dimensões auxiliares.
--
-- Observações:
--
-- 1. Este script utiliza \copy, comando executado no cliente
--    PostgreSQL (psql), e não no servidor.
--
-- 2. Os caminhos foram definidos de forma relativa ao projeto,
--    facilitando a reprodutibilidade no GitHub.
--
-- 3. Os arquivos CSV utilizados neste projeto foram previamente
--    tratados com scripts Python para corrigir:
--      - desalinhamentos de colunas;
--      - quebras de linha em campos textuais;
--      - problemas de aspas e delimitadores.
--
-- 4. Todos os arquivos utilizam:
--      - delimitador ;
--      - encoding UTF-8
--      - cabeçalho na primeira linha
-- ============================================================


-- ============================================================
-- IMPORTAÇÃO - LIQUIDAÇÃO
-- ============================================================

\copy dados_bahia.stg_liquidacao
FROM './data/VW_PAINEL_PAGAMENTO_LIQUIDACAO_LIMPO.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);


-- ============================================================
-- IMPORTAÇÃO - LIQUIDAÇÃO HISTÓRICO
-- ============================================================

\copy dados_bahia.stg_liquidacao_historico
FROM './data/VW_PAINEL_PAGAMENTO_LIQUIDACAO_HISTORICO_LIMPO.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);


-- ============================================================
-- IMPORTAÇÃO - NOTA DE ORDEM BANCÁRIA
-- ============================================================

\copy dados_bahia.stg_nota_ordem_bancaria
FROM './data/VW_PAINEL_PAGAMENTO_NOTA_ORDEM_BANCARIA_LIMPO.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);


-- ============================================================
-- IMPORTAÇÃO - NOTA DE ORDEM BANCÁRIA HISTÓRICO
-- ============================================================

\copy dados_bahia.stg_nota_ordem_bancaria_historico
FROM './data/VW_PAINEL_PAGAMENTO_NOTA_ORDEM_BANCARIA_HISTORICO_LIMPO.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);


-- ============================================================
-- IMPORTAÇÃO - DIMENSÃO DE MUNICÍPIOS (IBGE)
-- ============================================================
-- Fonte:
--   Instituto Brasileiro de Geografia e Estatística (IBGE)
--
-- Arquivo auxiliar construído a partir da base oficial de
-- municípios brasileiros.
--
-- Campos esperados:
--   codigo_municipio
--   uf
--   nome_municipio
--   municipio_uf
-- ============================================================

\copy dados_bahia.dim_municipios_ibge
FROM './data/dim_municipios_ibge.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);


-- ============================================================
-- IMPORTAÇÃO - DIMENSÃO DE MEDICAMENTOS
-- ============================================================
-- Dimensão construída manualmente a partir da análise exploratória
-- dos objetos das liquidações.
--
-- Campos esperados:
--   termo_original
--   termo_corrigido
--   substancia_ativa
--   nome_comercial
--   alto_custo
--   obtido_judicializacao
-- ============================================================

\copy dados_bahia.dim_medicamentos (
    termo_original,
    termo_corrigido,
    substancia_ativa,
    nome_comercial,
    alto_custo,
    obtido_judicializacao
)
FROM './data/dim_medicamentos.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'UTF8'
);