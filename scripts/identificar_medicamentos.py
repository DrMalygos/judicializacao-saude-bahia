"""
Script: Identificação de Medicamentos nos Objetos de Liquidação

Objetivo:
---------
Popular a tabela dados_bahia.fato_pagamento_medicamento a partir da busca
de medicamentos mencionados no campo objeto das liquidações.

Motivo da escolha por Python:
-----------------------------
A identificação textual foi feita em Python por eficiência, utilizando
o algoritmo Aho-Corasick para localizar múltiplos termos em grande volume
de registros.

Pré-requisitos:
---------------
1. Banco PostgreSQL criado e populado com:
   - dados_bahia.fato_nota_ordem_bancaria
   - dados_bahia.liquidacao
   - dados_bahia.dim_medicamentos

2. Instalar dependências:
   pip install pandas psycopg2-binary sqlalchemy unidecode pyahocorasick

Atenção:
--------
Substitua os placeholders de conexão pelos dados do seu ambiente local.
Nunca publique usuário e senha reais no GitHub.
"""

import re
import time
from io import StringIO
from urllib.parse import quote_plus

import ahocorasick
import pandas as pd
import psycopg2
from sqlalchemy import create_engine
from unidecode import unidecode


# ============================================================
# CONFIGURAÇÃO DO BANCO
# ============================================================
# Substitua pelos dados da sua conexão local.

DB_USER = "SEU_USUARIO_POSTGRES"
DB_PASS_RAW = "SUA_SENHA_POSTGRES"
DB_PASS_URL = quote_plus(DB_PASS_RAW)

DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "dados_bahia"

SCHEMA = "dados_bahia"

TABELA_FATO_PAGAMENTO = "fato_nota_ordem_bancaria"
TABELA_LIQUIDACAO = "liquidacao"
TABELA_MEDICAMENTOS = "dim_medicamentos"
TABELA_DESTINO = "fato_pagamento_medicamento"

CHUNK_SIZE = 50_000
COPY_BATCH_SIZE = 100_000


# ============================================================
# LOG
# ============================================================

def log(msg: str) -> None:
    print(f"[{time.strftime('%H:%M:%S')}] {msg}")


# ============================================================
# NORMALIZAÇÃO DE TEXTO
# ============================================================

def normalizar_texto(txt: str) -> str:
    """
    Normaliza textos para comparação:
    - converte para minúsculas;
    - remove acentos;
    - remove pontuação;
    - reduz múltiplos espaços.
    """
    if txt is None:
        return ""

    txt = str(txt).lower()
    txt = unidecode(txt)
    txt = re.sub(r"[^a-z0-9\s]", " ", txt)
    txt = re.sub(r"\s+", " ", txt)

    return txt.strip()


def preparar_para_busca(txt: str) -> str:
    """
    Adiciona espaços no início e no fim do texto para evitar matches
    parciais dentro de outras palavras.
    """
    texto = normalizar_texto(txt)
    return f" {texto} "


# ============================================================
# CONEXÕES
# ============================================================

log("Conectando ao PostgreSQL...")

engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{DB_PASS_URL}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

conn = psycopg2.connect(
    host=DB_HOST,
    port=DB_PORT,
    dbname=DB_NAME,
    user=DB_USER,
    password=DB_PASS_RAW
)

cur = conn.cursor()

log("Conectado.")


# ============================================================
# PREPARAÇÃO DA TABELA DESTINO
# ============================================================

log("Limpando tabela destino...")

cur.execute(f"""
TRUNCATE TABLE {SCHEMA}.{TABELA_DESTINO};
""")

conn.commit()


# ============================================================
# CARREGAMENTO DA DIMENSÃO DE MEDICAMENTOS
# ============================================================

log("Carregando medicamentos da dimensão...")

df_med = pd.read_sql(f"""
SELECT
    id_medicamento,
    termo_original,
    nome_comercial,
    substancia_ativa,
    alto_custo
FROM {SCHEMA}.{TABELA_MEDICAMENTOS}
WHERE
    (
        termo_original IS NOT NULL
        AND TRIM(termo_original) <> ''
    )
    OR
    (
        nome_comercial IS NOT NULL
        AND TRIM(nome_comercial) <> ''
    );
""", engine)

log(f"Medicamentos carregados: {len(df_med):,}")

if df_med.empty:
    raise ValueError("Nenhum medicamento encontrado na dim_medicamentos.")


# ============================================================
# MONTAGEM DO AUTÔMATO AHO-CORASICK
# ============================================================

log("Montando autômato Aho-Corasick...")

automato = ahocorasick.Automaton()
padroes_adicionados = set()

for row in df_med.itertuples(index=False):
    id_medicamento = int(row.id_medicamento)

    substancia_ativa = "" if pd.isna(row.substancia_ativa) else str(row.substancia_ativa).strip()
    nome_comercial = "" if pd.isna(row.nome_comercial) else str(row.nome_comercial).strip()
    alto_custo = bool(row.alto_custo)

    termos = []

    if not pd.isna(row.termo_original) and str(row.termo_original).strip():
        termos.append(str(row.termo_original).strip())

    if nome_comercial:
        termos.append(nome_comercial)

    for termo in termos:
        termo_normalizado = normalizar_texto(termo)

        if len(termo_normalizado) < 3:
            continue

        padrao = f" {termo_normalizado} "
        chave = (padrao, id_medicamento)

        if chave in padroes_adicionados:
            continue

        padroes_adicionados.add(chave)

        automato.add_word(
            padrao,
            {
                "id_medicamento": id_medicamento,
                "substancia_ativa": substancia_ativa,
                "nome_comercial": nome_comercial,
                "alto_custo": alto_custo,
            }
        )

