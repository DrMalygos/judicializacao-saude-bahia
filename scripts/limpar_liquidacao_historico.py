"""
Script: Tratamento de CSV - Liquidação Histórico

Objetivo:
---------
Reconstruir e limpar o arquivo histórico de liquidações, que apresenta
problemas estruturais mais complexos, como:

- quebras de linha dentro do campo "Objeto";
- aspas internas em textos longos;
- delimitadores dentro de campos textuais;
- registros quebrados ou malformados;
- valores com ponto ou vírgula decimal;
- risco de travamento em campos excessivamente longos.

Entrada:
--------
./data/VW_PAINEL_PAGAMENTO_LIQUIDACAO_HISTORICO.csv

Saída:
------
./data/VW_PAINEL_PAGAMENTO_LIQUIDACAO_HISTORICO_LIMPO.csv

Log:
----
./data/VW_PAINEL_PAGAMENTO_LIQUIDACAO_HISTORICO_PROBLEMAS.txt
"""

from pathlib import Path
import csv
import time
import re


# ============================================================
# 📂 CONFIGURAÇÃO DE CAMINHOS
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

ARQUIVO_ENTRADA = BASE_DIR / "data" / "VW_PAINEL_PAGAMENTO_LIQUIDACAO_HISTORICO.csv"
ARQUIVO_SAIDA = BASE_DIR / "data" / "VW_PAINEL_PAGAMENTO_LIQUIDACAO_HISTORICO_LIMPO.csv"
ARQUIVO_LOG = BASE_DIR / "data" / "VW_PAINEL_PAGAMENTO_LIQUIDACAO_HISTORICO_PROBLEMAS.txt"


# ============================================================
# 📌 ESTRUTURA ESPERADA DO ARQUIVO FINAL
# ============================================================

CABECALHO_ESPERADO = [
    "Nº da Liquidação",
    "Objeto",
    "Nº do Instrumento",
    "Data da Liquidação",
    "Valor da Liquidação",
]


# ============================================================
# ⚙️ PARÂMETROS DE SEGURANÇA
# ============================================================

# Evita que o parser fique preso em campos absurdamente longos.
# Se um campo ultrapassar esse limite, o registro será enviado para o log.
MAX_TAMANHO_CAMPO = 200_000


# ============================================================
# 🔎 PADRÕES REGULARES
# ============================================================

# Início plausível de um novo registro:
# exemplo: "123456789";
RE_INICIO_REGISTRO = re.compile(r'^\s*"\d+"\s*;')

# Formato esperado para data:
# exemplo: 31/12/2023
RE_DATA = re.compile(r"^\d{2}/\d{2}/\d{4}$")

# Formato esperado para valor:
# aceita tanto 123,45 quanto 123.45
RE_VALOR = re.compile(r"^\d+(?:[.,]\d{2})$")


# ============================================================
# 🧹 FUNÇÕES DE LIMPEZA E NORMALIZAÇÃO
# ============================================================

def limpar_texto(texto: str) -> str:
    """
    Remove quebras de linha internas e espaços excedentes.

    Essa etapa é essencial porque o campo "Objeto" frequentemente contém
    textos longos, com quebras de linha que prejudicam a leitura do CSV.
    """
    if texto is None:
        return ""

    return " ".join(texto.replace("\r", "\n").splitlines()).strip()


def normalizar_valor(valor: str) -> str:
    """
    Normaliza o campo de valor monetário.

    Se o valor vier com ponto decimal, converte para vírgula decimal,
    mantendo o padrão utilizado nos arquivos públicos brasileiros.
    """
    valor = limpar_texto(valor)

    if "." in valor and "," not in valor:
        if RE_VALOR.match(valor):
            valor = valor.replace(".", ",")

    return valor


# ============================================================
# ✅ VALIDAÇÃO DE REGISTRO
# ============================================================

