-- ============================================================
-- 02_create_tables.sql
-- Projeto: Judicialização da Saúde na Bahia
-- Objetivo:
--   Criar as tabelas staging, dimensões, tabelas fato e tabelas
--   auxiliares utilizadas no projeto.
--
-- Observação:
--   As tabelas staging armazenam os dados importados dos CSVs tratados
--   com Python. Por isso, seus campos são mantidos como TEXT, evitando
--   falhas de importação causadas por inconsistências nos arquivos
--   originais.
-- ============================================================


-- ============================================================
-- STAGING - LIQUIDAÇÃO
-- ============================================================

DROP TABLE IF EXISTS dados_bahia.stg_liquidacao;

CREATE TABLE dados_bahia.stg_liquidacao (
    numero_liquidacao TEXT,
    objeto TEXT,
    numero_instrumento TEXT,
    data_liquidacao TEXT,
    valor_liquidacao TEXT
);


-- ============================================================
-- STAGING - LIQUIDAÇÃO HISTÓRICO
-- ============================================================

DROP TABLE IF EXISTS dados_bahia.stg_liquidacao_historico;

CREATE TABLE dados_bahia.stg_liquidacao_historico (
    numero_liquidacao TEXT,
    objeto TEXT,
    numero_instrumento TEXT,
    data_liquidacao TEXT,
    valor_liquidacao TEXT
);


-- ============================================================
-- STAGING - NOTA DE ORDEM BANCÁRIA
-- ============================================================

DROP TABLE IF EXISTS dados_bahia.stg_nota_ordem_bancaria;

CREATE TABLE dados_bahia.stg_nota_ordem_bancaria (
    "Nº da Liquidação" TEXT,
    "COD_CREDOR_DESPESA" TEXT,
    "Recebedor do pag principal" TEXT,
    "Código do Município/IBGE" TEXT,
    "CPF/CNPJ Credor do Pagamento Principal" TEXT,
    "COD_CREDOR_DESPESA_PAGAMENTO" TEXT,
    "Recebedor" TEXT,
    "CPF/CNPJ Credor do Pagamento" TEXT,
    "Nº do Pagamento" TEXT,
    "Nº do Pagamento Formatado" TEXT,
    "Código do Poder/Órgão Autônomo" TEXT,
    "Poder/Órgão Autônomo" TEXT,
    "Órgão" TEXT,
    "Sigla do Órgão" TEXT,
    "Sigla da Unidade Orçamentária" TEXT,
    "Unidade Orçamentária" TEXT,
    "Código da Unidade Gestora" TEXT,
    "Sigla da Unidade Gestora" TEXT,
    "Unidade Gestora" TEXT,
    "NUM_EMPENHO_ORCAMENTO" TEXT,
    "Nº do Empenho" TEXT,
    "Função" TEXT,
    "Subfunção" TEXT,
    "Programa" TEXT,
    "Ação" TEXT,
    "Modalidade da Licitação" TEXT,
    "Tipo do Empenho" TEXT,
    "Natureza da Despesa" TEXT,
    "Código Elemento da Despesa" TEXT,
    "Elemento da Despesa" TEXT,
    "Subelemento da Despesa" TEXT,
    "Código da Consignataria" TEXT,
    "Tipo de Pagamento" TEXT,
    "Consignataria" TEXT,
    "Data do Pagamento" TEXT,
    "Valor do Pagamento" TEXT,
    "Nº LID" TEXT,
    "Nº do Processo de Licitação/Inexigibilidade/Dispensa" TEXT,
    num_instrumento TEXT,
    num_instrumento_formatado TEXT,
    "CodTipoInstrumento" TEXT,
    "val_GCV" TEXT,
    "Data do Vencimento da Despesa" TEXT,
    "Pagamento Efetivado" TEXT
);


-- ============================================================
-- STAGING - NOTA DE ORDEM BANCÁRIA HISTÓRICO
-- ============================================================

DROP TABLE IF EXISTS dados_bahia.stg_nota_ordem_bancaria_historico;

