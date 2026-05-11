"""
Script: Tratamento de CSV - Nota de Ordem Bancária

Objetivo:
---------
Corrigir desalinhamentos no arquivo de Nota de Ordem Bancária,
causados principalmente por delimitadores internos dentro de campos textuais.

Entrada:
--------
./data/VW_PAINEL_PAGAMENTO_NOTA_ORDEM_BANCARIA.csv

Saída:
------
./data/VW_PAINEL_PAGAMENTO_NOTA_ORDEM_BANCARIA_LIMPO.csv
"""

from pathlib import Path
import csv
import time


# ============================================================
# 📂 CONFIGURAÇÃO DE CAMINHOS
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

ARQUIVO_ENTRADA = BASE_DIR / "data" / "VW_PAINEL_PAGAMENTO_NOTA_ORDEM_BANCARIA.csv"
ARQUIVO_SAIDA = BASE_DIR / "data" / "VW_PAINEL_PAGAMENTO_NOTA_ORDEM_BANCARIA_LIMPO.csv"


# ============================================================
# ⏱️ CONTROLE DE EXECUÇÃO
# ============================================================

start_time = time.time()
contador = 0


# ============================================================
# 📖 LEITURA E ESCRITA DOS ARQUIVOS
# ============================================================

with open(ARQUIVO_ENTRADA, "r", encoding="utf-8-sig") as infile, \
     open(ARQUIVO_SAIDA, "w", encoding="utf-8", newline="") as outfile:

    reader = csv.reader(infile, delimiter=";", quotechar='"')
    writer = csv.writer(
        outfile,
        delimiter=";",
        quotechar='"',
        quoting=csv.QUOTE_MINIMAL
    )


    # ------------------------------------------------------------
    # 1. Leitura e gravação do cabeçalho
    # ------------------------------------------------------------

    header = next(reader)
    writer.writerow(header)


    # ------------------------------------------------------------
    # 2. Processamento das linhas
    # ------------------------------------------------------------

    for row in reader:
        contador += 1


        # --------------------------------------------------------
        # 3. Correção de desalinhamento
        # --------------------------------------------------------
        # Problema:
        # Algumas linhas possuem mais colunas do que o cabeçalho.
        # Isso indica que algum campo textual foi quebrado por conter
        # delimitadores internos.
        #
        # Solução:
        # - identifica o excesso de colunas;
        # - assume que o campo problemático começa na posição 2;
        # - junta os campos excedentes em um único texto;
        # - reconstrói a linha com a quantidade correta de colunas.

        if len(row) > len(header):
            excesso = len(row) - len(header) + 1

            row = (
                row[:2]
                + [" ".join(row[2:2 + excesso])]
                + row[2 + excesso:]
            )


        # --------------------------------------------------------
        # 4. Gravação da linha tratada
        # --------------------------------------------------------

        writer.writerow(row)


        # --------------------------------------------------------
        # 5. Debug de performance
        # --------------------------------------------------------
        # A cada 10.000 linhas, o script exibe:
        # - quantidade de linhas processadas;
        # - tempo decorrido;
        # - velocidade média de processamento.

        if contador % 10000 == 0:
            tempo = time.time() - start_time
            velocidade = contador / tempo if tempo > 0 else 0

            print(
                f"[DEBUG] Linhas processadas: {contador:,} | "
                f"Tempo: {tempo:.2f}s | "
                f"Velocidade: {velocidade:,.0f} linhas/s"
            )


# ============================================================
# ✅ RESUMO FINAL
# ============================================================

tempo_total = time.time() - start_time

print("\n✅ Processamento concluído!")
print(f"Total de linhas: {contador:,}")
print(f"Tempo total: {tempo_total:.2f}s")