def registro_valido(campos: list[str]) -> tuple[bool, str | None]:
    """
    Valida se o registro reconstruído possui a estrutura esperada.

    Regras aplicadas:
    - deve conter exatamente 5 campos;
    - o número da liquidação deve ser numérico;
    - a data, se preenchida, deve seguir o formato DD/MM/AAAA;
    - o valor, se preenchido, deve estar em formato monetário válido.
    """
    if len(campos) != 5:
        return False, f"quantidade_campos_{len(campos)}"

    liquidacao = limpar_texto(campos[0])
    data = limpar_texto(campos[3])
    valor = normalizar_valor(campos[4])

    if not liquidacao.isdigit():
        return False, "liquidacao_invalida"

    if data and not RE_DATA.match(data):
        return False, "data_invalida"

    if valor and not RE_VALOR.match(valor):
        return False, "valor_invalido"

    return True, None


# ============================================================
# 🧭 FUNÇÕES AUXILIARES DO PARSER
# ============================================================

def proximo_nao_espaco(conteudo: str, pos: int) -> int:
    """
    Avança no texto até encontrar o próximo caractere que não seja
    espaço, tabulação ou quebra de linha.
    """
    n = len(conteudo)
    j = pos

    while j < n and conteudo[j] in " \t\r\n":
        j += 1

    return j


def quote_fecha_campo_intermediario(conteudo: str, i: int) -> bool:
    """
    Verifica se uma aspas fecha um campo intermediário.

    Para os campos 1 a 4, a aspas só é considerada fechamento real
    se for seguida por:

        " ; "

    e depois pelo início do próximo campo entre aspas.

    Isso evita tratar aspas internas do campo "Objeto" como fim do campo.
    """
    n = len(conteudo)
    j = i + 1

    j = proximo_nao_espaco(conteudo, j)

    if j >= n or conteudo[j] != ";":
        return False

    j += 1
    j = proximo_nao_espaco(conteudo, j)

    return j < n and conteudo[j] == '"'


def quote_fecha_ultimo_campo(conteudo: str, i: int) -> bool:
    """
    Verifica se uma aspas fecha o último campo do registro.

    Para o último campo, a aspas é considerada fechamento real quando
    depois dela há apenas espaços/quebras e, em seguida:

    - fim do arquivo; ou
    - início plausível de um novo registro.
    """
    n = len(conteudo)
    j = i + 1

    j = proximo_nao_espaco(conteudo, j)

    if j >= n:
        return True

    trecho = conteudo[j:j + 50]

    return bool(RE_INICIO_REGISTRO.match(trecho))


# ============================================================
# 🧩 PARSER PRINCIPAL DOS REGISTROS
# ============================================================