CREATE TABLE dados_bahia.stg_nota_ordem_bancaria_historico (
    "Nº da Liquidação" TEXT,
    cod_credor_despesa TEXT,
    "Recebedor do pag principal" TEXT,
    "Código do MunicípioIBGE" TEXT,
    "CPFCNPJ Credor do Pagamento Principal" TEXT,
    cod_credor_despesa_pagamento TEXT,
    recebedor TEXT,
    "CPFCNPJ Credor do Pagamento" TEXT,
    "Nº do Pagamento" TEXT,
    "Nº do Pagamento Formatado" TEXT,
    "Código do PoderÓrgão Autônomo" TEXT,
    "PoderÓrgão Autônomo" TEXT,
    órgão TEXT,
    "Sigla do Órgão" TEXT,
    "Sigla da Unidade Orçamentária" TEXT,
    "Unidade Orçamentária" TEXT,
    "Código da Unidade Gestora" TEXT,
    "Sigla da Unidade Gestora" TEXT,
    "Unidade Gestora" TEXT,
    num_empenho_orcamento TEXT,
    "Nº do Empenho" TEXT,
    função TEXT,
    subfunção TEXT,
    programa TEXT,
    ação TEXT,
    "Modalidade da Licitação" TEXT,
    "Tipo do Empenho" TEXT,
    "Natureza da Despesa" TEXT,
    "Código Elemento da Despesa" TEXT,
    "Elemento da Despesa" TEXT,
    "Subelemento da Despesa" TEXT,
    "Código da Consignataria" TEXT,
    "Tipo de Pagamento" TEXT,
    consignataria TEXT,
    "Data do Pagamento" TEXT,
    "Valor do Pagamento" TEXT,
    "Nº LID" TEXT,
    "Nº do Processo de LicitaçãoInexigibilidadeDispensa" TEXT,
    num_instrumento TEXT,
    num_instrumento_formatado TEXT,
    codtipoinstrumento TEXT,
    val_gcv TEXT,
    "Data do Vencimento da Despesa" TEXT,
    "Pagamento Efetivado" TEXT
);


-- ============================================================
-- DIMENSÃO - CLASSIFICAÇÃO DA DESPESA
-- ============================================================

DROP TABLE IF EXISTS dados_bahia.dim_classificacao_despesa CASCADE;

CREATE TABLE dados_bahia.dim_classificacao_despesa (
    id_classificacao_despesa SERIAL PRIMARY KEY,
    natureza_despesa TEXT NOT NULL,
    elemento_despesa TEXT NOT NULL,
    subelemento_despesa TEXT NOT NULL
);


-- ============================================================
-- DIMENSÃO - CLASSIFICAÇÃO PROGRAMÁTICA
-- ============================================================

DROP TABLE IF EXISTS dados_bahia.dim_classificacao_programatica CASCADE;

CREATE TABLE dados_bahia.dim_classificacao_programatica (
    id_classificacao_programatica SERIAL PRIMARY KEY,
    funcao TEXT NOT NULL,
    subfuncao TEXT NOT NULL,
    programa TEXT NOT NULL,
    acao TEXT NOT NULL
);


-- ============================================================
-- DIMENSÃO - ESTRUTURA ADMINISTRATIVA
-- ============================================================

DROP TABLE IF EXISTS dados_bahia.dim_estrutura_administrativa CASCADE;

CREATE TABLE dados_bahia.dim_estrutura_administrativa (
    id_estrutura_administrativa SERIAL PRIMARY KEY,
    poder_orgao_autonomo TEXT NOT NULL,
    orgao TEXT NOT NULL,
    unidade_orcamentaria TEXT NOT NULL,
    unidade_gestora TEXT NOT NULL
);


-- ============================================================
-- DIMENSÃO - TIPO DE PAGAMENTO
-- ============================================================

DROP TABLE IF EXISTS dados_bahia.dim_tipo_pagamento CASCADE;

CREATE TABLE dados_bahia.dim_tipo_pagamento (
    id_tipo_pagamento SERIAL PRIMARY KEY,
    codigo_consignataria TEXT,
    tipo_pagamento TEXT NOT NULL,
    consignataria TEXT,
    pagamento_efetivado TEXT
);


-- ============================================================
-- DIMENSÃO - CREDOR PRINCIPAL
-- ============================================================

DROP TABLE IF EXISTS dados_bahia.dim_credor_principal CASCADE;

CREATE TABLE dados_bahia.dim_credor_principal (
    cod_credor_despesa INTEGER PRIMARY KEY,
    recebedor_pag_principal TEXT NOT NULL,
    codigo_municipio_ibge INTEGER,
    cpf_cnpj_pag_principal TEXT
);


-- ============================================================
-- DIMENSÃO - MEDICAMENTOS
-- ============================================================
-- Tabela curada manualmente a partir da análise exploratória dos
-- objetos das liquidações.
--
-- Armazena termos originais encontrados nos textos, correções,
-- substâncias ativas, nomes comerciais e flags auxiliares.

DROP TABLE IF EXISTS dados_bahia.dim_medicamentos CASCADE;

CREATE TABLE dados_bahia.dim_medicamentos (
    id_medicamento SERIAL PRIMARY KEY,
    termo_original TEXT UNIQUE,
    termo_corrigido TEXT,
    substancia_ativa TEXT,
    nome_comercial TEXT,
    alto_custo BOOLEAN,
    obtido_judicializacao BOOLEAN
);


-- ============================================================
-- DIMENSÃO - MUNICÍPIOS IBGE
-- ============================================================
-- Tabela auxiliar construída a partir dos códigos oficiais de
-- municípios do IBGE.

DROP TABLE IF EXISTS dados_bahia.dim_municipios_ibge CASCADE;

