"""
Script: Tratamento de CSV - Liquidação

Objetivo:
---------
Corrigir problemas estruturais no arquivo de liquidação, especialmente:
- quebras de linha dentro da coluna "Objeto";
- registros quebrados em múltiplas linhas;
- necessidade de reconstruir cada liquidação como uma linha lógica única.

Entrada:
--------
./data/VW_PAINEL_PAGAMENTO_LIQUIDACAO.csv

Saída:
------
./data/VW_PAINEL_PAGAMENTO_LIQUIDACAO_LIMPO.csv

Log:
----
./data/VW_PAINEL_PAGAMENTO_LIQUIDACAO_PROBLEMAS.txt
"""

from pathlib import Path
import csv
import re


# ============================================================
# 📂 CONFIGURAÇÃO DE CAMINHOS
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

ARQUIVO_ENTRADA = BASE_DIR / "data" / "VW_PAINEL_PAGAMENTO_LIQUIDACAO.csv"
ARQUIVO_SAIDA = BASE_DIR / "data" / "VW_PAINEL_PAGAMENTO_LIQUIDACAO_LIMPO 2.csv"
ARQUIVO_LOG = BASE_DIR / "data" / "VW_PAINEL_PAGAMENTO_LIQUIDACAO_PROBLEMAS 2.txt"


# ============================================================
# 📌 CABEÇALHO ESPERADO NO ARQUIVO FINAL
# ============================================================

CABECALHO_ESPERADO = [
    "Nº da Liquidação",
    "Objeto",
    "Nº do Instrumento",
    "Data da Liquidação",
    "Valor da Liquidação",
]


# ============================================================
# 🔎 PADRÕES REGEX PARA IDENTIFICAÇÃO DOS REGISTROS
# ============================================================

# Identifica o início típico de um novo registro:
# exemplo: "123456";
PADRAO_INICIO_REGISTRO = re.compile(r'^"\d+";')

# Captura os 5 campos esperados no arquivo:
# 1. Nº da Liquidação
# 2. Objeto
# 3. Nº do Instrumento
# 4. Data da Liquidação
# 5. Valor da Liquidação
#
# O campo "Objeto" usa captura gulosa (.*), pois pode conter textos longos,
# delimitadores internos e quebras de linha originalmente presentes no CSV.
PADRAO_5_CAMPOS = re.compile(
    r'^"(?P<liquidacao>\d+)";'
    r'"(?P<objeto>.*)";'
    r'"(?P<instrumento>.*?)";'
    r'"(?P<data>\d{2}/\d{2}/\d{4})";'
    r'"(?P<valor>\d+,\d{2})"$'
)


# ============================================================
# 🧹 FUNÇÃO AUXILIAR DE LIMPEZA DE TEXTO
# ============================================================

def limpar_texto(texto: str) -> str:
    """
    Remove quebras de linha internas e espaços excedentes.

    Essa função é importante porque o campo "Objeto" pode conter textos
    longos com quebras de linha, o que prejudica a importação posterior
    para o PostgreSQL.
    """
    if texto is None:
        return ""

    return " ".join(texto.replace("\r", "\n").splitlines()).strip()


# ============================================================
# 🚀 FUNÇÃO PRINCIPAL DO PROCESSAMENTO
# ============================================================

