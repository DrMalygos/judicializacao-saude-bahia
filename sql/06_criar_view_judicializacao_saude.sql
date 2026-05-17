-- ============================================================
-- 06_create_view_judicializacao_saude.sql
-- Projeto: Judicialização da Saúde na Bahia
-- Objetivo: Criar view analítica final para consumo no Power BI
-- ============================================================
--
-- Esta view consolida pagamentos relacionados à judicialização da saúde
-- a partir de dois critérios principais:
--
-- 1. Evidência jurídica/orçamentária:
--    pagamentos que passam por filtros estruturais de saúde e possuem
--    elemento de despesa "Sentenças Judiciais" ou termos jurídicos no objeto.
--
-- 2. Evidência por medicamento:
--    pagamentos relacionados a medicamentos classificados previamente
--    como obtidos por judicialização.
-- ============================================================

CREATE OR REPLACE VIEW dados_bahia.vw_judicializacao_saude AS

WITH medicamentos_judicializacao AS (
    -- Identifica pagamentos vinculados a medicamentos marcados como
    -- obtidos por judicialização na dimensão curada de medicamentos.
    SELECT DISTINCT
        fpm.numero_pagamento
    FROM dados_bahia.fato_pagamento_medicamento fpm
    JOIN dados_bahia.dim_medicamentos dm
        ON dm.id_medicamento = fpm.id_medicamento
    WHERE dm.obtido_judicializacao = TRUE
),

base AS (
    -- Consolida a tabela fato com as dimensões necessárias para análise.
    SELECT
        f.numero_pagamento,
        f.numero_pagamento_formatado,
        f.data_pagamento,
        f.valor_pagamento,

        l.objeto,

        dcp.funcao,
        dcp.subfuncao,
        dcp.programa,
        dcp.acao,

        dcd.natureza_despesa,
        dcd.elemento_despesa,
        dcd.subelemento_despesa,

        dea.orgao,
        dea.unidade_orcamentaria,
        dea.unidade_gestora,

        dtp.tipo_pagamento,

        dcred.recebedor_pag_principal,
        dcred.cpf_cnpj_pag_principal,

        mun.uf,
        mun.nome_municipio,
        mun.municipio_uf,

        CASE
            WHEN mj.numero_pagamento IS NOT NULL THEN TRUE
            ELSE FALSE
        END AS possui_medicamento_objeto

    FROM dados_bahia.fato_nota_ordem_bancaria f

    JOIN dados_bahia.liquidacao l
        ON f.numero_liquidacao = l.numero_liquidacao

    LEFT JOIN dados_bahia.dim_classificacao_programatica dcp
        ON f.id_classificacao_programatica = dcp.id_classificacao_programatica

    LEFT JOIN dados_bahia.dim_classificacao_despesa dcd
        ON f.id_classificacao_despesa = dcd.id_classificacao_despesa

    LEFT JOIN dados_bahia.dim_estrutura_administrativa dea
        ON f.id_estrutura_administrativa = dea.id_estrutura_administrativa

    LEFT JOIN dados_bahia.dim_tipo_pagamento dtp
        ON f.id_tipo_pagamento = dtp.id_tipo_pagamento

    LEFT JOIN dados_bahia.dim_credor_principal dcred
        ON f.cod_credor_despesa = dcred.cod_credor_despesa

    LEFT JOIN dados_bahia.dim_municipios_ibge mun
        ON dcred.codigo_municipio_ibge = mun.codigo_municipio

    LEFT JOIN medicamentos_judicializacao mj
        ON mj.numero_pagamento = f.numero_pagamento
),

