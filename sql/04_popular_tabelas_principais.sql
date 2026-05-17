-- ============================================================
-- 04_populate_core_tables.sql
-- Projeto: Judicialização da Saúde na Bahia
-- Objetivo:
--   Popular as tabelas finais do modelo a partir das tabelas staging.
--
-- Etapas:
--   1. Unificar arquivos atuais e históricos em tabelas temporárias;
--   2. Popular a tabela final liquidacao;
--   3. Popular dimensões;
--   4. Popular a tabela fato de pagamentos.
--
-- Observação:
--   As tabelas staging armazenam os dados como TEXT. Nesta etapa,
--   são feitas conversões de tipos, deduplicações e relacionamentos
--   com as dimensões.
-- ============================================================


-- ============================================================
-- 1. TABELA TEMPORÁRIA PADRONIZADA - LIQUIDAÇÃO
-- ============================================================
-- Une liquidação atual e histórica em uma única base temporária.

DROP TABLE IF EXISTS tmp_liquidacao;

CREATE TEMP TABLE tmp_liquidacao AS
SELECT
    TRIM(numero_liquidacao) AS numero_liquidacao,
    TRIM(objeto) AS objeto,
    TRIM(numero_instrumento) AS numero_instrumento,
    TRIM(data_liquidacao) AS data_liquidacao,
    TRIM(valor_liquidacao) AS valor_liquidacao
FROM dados_bahia.stg_liquidacao

UNION ALL

SELECT
    TRIM(numero_liquidacao) AS numero_liquidacao,
    TRIM(objeto) AS objeto,
    TRIM(numero_instrumento) AS numero_instrumento,
    TRIM(data_liquidacao) AS data_liquidacao,
    TRIM(valor_liquidacao) AS valor_liquidacao
FROM dados_bahia.stg_liquidacao_historico;


-- ============================================================
-- 2. TABELA TEMPORÁRIA PADRONIZADA - NOTA DE ORDEM BANCÁRIA
-- ============================================================
-- Une pagamentos atuais e históricos.
-- Como os arquivos possuem pequenas diferenças nos nomes das colunas,
-- os campos são padronizados nesta etapa.

DROP TABLE IF EXISTS tmp_nota_ordem_bancaria;

CREATE TEMP TABLE tmp_nota_ordem_bancaria AS

SELECT
    TRIM("Nº da Liquidação") AS numero_liquidacao,
    TRIM("COD_CREDOR_DESPESA") AS cod_credor_despesa,
    TRIM("Recebedor do pag principal") AS recebedor_pag_principal,
    TRIM("Código do Município/IBGE") AS codigo_municipio_ibge,
    TRIM("CPF/CNPJ Credor do Pagamento Principal") AS cpf_cnpj_pag_principal,
    TRIM("COD_CREDOR_DESPESA_PAGAMENTO") AS cod_credor_despesa_pagamento,
    TRIM("Nº do Pagamento") AS numero_pagamento,
    TRIM("Nº do Pagamento Formatado") AS numero_pagamento_formatado,
    TRIM("Poder/Órgão Autônomo") AS poder_orgao_autonomo,
    TRIM("Órgão") AS orgao,
    TRIM("Unidade Orçamentária") AS unidade_orcamentaria,
    TRIM("Unidade Gestora") AS unidade_gestora,
    TRIM("Função") AS funcao,
    TRIM("Subfunção") AS subfuncao,
    TRIM("Programa") AS programa,
    TRIM("Ação") AS acao,
    TRIM("Natureza da Despesa") AS natureza_despesa,
    TRIM("Elemento da Despesa") AS elemento_despesa,
    TRIM("Subelemento da Despesa") AS subelemento_despesa,
    TRIM("Código da Consignataria") AS codigo_consignataria,
    TRIM("Tipo de Pagamento") AS tipo_pagamento,
    TRIM("Consignataria") AS consignataria,
    TRIM("Data do Pagamento") AS data_pagamento,
    TRIM("Valor do Pagamento") AS valor_pagamento,
    TRIM("Pagamento Efetivado") AS pagamento_efetivado
FROM dados_bahia.stg_nota_ordem_bancaria

UNION ALL

SELECT
    TRIM("Nº da Liquidação") AS numero_liquidacao,
    TRIM(cod_credor_despesa) AS cod_credor_despesa,
    TRIM("Recebedor do pag principal") AS recebedor_pag_principal,
    TRIM("Código do MunicípioIBGE") AS codigo_municipio_ibge,
    TRIM("CPFCNPJ Credor do Pagamento Principal") AS cpf_cnpj_pag_principal,
    TRIM(cod_credor_despesa_pagamento) AS cod_credor_despesa_pagamento,
    TRIM("Nº do Pagamento") AS numero_pagamento,
    TRIM("Nº do Pagamento Formatado") AS numero_pagamento_formatado,
    TRIM("PoderÓrgão Autônomo") AS poder_orgao_autonomo,
    TRIM(órgão) AS orgao,
    TRIM("Unidade Orçamentária") AS unidade_orcamentaria,
    TRIM("Unidade Gestora") AS unidade_gestora,
    TRIM(função) AS funcao,
    TRIM(subfunção) AS subfuncao,
    TRIM(programa) AS programa,
    TRIM(ação) AS acao,
    TRIM("Natureza da Despesa") AS natureza_despesa,
    TRIM("Elemento da Despesa") AS elemento_despesa,
    TRIM("Subelemento da Despesa") AS subelemento_despesa,
    TRIM("Código da Consignataria") AS codigo_consignataria,
    TRIM("Tipo de Pagamento") AS tipo_pagamento,
    TRIM(consignataria) AS consignataria,
    TRIM("Data do Pagamento") AS data_pagamento,
    TRIM("Valor do Pagamento") AS valor_pagamento,
    TRIM("Pagamento Efetivado") AS pagamento_efetivado