def main():
    print(f"Arquivo de entrada: {ARQUIVO_ENTRADA}")


    # ------------------------------------------------------------
    # 1. VALIDAÇÃO DO ARQUIVO DE ENTRADA
    # ------------------------------------------------------------

    if not ARQUIVO_ENTRADA.exists():
        raise FileNotFoundError(f"Arquivo não encontrado: {ARQUIVO_ENTRADA}")


    # ------------------------------------------------------------
    # 2. LEITURA DO ARQUIVO ORIGINAL
    # ------------------------------------------------------------

    with open(ARQUIVO_ENTRADA, "r", encoding="utf-8-sig") as f:
        linhas = f.read().splitlines()

    if not linhas:
        raise ValueError("O arquivo está vazio.")

    cabecalho = linhas[0].strip()
    print("Cabeçalho:", cabecalho)


    # ------------------------------------------------------------
    # 3. RECONSTRUÇÃO DOS REGISTROS EM BLOCOS LÓGICOS
    # ------------------------------------------------------------
    # Problema:
    # O arquivo original pode ter quebras de linha dentro do campo "Objeto".
    # Isso faz com que um único registro seja lido como várias linhas.
    #
    # Solução:
    # Um novo registro é identificado sempre que a linha começa com:
    # "número";
    #
    # As linhas seguintes são acumuladas no mesmo bloco até que um novo
    # início de registro seja encontrado.

    blocos = []
    buffer = []

    for linha in linhas[1:]:
        linha = linha.rstrip()

        if PADRAO_INICIO_REGISTRO.match(linha):
            if buffer:
                blocos.append(" ".join(buffer))

            buffer = [linha]
        else:
            buffer.append(linha)

    if buffer:
        blocos.append(" ".join(buffer))

    print("Blocos encontrados:", len(blocos))


    # ------------------------------------------------------------
    # 4. EXTRAÇÃO DOS CAMPOS COM REGEX
    # ------------------------------------------------------------
    # Cada bloco lógico é testado contra o padrão esperado de 5 campos.
    #
    # Se o padrão casar:
    # - o registro é limpo e salvo na lista de registros válidos.
    #
    # Se não casar:
    # - o bloco é enviado para o log de problemas para análise posterior.

    registros_limpos = []
    registros_problema = []

    for idx, bloco in enumerate(blocos, start=2):
        bloco_limpo = limpar_texto(bloco)

        m = PADRAO_5_CAMPOS.match(bloco_limpo)

        if not m:
            registros_problema.append((idx, bloco_limpo, "regex_nao_casou"))
            continue

        registros_limpos.append([
            limpar_texto(m.group("liquidacao")),
            limpar_texto(m.group("objeto")),
            limpar_texto(m.group("instrumento")),
            limpar_texto(m.group("data")),
            limpar_texto(m.group("valor")),
        ])


    # ------------------------------------------------------------
    # 5. GRAVAÇÃO DO CSV LIMPO
    # ------------------------------------------------------------
    # O novo arquivo é gravado com:
    # - delimitador ";"
    # - campos entre aspas
    # - codificação UTF-8
    # - uma linha por registro lógico

    with open(ARQUIVO_SAIDA, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(
            f,
            delimiter=";",
            quotechar='"',
            quoting=csv.QUOTE_ALL,
            lineterminator="\n",
        )

        writer.writerow(CABECALHO_ESPERADO)
        writer.writerows(registros_limpos)


    # ------------------------------------------------------------
    # 6. GRAVAÇÃO DO LOG DE PROBLEMAS
    # ------------------------------------------------------------
    # O log permite verificar registros que não seguiram o padrão esperado.
    # Para evitar arquivos muito grandes, são registrados apenas os 200
    # primeiros problemas encontrados.

    with open(ARQUIVO_LOG, "w", encoding="utf-8") as f:
        f.write(f"Total de blocos: {len(blocos)}\n")
        f.write(f"Registros limpos: {len(registros_limpos)}\n")
        f.write(f"Registros problema: {len(registros_problema)}\n\n")

        for idx, bloco, motivo in registros_problema[:200]:
            f.write(f"[Linha lógica {idx}] Motivo: {motivo}\n")
            f.write(bloco[:3000] + "\n")
            f.write("-" * 100 + "\n")


    # ------------------------------------------------------------
    # 7. RESUMO FINAL DO PROCESSAMENTO
    # ------------------------------------------------------------

    print("Registros limpos:", len(registros_limpos))
    print("Registros problema:", len(registros_problema))
    print(f"Arquivo limpo gerado em: {ARQUIVO_SAIDA}")
    print(f"Log de problemas gerado em: {ARQUIVO_LOG}")


# ============================================================
# ▶️ EXECUÇÃO DO SCRIPT
# ============================================================

if __name__ == "__main__":
    main()