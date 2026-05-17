-- ============================================================
-- 05_create_classification_rules.sql
-- Projeto: Judicialização da Saúde na Bahia
-- Objetivo:
--   Popular a tabela de regras de exclusão textual utilizada na
--   classificação da judicialização da saúde.
--
-- Observação:
--   Os termos abaixo são expressões regulares PostgreSQL.
--   Eles foram identificados empiricamente durante a análise
--   exploratória dos objetos das liquidações e servem para excluir
--   falsos positivos.
-- ============================================================


-- ============================================================
-- INSERÇÃO DAS REGRAS DE EXCLUSÃO
-- ============================================================

INSERT INTO dados_bahia.regra_exclusao_termo_objeto (termo)
VALUES

    ('\mfundef\M'),
    ('\mfundeb\M'),
    ('\mmagist[ée]rio\M'),
    ('\mtransporte escolar\M'),
    ('\mmerenda\M'),
    ('\muniforme escolar\M'),
    ('\mtrabalhista\M'),
    ('\mdiraf\M'),
    ('\mdanos morais\M'),
    ('\mimobili[áa]rio\M'),
    ('\mpr[ée]dio\M'),
    ('\minsalubridade\M'),
    ('\mrpv\M'),
    ('\mprodutividade judicial\M'),
    ('\mpericulosidade\M'),
    ('\mindeniza[çc][ãa]o\M'),
    ('\mfolha\M'),
    ('\mdesapropria[çc][ãa]o\M'),
    ('\mtransportar\M'),
    ('\mcontrato de gest[aã]o\M'),
    ('\mempregad[oa]\M'),
    ('\mloca[çc][ãa]o\M'),
    ('\mim[óo]veis\M'),
    ('\mres[íi]duos?\M'),
    ('\mlavanderia\M'),
    ('\marroz\M'),
    ('\minfra[çc][ãa]o\M'),
    ('\mportaria\M'),
    ('\mesp[óo]lio\M'),
    ('\mfalecido\M'),
    ('\malimenta[çc][ãa]o\M'),
    ('\msucessor\M'),
    ('\mrescis[óo]rias?\M'),
    ('\mreg\.?\s*pre[çc]o\M'),
    ('\mspecial sa[úu]de\M')

ON CONFLICT (termo) DO NOTHING;