FROM dados_bahia.stg_nota_ordem_bancaria_historico;


-- ============================================================
-- 3. POVOAMENTO - TABELA FINAL LIQUIDAÇÃO
-- ============================================================
-- Insere liquidações atuais e históricas em uma única tabela final.
-- DISTINCT ON evita duplicidade de numero_liquidacao.

INSERT INTO dados_bahia.liquidacao (
    numero_liquidacao,
    objeto,
    numero_instrumento,
    data_liquidacao,
    valor_liquidacao
)
SELECT DISTINCT ON (numero_liquidacao::BIGINT)
    numero_liquidacao::BIGINT,
    objeto,
    NULLIF(numero_instrumento, ''),
    TO_DATE(data_liquidacao, 'DD/MM/YYYY'),
    REPLACE(valor_liquidacao, ',', '.')::NUMERIC(18,2)
FROM tmp_liquidacao
WHERE numero_liquidacao ~ '^[0-9]+$'
  AND data_liquidacao ~ '^\d{2}/\d{2}/\d{4}$'
  AND valor_liquidacao ~ '^\d+([,.]\d{2})?$'
ORDER BY
    numero_liquidacao::BIGINT,
    data_liquidacao DESC;


-- ============================================================
-- 4. POVOAMENTO - DIMENSÃO CREDOR PRINCIPAL
-- ============================================================
-- Para cada código de credor, escolhe um único registro representativo.
-- Quando há nomes anonimizados com "*", eles são preteridos.

WITH base AS (
    SELECT
        cod_credor_despesa,
        recebedor_pag_principal,
        codigo_municipio_ibge,
        cpf_cnpj_pag_principal
    FROM tmp_nota_ordem_bancaria
    WHERE cod_credor_despesa ~ '^[0-9]+$'
),

agrupado AS (
    SELECT
        cod_credor_despesa,
        recebedor_pag_principal,
        codigo_municipio_ibge,
        cpf_cnpj_pag_principal,
        COUNT(*) AS qtd_registros,
        CASE
            WHEN recebedor_pag_principal LIKE '%*%' THEN 1
            ELSE 0
        END AS nome_anonimizado
    FROM base
    GROUP BY
        cod_credor_despesa,
        recebedor_pag_principal,
        codigo_municipio_ibge,
        cpf_cnpj_pag_principal
),

ranqueado AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY cod_credor_despesa
            ORDER BY
                nome_anonimizado,
                qtd_registros DESC,
                recebedor_pag_principal
        ) AS rn
    FROM agrupado
)

INSERT INTO dados_bahia.dim_credor_principal (
    cod_credor_despesa,
    recebedor_pag_principal,
    codigo_municipio_ibge,
    cpf_cnpj_pag_principal
)
SELECT
    cod_credor_despesa::INTEGER,
    recebedor_pag_principal,
    CASE
        WHEN codigo_municipio_ibge ~ '^[0-9]+$'
        THEN codigo_municipio_ibge::INTEGER
    END AS codigo_municipio_ibge,
    cpf_cnpj_pag_principal
FROM ranqueado
WHERE rn = 1;


-- ============================================================
-- 5. POVOAMENTO - DIMENSÃO ESTRUTURA ADMINISTRATIVA
-- ============================================================

INSERT INTO dados_bahia.dim_estrutura_administrativa (
    poder_orgao_autonomo,
    orgao,
    unidade_orcamentaria,
    unidade_gestora
)
SELECT DISTINCT
    poder_orgao_autonomo,
    orgao,
    unidade_orcamentaria,
    unidade_gestora
FROM tmp_nota_ordem_bancaria
WHERE COALESCE(poder_orgao_autonomo, '') <> ''
  AND COALESCE(orgao, '') <> ''
  AND COALESCE(unidade_orcamentaria, '') <> ''
  AND COALESCE(unidade_gestora, '') <> '';


-- ============================================================
-- 6. POVOAMENTO - DIMENSÃO CLASSIFICAÇÃO PROGRAMÁTICA
-- ============================================================

INSERT INTO dados_bahia.dim_classificacao_programatica (
    funcao,
    subfuncao,
    programa,
    acao
)
SELECT DISTINCT
    funcao,
    subfuncao,
    programa,
    acao
FROM tmp_nota_ordem_bancaria
WHERE COALESCE(funcao, '') <> ''
  AND COALESCE(subfuncao, '') <> ''
  AND COALESCE(programa, '') <> ''
  AND COALESCE(acao, '') <> '';