CREATE TABLE dados_bahia.dim_municipios_ibge (
    codigo_municipio INTEGER PRIMARY KEY,
    uf TEXT,
    nome_municipio TEXT,
    municipio_uf TEXT
);


-- ============================================================
-- TABELA FINAL - LIQUIDAÇÃO
-- ============================================================
-- Armazena os dados tratados das liquidações.
-- A coluna "objeto" é central para a classificação textual da
-- judicialização da saúde.

DROP TABLE IF EXISTS dados_bahia.liquidacao CASCADE;

CREATE TABLE dados_bahia.liquidacao (
    numero_liquidacao BIGINT PRIMARY KEY,
    objeto TEXT,
    numero_instrumento TEXT,
    data_liquidacao DATE NOT NULL,
    valor_liquidacao NUMERIC(18,2) NOT NULL
);


-- ============================================================
-- TABELA FATO - NOTA DE ORDEM BANCÁRIA
-- ============================================================
-- Tabela central de pagamentos.
--
-- Observação:
--   A coluna numero_empenho foi removida desta versão reprodutível,
--   pois a tabela de empenhos não será utilizada no fluxo final do
--   portfólio.

DROP TABLE IF EXISTS dados_bahia.fato_nota_ordem_bancaria CASCADE;

CREATE TABLE dados_bahia.fato_nota_ordem_bancaria (
    numero_pagamento BIGINT PRIMARY KEY,
    numero_pagamento_formatado TEXT,
    numero_liquidacao BIGINT NOT NULL,
    data_pagamento DATE,
    valor_pagamento NUMERIC(18,2),
    cod_credor_despesa_pagamento INTEGER,
    cod_credor_despesa INTEGER,
    id_estrutura_administrativa INTEGER,
    id_classificacao_programatica INTEGER,
    id_classificacao_despesa INTEGER,
    id_tipo_pagamento INTEGER,

    CONSTRAINT fk_fato_nob_liquidacao
        FOREIGN KEY (numero_liquidacao)
        REFERENCES dados_bahia.liquidacao(numero_liquidacao),

    CONSTRAINT fk_fato_nob_credor_principal
        FOREIGN KEY (cod_credor_despesa)
        REFERENCES dados_bahia.dim_credor_principal(cod_credor_despesa),

    CONSTRAINT fk_fato_nob_estrutura
        FOREIGN KEY (id_estrutura_administrativa)
        REFERENCES dados_bahia.dim_estrutura_administrativa(id_estrutura_administrativa),

    CONSTRAINT fk_fato_nob_class_prog
        FOREIGN KEY (id_classificacao_programatica)
        REFERENCES dados_bahia.dim_classificacao_programatica(id_classificacao_programatica),

    CONSTRAINT fk_fato_nob_class_desp
        FOREIGN KEY (id_classificacao_despesa)
        REFERENCES dados_bahia.dim_classificacao_despesa(id_classificacao_despesa),

    CONSTRAINT fk_fato_nob_tipo_pag
        FOREIGN KEY (id_tipo_pagamento)
        REFERENCES dados_bahia.dim_tipo_pagamento(id_tipo_pagamento)
);


-- ============================================================
-- TABELA FATO - PAGAMENTO MEDICAMENTO
-- ============================================================
-- Tabela de relacionamento entre pagamentos e medicamentos
-- identificados no campo "objeto" da liquidação.
--
-- Um pagamento pode mencionar mais de um medicamento, e um mesmo
-- medicamento pode aparecer em vários pagamentos.

DROP TABLE IF EXISTS dados_bahia.fato_pagamento_medicamento CASCADE;

CREATE TABLE dados_bahia.fato_pagamento_medicamento (
    numero_pagamento BIGINT NOT NULL,
    id_medicamento INTEGER NOT NULL,
    substancia_ativa TEXT,
    nome_comercial TEXT,
    alto_custo BOOLEAN,
    objeto TEXT,
    objeto_normalizado TEXT,

    CONSTRAINT fato_pagamento_medicamento_pkey
        PRIMARY KEY (numero_pagamento, id_medicamento),

    CONSTRAINT fk_fato_pag_med_pagamento
        FOREIGN KEY (numero_pagamento)
        REFERENCES dados_bahia.fato_nota_ordem_bancaria(numero_pagamento),

    CONSTRAINT fk_fato_pag_med_medicamento
        FOREIGN KEY (id_medicamento)
        REFERENCES dados_bahia.dim_medicamentos(id_medicamento)
);


-- ============================================================
-- REGRA - EXCLUSÃO POR TERMO NO OBJETO
-- ============================================================
-- Tabela auxiliar com expressões textuais usadas para excluir
-- falsos positivos da classificação de judicialização da saúde.
--
-- Os termos podem ser palavras simples ou expressões regulares
-- compatíveis com PostgreSQL.

DROP TABLE IF EXISTS dados_bahia.regra_exclusao_termo_objeto;

CREATE TABLE dados_bahia.regra_exclusao_termo_objeto (
    termo TEXT PRIMARY KEY
);