def parsear_registros(conteudo: str) -> tuple[list[list[str]], list[tuple[int, str, str]]]:
    """
    Percorre o arquivo inteiro caractere por caractere, reconstruindo
    registros válidos com 5 campos.

    Essa abordagem foi necessária porque o arquivo histórico possui
    inconsistências que impedem uma leitura simples com csv.reader.
    """
    registros = []
    problemas = []

    n = len(conteudo)
    i = 0
    linha_logica = 1

    inicio_exec = time.time()
    ultimo_debug_char = 0
    registros_processados = 0

    while i < n:
        ch = conteudo[i]

        # ------------------------------------------------------------
        # Controle aproximado da linha lógica
        # ------------------------------------------------------------

        if ch == "\n":
            linha_logica += 1
            i += 1
            continue

        # ------------------------------------------------------------
        # Busca pelo início plausível de um registro
        # ------------------------------------------------------------

        if ch != '"':
            i += 1
            continue

        trecho_inicio = conteudo[i:i + 50]

        if not RE_INICIO_REGISTRO.match(trecho_inicio):
            i += 1
            continue

        inicio_registro_linha = linha_logica
        campos = []
        erro = None

        # ------------------------------------------------------------
        # Leitura dos 5 campos esperados
        # ------------------------------------------------------------

        for idx_campo in range(5):

            # Cada campo deve começar com aspas.
            if i >= n or conteudo[i] != '"':
                erro = f"campo_{idx_campo + 1}_sem_aspas_iniciais"
                break

            i += 1
            atual = []

            # --------------------------------------------------------
            # Leitura caractere a caractere do campo atual
            # --------------------------------------------------------

            while i < n:
                ch = conteudo[i]

                # Ignora carriage return.
                if ch == "\r":
                    i += 1
                    continue

                # Quebras de linha internas são incorporadas como espaço.
                if ch == "\n":
                    linha_logica += 1
                    atual.append(" ")
                    i += 1
                    continue

                # Tratamento de aspas.
                if ch == '"':
                    if idx_campo < 4:
                        if quote_fecha_campo_intermediario(conteudo, i):
                            i += 1
                            break
                        else:
                            atual.append(ch)
                            i += 1
                            continue
                    else:
                        if quote_fecha_ultimo_campo(conteudo, i):
                            i += 1
                            break
                        else:
                            atual.append(ch)
                            i += 1
                            continue

                atual.append(ch)
                i += 1

                # Proteção contra campos excessivamente longos.
                if len(atual) > MAX_TAMANHO_CAMPO:
                    erro = f"campo_{idx_campo + 1}_muito_grande"
                    break

            else:
                erro = f"campo_{idx_campo + 1}_sem_fechamento"
                break

            if erro is not None:
                break

            campos.append(limpar_texto("".join(atual)))

            # --------------------------------------------------------
            # Após os campos 1 a 4, deve existir delimitador ";"
            # --------------------------------------------------------

            if idx_campo < 4:
                i = proximo_nao_espaco(conteudo, i)

                if i >= n or conteudo[i] != ";":
                    erro = f"campo_{idx_campo + 1}_sem_ponto_e_virgula"
                    break

                i += 1
                i = proximo_nao_espaco(conteudo, i)

                if i >= n or conteudo[i] != '"':
                    erro = f"campo_{idx_campo + 2}_sem_aspas_iniciais"
                    break

        # ------------------------------------------------------------
        # Validação e armazenamento do registro
        # ------------------------------------------------------------

        if erro is None:
            ok, motivo = registro_valido(campos)

            if ok:
                registros.append([
                    limpar_texto(campos[0]),
                    limpar_texto(campos[1]),
                    limpar_texto(campos[2]),
                    limpar_texto(campos[3]),
                    normalizar_valor(campos[4]),
                ])

                registros_processados += 1
            else:
                problemas.append((
                    inicio_registro_linha,
                    motivo or "registro_invalido",
                    str(campos)[:3000]
                ))

        # ------------------------------------------------------------
        # Registro com erro: salva no log e tenta ressincronizar
        # ------------------------------------------------------------

        else:
            trecho_prob = conteudo[max(0, i - 300):min(n, i + 700)]
            trecho_prob = trecho_prob.replace("\r", " ").replace("\n", " ")

            problemas.append((
                inicio_registro_linha,
                erro,
                trecho_prob[:3000]
            ))

            # Tenta encontrar o próximo possível início de registro.
            prox = conteudo.find('\n"', i)

            if prox == -1:
                i += 1
            else:
                i = prox + 1

        # ------------------------------------------------------------
        # Debug periódico por quantidade de registros
        # ------------------------------------------------------------

        if registros_processados % 10000 == 0 and registros_processados > 0:
            tempo = time.time() - inicio_exec
            print(f"[DEBUG] {registros_processados:,} registros processados | tempo: {tempo:.1f}s")

        # ------------------------------------------------------------
        # Debug periódico por avanço no arquivo
        # ------------------------------------------------------------

        if (i - ultimo_debug_char) >= 2_000_000:
            tempo = time.time() - inicio_exec

            print(
                f"[DEBUG] posição {i:,}/{n:,} caracteres | "
                f"linha lógica ~ {linha_logica:,} | "
                f"problemas: {len(problemas):,} | "
                f"tempo: {tempo:.1f}s"
            )

            ultimo_debug_char = i

    print(f"[DEBUG] Parsing concluído em {time.time() - inicio_exec:.1f}s")

    return registros, problemas