judicializacao_por_regra AS (
    -- Seleciona pagamentos com indícios estruturais e textuais de
    -- judicialização da saúde.
    SELECT DISTINCT
        b.numero_pagamento
    FROM base b
    WHERE b.tipo_pagamento IN (
        'PAGAMENTO PRINCIPAL',
        'SENTENÇA JUDICIAL'
    )

      AND b.funcao = 'Saúde'

      AND b.subfuncao IN (
        'Administração Geral',
        'Assistência ao Portador de Deficiência',
        'Assistência Hospitalar e Ambulatorial',
        'Outros Encargos Especiais',
        'Suporte Profilático e Terapêutico',
        'Vigilância Epidemiológica'
    )

      AND b.programa IN (
        'Saúde',
        'Cuidar Mais',
        'Saúde Mais Perto de Você',
        'Ações de Apoio Administrativo do Poder Executivo',
        'Gestão de Pessoas',
        'Operação Especial do Poder Executivo',
        'SUS Mais Forte'
    )

      AND b.acao IN (
        'Administração de Pessoal e Encargos do Grupo Ocupacional de Saúde',
        'Concessão de Órtese, Prótese, Meio Auxiliar de Locomoção e Bolsa de Ostomia',
        'Prestação de Assistência à Saúde dos Beneficiários do Planserv',
        'Assistência à Saúde em Caráter Excepcional',
        'Assistência Financeira a Usuário do SUS no Tratamento Fora do Domicílio - TFD',
        'Gerenciamento de Unidade Ambulatorial e Hospitalar sob Administração Direta',
        'Gerenciamento de Unidade Ambulatorial e Hospitalar sob Administração Indireta',
        'Implementação de Ações Estratégicas Complementares da Rede de Saúde de Média e Alta Complexidade',
        'Implantação de Unidade de Saúde',
        'Assistência Financeira a Usuário no Tratamento Fora do Domicílio',
        'Funcionamento da Rede Complementar de Serviço de Saúde de Média e Alta Complexidade',
        'Funcionamento de Unidade Ambulatorial e Hospitalar sob Administração Direta',
        'Encargos com Cumprimento de Sentença Judicial',
        'Disponibilização de Tratamento Medicamentoso em Caráter Especial',
        'Disponibilização de Fórmula Nutricional em Caráter Excepcional',
        'Disponibilização de Medicamento em Caráter Especial',
        'Apoio Institucional a Município na Implementação de Ações de Vigilância Epidemiológica',
        'Reestruturação da Rede de Frio do Programa Estadual de Imunização',
        'Requalificação da Rede de Frio do Programa Estadual de Imunização'
    )

      AND b.orgao IN (
        'Secretaria da Saúde',
        'Secretaria da Administração'
    )

      -- Exclusões identificadas durante a validação dos falsos positivos.
      AND b.unidade_gestora NOT IN (
        'Funserv - Credenciados',
        'Hospital Central Roberto Santos'
    )

      AND b.elemento_despesa IN (
        'Material de Consumo',
        'Despesas de Exercícios Anteriores',
        'Sentenças Judiciais',
        'Outros Auxílios Financeiros a Pessoas Físicas',
        'Outros Serviços de Terceiros - Pessoa Jurídica'
    )

      -- Exclusão manual de recebedor identificado como falso positivo.
      AND COALESCE(b.recebedor_pag_principal, '') <> 'Special Saude Produtos E Serviços Ltda.'

      -- Exclusões textuais curadas em tabela auxiliar.
      AND NOT EXISTS (
          SELECT 1
          FROM dados_bahia.regra_exclusao_termo_objeto x
          WHERE b.objeto ~* x.termo
      )

      -- Evidência jurídica direta: elemento judicial ou termos jurídicos no objeto.
      AND (
          b.elemento_despesa = 'Sentenças Judiciais'
          OR b.objeto ~* '(judicial|senten[çc]a|liminar|judiciais)'
      )
),

pagamentos_judicializacao AS (
    -- Consolida os pagamentos identificados por regra estrutural/textual
    -- e os pagamentos identificados pela dimensão de medicamentos.
    SELECT numero_pagamento
    FROM judicializacao_por_regra

    UNION

    SELECT numero_pagamento
    FROM medicamentos_judicializacao
)

SELECT DISTINCT
    b.numero_pagamento,
    b.numero_pagamento_formatado,
    b.data_pagamento,
    EXTRACT(YEAR FROM b.data_pagamento) AS ano_pagamento,
    b.valor_pagamento,

    b.objeto,

    b.funcao,
    b.subfuncao,
    b.programa,
    b.acao,

    b.natureza_despesa,
    b.elemento_despesa,
    b.subelemento_despesa,

    b.orgao,
    b.unidade_orcamentaria,
    b.unidade_gestora,

    b.tipo_pagamento,

    b.recebedor_pag_principal,
    b.cpf_cnpj_pag_principal,

    CASE
        WHEN b.cpf_cnpj_pag_principal IS NULL
          OR TRIM(b.cpf_cnpj_pag_principal) = ''
        THEN 'Não identificado'

        WHEN SUBSTRING(TRIM(b.cpf_cnpj_pag_principal), 4, 1) = '.'
        THEN 'Pessoa Física'

        WHEN SUBSTRING(TRIM(b.cpf_cnpj_pag_principal), 3, 1) = '.'
        THEN 'Pessoa Jurídica'

        ELSE 'Não identificado'
    END AS tipo_recebedor,

    b.municipio_uf,
    b.uf,
    b.nome_municipio,

    b.possui_medicamento_objeto

FROM pagamentos_judicializacao pj
JOIN base b
    ON b.numero_pagamento = pj.numero_pagamento;