-- ============================================================
-- 7. POVOAMENTO - DIMENSÃO CLASSIFICAÇÃO DA DESPESA
-- ============================================================

INSERT INTO dados_bahia.dim_classificacao_despesa (
    natureza_despesa,
    elemento_despesa,
    subelemento_despesa
)
SELECT DISTINCT
    natureza_despesa,
    elemento_despesa,
    subelemento_despesa
FROM tmp_nota_ordem_bancaria
WHERE COALESCE(natureza_despesa, '') <> ''
  AND COALESCE(elemento_despesa, '') <> ''
  AND COALESCE(subelemento_despesa, '') <> '';


-- ============================================================
-- 8. POVOAMENTO - DIMENSÃO TIPO DE PAGAMENTO
-- ============================================================

INSERT INTO dados_bahia.dim_tipo_pagamento (
    codigo_consignataria,
    tipo_pagamento,
    consignataria,
    pagamento_efetivado
)
SELECT DISTINCT
    NULLIF(codigo_consignataria, ''),
    tipo_pagamento,
    NULLIF(consignataria, ''),
    NULLIF(pagamento_efetivado, '')
FROM tmp_nota_ordem_bancaria
WHERE COALESCE(tipo_pagamento, '') <> '';


-- ============================================================
-- 9. POVOAMENTO - TABELA FATO NOTA DE ORDEM BANCÁRIA
-- ============================================================
-- Insere pagamentos atuais e históricos em uma única tabela fato.
-- A condição EXISTS garante que apenas pagamentos com liquidação válida
-- sejam carregados.

INSERT INTO dados_bahia.fato_nota_ordem_bancaria (
    numero_pagamento,
    numero_pagamento_formatado,
    numero_liquidacao,
    data_pagamento,
    valor_pagamento,
    cod_credor_despesa_pagamento,
    cod_credor_despesa,
    id_estrutura_administrativa,
    id_classificacao_programatica,
    id_classificacao_despesa,
    id_tipo_pagamento
)
SELECT DISTINCT ON (s.numero_pagamento::BIGINT)
    s.numero_pagamento::BIGINT,
    s.numero_pagamento_formatado,
    s.numero_liquidacao::BIGINT,

    CASE
        WHEN s.data_pagamento ~ '^\d{2}/\d{2}/\d{4}$'
        THEN TO_DATE(s.data_pagamento, 'DD/MM/YYYY')
    END AS data_pagamento,

    CASE
        WHEN s.valor_pagamento ~ '^\d+([,.]\d{2})?$'
        THEN REPLACE(s.valor_pagamento, ',', '.')::NUMERIC(18,2)
    END AS valor_pagamento,

    CASE
        WHEN s.cod_credor_despesa_pagamento ~ '^[0-9]+$'
        THEN s.cod_credor_despesa_pagamento::INTEGER
    END AS cod_credor_despesa_pagamento,

    CASE
        WHEN s.cod_credor_despesa ~ '^[0-9]+$'
        THEN s.cod_credor_despesa::INTEGER
    END AS cod_credor_despesa,

    dea.id_estrutura_administrativa,
    dcp.id_classificacao_programatica,
    dcd.id_classificacao_despesa,
    dtp.id_tipo_pagamento

FROM tmp_nota_ordem_bancaria s

LEFT JOIN dados_bahia.dim_estrutura_administrativa dea
    ON s.poder_orgao_autonomo = dea.poder_orgao_autonomo
   AND s.orgao = dea.orgao
   AND s.unidade_orcamentaria = dea.unidade_orcamentaria
   AND s.unidade_gestora = dea.unidade_gestora

LEFT JOIN dados_bahia.dim_classificacao_programatica dcp
    ON s.funcao = dcp.funcao
   AND s.subfuncao = dcp.subfuncao
   AND s.programa = dcp.programa
   AND s.acao = dcp.acao

LEFT JOIN dados_bahia.dim_classificacao_despesa dcd
    ON s.natureza_despesa = dcd.natureza_despesa
   AND s.elemento_despesa = dcd.elemento_despesa
   AND s.subelemento_despesa = dcd.subelemento_despesa

LEFT JOIN dados_bahia.dim_tipo_pagamento dtp
    ON COALESCE(s.codigo_consignataria, '') = COALESCE(dtp.codigo_consignataria, '')
   AND s.tipo_pagamento = dtp.tipo_pagamento
   AND COALESCE(s.consignataria, '') = COALESCE(dtp.consignataria, '')
   AND COALESCE(s.pagamento_efetivado, '') = COALESCE(dtp.pagamento_efetivado, '')

WHERE s.numero_pagamento ~ '^[0-9]+$'
  AND s.numero_liquidacao ~ '^[0-9]+$'
  AND EXISTS (
      SELECT 1
      FROM dados_bahia.liquidacao l
      WHERE l.numero_liquidacao = s.numero_liquidacao::BIGINT
  )
ORDER BY
    s.numero_pagamento::BIGINT,
    s.data_pagamento DESC;