# ============================================================
# 🔍 VALIDAÇÃO DO CSV GERADO
# ============================================================

def validar_csv_saida(caminho_csv: Path, caminho_log: Path) -> None:
    """
    Valida se todas as linhas do CSV final possuem exatamente 5 colunas.

    Caso sejam encontradas linhas inválidas, os detalhes são adicionados
    ao arquivo de log.
    """
    linhas_invalidas = []

    with open(caminho_csv, "r", encoding="utf-8", newline="") as f:
        reader = csv.reader(f, delimiter=";", quotechar='"')

        for i, row in enumerate(reader, start=1):
            if len(row) != 5:
                linhas_invalidas.append((i, len(row), row))

    if linhas_invalidas:
        with open(caminho_log, "a", encoding="utf-8") as f:
            f.write("\nVALIDAÇÃO DO CSV DE SAÍDA\n")
            f.write("=" * 100 + "\n")

            for i, qtd, row in linhas_invalidas[:200]:
                f.write(f"Linha {i} com {qtd} colunas: {row}\n")

        print(f"[ALERTA] {len(linhas_invalidas)} linhas inválidas no CSV.")
    else:
        print("Validação OK: todas as linhas têm 5 colunas.")


# ============================================================
# 🚀 FUNÇÃO PRINCIPAL
# ============================================================

def main():
    print(f"Arquivo de entrada: {ARQUIVO_ENTRADA}")

    # ------------------------------------------------------------
    # 1. Validação da existência do arquivo
    # ------------------------------------------------------------

    if not ARQUIVO_ENTRADA.exists():
        raise FileNotFoundError(f"Arquivo não encontrado: {ARQUIVO_ENTRADA}")

    inicio_total = time.time()

    # ------------------------------------------------------------
    # 2. Leitura integral do arquivo original
    # ------------------------------------------------------------
    # O arquivo é lido como texto bruto para permitir parsing manual,
    # já que o csv.reader tradicional não consegue lidar bem com todas
    # as inconsistências encontradas no arquivo histórico.

    conteudo = ARQUIVO_ENTRADA.read_text(encoding="utf-8-sig")

    print(f"[DEBUG] Tamanho do arquivo: {len(conteudo):,} caracteres")

    # ------------------------------------------------------------
    # 3. Parsing e reconstrução dos registros
    # ------------------------------------------------------------

    registros_limpos, registros_problema = parsear_registros(conteudo)

    # ------------------------------------------------------------
    # 4. Gravação do CSV limpo
    # ------------------------------------------------------------

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
    # 5. Gravação do log de problemas
    # ------------------------------------------------------------

    with open(ARQUIVO_LOG, "w", encoding="utf-8") as f:
        f.write(f"Registros limpos: {len(registros_limpos)}\n")
        f.write(f"Registros problema: {len(registros_problema)}\n\n")

        for linha, motivo, conteudo_prob in registros_problema[:1000]:
            f.write(f"[Linha lógica {linha}] Motivo: {motivo}\n")
            f.write(conteudo_prob + "\n")
            f.write("-" * 100 + "\n")

    # ------------------------------------------------------------
    # 6. Resumo do processamento
    # ------------------------------------------------------------

    print(f"Registros limpos: {len(registros_limpos):,}")
    print(f"Registros problema: {len(registros_problema):,}")
    print(f"Arquivo gerado: {ARQUIVO_SAIDA}")
    print(f"Log gerado: {ARQUIVO_LOG}")

    # ------------------------------------------------------------
    # 7. Validação final do arquivo de saída
    # ------------------------------------------------------------

    validar_csv_saida(ARQUIVO_SAIDA, ARQUIVO_LOG)

    print(f"[DEBUG] Tempo total: {time.time() - inicio_total:.1f}s")


# ============================================================
# ▶️ EXECUÇÃO DO SCRIPT
# ============================================================

if __name__ == "__main__":
    main()