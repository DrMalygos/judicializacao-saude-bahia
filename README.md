# 📊 Análise da Judicialização da Saúde na Bahia

Projeto de análise de dados públicos para identificar e mensurar o impacto financeiro da judicialização da saúde no Estado da Bahia.

---

## 💡 Problema

Os gastos com judicialização da saúde são pouco transparentes e difíceis de identificar nos dados públicos.

Como separar, dentro de milhões de pagamentos, aqueles que realmente decorrem de decisões judiciais relacionadas à saúde?

---

## 📊 Dados utilizados

- Portal de Dados Abertos da Bahia: https://dados.ba.gov.br/dataset/pagamentos
- Base auxiliar de municípios do IBGE, extraída da Divisão Territorial Brasileira / Banco de Estruturas Territoriais
- Mais de 5 milhões de pagamentos analisados
- Arquivos CSV com problemas estruturais:
  - quebra de linha em registros;
  - delimitadores inconsistentes;
  - campos textuais desalinhados.

### Base de municípios

A planilha original do IBGE foi tratada no Excel para manter apenas os campos necessários à dimensão de municípios:
- código do município;
- UF;
- nome do município;
- município/UF.

---

## 🛠️ Metodologia

### 🔹 1. Tratamento de dados (Python)

- Correção de CSVs com quebra de linhas por registro
- Reestruturação de campos utilizando regex
- Padronização de dados textuais
- Tratamento de inconsistências estruturais

### 🔹 2. Modelagem de dados (PostgreSQL)

Construção de modelo estrela (*star schema*) com tabelas fato e dimensões.

Principais tabelas:
- dim_classificacao_programatica
- dim_credor_principal
- dim_estrutura_administrativa
- dim_medicamentos
- dim_municipios_ibge
- dim_tipo_pagamento
- liquidacao
- fato_nota_ordem_bancaria
- fato_pagamento_medicamento

### 🔹 3. Classificação da judicialização

Regras baseadas em:
- elemento de despesa;
- classificação programática;
- estrutura administrativa;
- identificação textual no objeto da liquidação.

### 🔹 4. Identificação de padrões

- Extração de medicamentos mais recorrentes
- Filtragem de falsos positivos
- Regras de exclusão por contexto
- Matching textual utilizando Aho-Corasick

---

## 📈 Principais resultados

- 💰 R$ 585 milhões identificados em gastos
- 📄 +12.000 pagamentos classificados
- 💊 Identificação dos medicamentos mais recorrentes
- 🧠 Criação de modelo replicável de classificação

---

## ▶️ Reprodução do projeto

### 1. Baixar os arquivos

Baixe os arquivos de pagamentos no Portal de Dados Abertos da Bahia:

https://dados.ba.gov.br/dataset/pagamentos

Bem como os arquivos auxiliares disponibilizados na pasta `data/` deste projeto.

---

### 2. Executar os scripts Python de limpeza

Utilize os scripts da pasta `python/` para tratar os arquivos CSV originais.

---

### 3. Executar os scripts SQL

Execute os scripts SQL em ordem até o arquivo `05_criar_regras_exclusao.sql`.

---

### 4. Popular a tabela de medicamentos

Execute o script Python:

```bash
python identificar_medicamentos.py
```

para popular a tabela `fato_pagamento_medicamento`.

---

### 5. Criar a view final

Execute o script:

```text
06_criar_view_judicializacao_saude.sql
```

---

### 6. Abrir o Power BI

Abra o arquivo:

```text
judicializacao_saude.pbix
```

e configure as conexões necessárias com o PostgreSQL.

---

## 📊 Dashboard

<img width="1326" height="748" alt="image" src="https://github.com/user-attachments/assets/00492f8a-e6a1-447b-9636-74ed96355d7e" />

<br>

<img width="1329" height="754" alt="image" src="https://github.com/user-attachments/assets/376f6e4e-2536-4ad9-a9a1-786f6e76c5f7" />

<br>

<img width="1319" height="746" alt="image" src="https://github.com/user-attachments/assets/a3b2c2a7-adfa-4b7b-a16f-0e8598d807dc" />

---

## 🛠️ Tecnologias utilizadas

- Python
  - Utilizamos o PyCharm 2026.1
- PostgreSQL
  - Utilizamos o Dbeaver 26.0.4
- Power BI

---

## 📫 Contato

- LinkedIn: [Matheus Bragança](https://www.linkedin.com/in/matheus-bragan%C3%A7a-544134321/)