automato.make_automaton()

log(f"Padrões adicionados ao autômato: {len(padroes_adicionados):,}")


# ============================================================
# FUNÇÃO DE BUSCA DE MEDICAMENTOS
# ============================================================

def encontrar_medicamentos(objeto: str):
    """
    Retorna medicamentos distintos encontrados no objeto informado.
    """
    texto = preparar_para_busca(objeto)
    encontrados = {}

    for _, item in automato.iter(texto):
        id_medicamento = item["id_medicamento"]
        encontrados[id_medicamento] = item

    return encontrados.values()


# ============================================================
# COPY EM LOTE PARA O POSTGRESQL
# ============================================================

def copiar_lote(linhas: list[list]) -> None:
    """
    Grava um lote de ocorrências na tabela destino usando COPY,
    que é mais eficiente do que múltiplos INSERTs.
    """
    if not linhas:
        return

    buffer = StringIO()

    df_lote = pd.DataFrame(
        linhas,
        columns=[
            "numero_pagamento",
            "id_medicamento",
            "substancia_ativa",
            "nome_comercial",
            "alto_custo",
            "objeto",
            "objeto_normalizado",
        ]
    )

    df_lote.to_csv(
        buffer,
        sep=";",
        header=False,
        index=False,
        na_rep=""
    )

    buffer.seek(0)

    cur.copy_expert(f"""
        COPY {SCHEMA}.{TABELA_DESTINO}
        (
            numero_pagamento,
            id_medicamento,
            substancia_ativa,
            nome_comercial,
            alto_custo,
            objeto,
            objeto_normalizado
        )
        FROM STDIN
        WITH (
            FORMAT CSV,
            DELIMITER ';',
            NULL '',
            QUOTE '"',
            ESCAPE '"'
        );
    """, buffer)

    conn.commit()


# ============================================================
# CONTAGEM DA BASE
# ============================================================

log("Contando registros com objeto disponível...")

total = pd.read_sql(f"""
SELECT COUNT(*)
FROM {SCHEMA}.{TABELA_FATO_PAGAMENTO} f
JOIN {SCHEMA}.{TABELA_LIQUIDACAO} l
    ON f.numero_liquidacao = l.numero_liquidacao
WHERE l.objeto IS NOT NULL;
""", engine).iloc[0, 0]

log(f"Registros com objeto: {total:,}")


# ============================================================
# PROCESSAMENTO EM LOTES
# ============================================================

query = f"""
SELECT
    f.numero_pagamento,
    l.objeto
FROM {SCHEMA}.{TABELA_FATO_PAGAMENTO} f
JOIN {SCHEMA}.{TABELA_LIQUIDACAO} l
    ON f.numero_liquidacao = l.numero_liquidacao
WHERE l.objeto IS NOT NULL;
"""

linhas_para_copy = []
linhas_lidas = 0
matches_total = 0

log("Iniciando identificação de medicamentos...")

for i, chunk in enumerate(pd.read_sql(query, engine, chunksize=CHUNK_SIZE), start=1):
    for row in chunk.itertuples(index=False):
        if pd.isna(row.numero_pagamento) or pd.isna(row.objeto):
            continue

        objeto_normalizado = normalizar_texto(row.objeto)
        medicamentos = encontrar_medicamentos(row.objeto)

        for med in medicamentos:
            linhas_para_copy.append([
                int(row.numero_pagamento),
                int(med["id_medicamento"]),
                med["substancia_ativa"],
                med["nome_comercial"],
                med["alto_custo"],
                row.objeto,
                objeto_normalizado,
            ])

            matches_total += 1

        if len(linhas_para_copy) >= COPY_BATCH_SIZE:
            copiar_lote(linhas_para_copy)
            log(f"Ocorrências gravadas até agora: {matches_total:,}")
            linhas_para_copy.clear()

    linhas_lidas += len(chunk)
    log(f"Lote {i:,} processado: {linhas_lidas:,}/{total:,} registros")

if linhas_para_copy:
    copiar_lote(linhas_para_copy)
    linhas_para_copy.clear()


# ============================================================
# ÍNDICES AUXILIARES
# ============================================================

log("Criando índices auxiliares...")

cur.execute(f"""
CREATE INDEX IF NOT EXISTS idx_{TABELA_DESTINO}_pagamento
ON {SCHEMA}.{TABELA_DESTINO} (numero_pagamento);

CREATE INDEX IF NOT EXISTS idx_{TABELA_DESTINO}_medicamento
ON {SCHEMA}.{TABELA_DESTINO} (id_medicamento);

CREATE INDEX IF NOT EXISTS idx_{TABELA_DESTINO}_alto_custo
ON {SCHEMA}.{TABELA_DESTINO} (alto_custo);
""")

conn.commit()


# ============================================================
# TESTE DE VALIDAÇÃO
# ============================================================

log("Executando teste de validação para Ceprotin / Proteína C...")

cur.execute(f"""
SELECT COUNT(*)
FROM {SCHEMA}.{TABELA_DESTINO}
WHERE objeto_normalizado LIKE '%ceprotin%'
   OR objeto_normalizado LIKE '%proteina c%';
""")

teste_ceprotin = cur.fetchone()[0]

log(f"Registros com Ceprotin / Proteína C: {teste_ceprotin:,}")


# ============================================================
# FINALIZAÇÃO
# ============================================================

cur.close()
conn.close()
engine.dispose()

log(f"FINALIZADO. Total de matches gravados: {matches_total:,}")