# 📊 Análise da Judicialização da Saúde na Bahia

Projeto de análise de dados públicos para identificar e mensurar o impacto financeiro da judicialização da saúde no Estado da Bahia.

---

## 💡 Problema

Os gastos com judicialização da saúde são pouco transparentes e difíceis de identificar nos dados públicos.

Como separar, dentro de milhões de pagamentos, aqueles que realmente decorrem de decisões judiciais relacionadas à saúde?

---

## 📊 Dados utilizados

- Portal de Dados Abertos da Bahia: [link](https://dados.ba.gov.br/dataset/pagamentos)
- Mais de 5 milhões de pagamentos analisados
- Arquivos CSV com problemas estruturais (quebra de linha, delimitadores inconsistentes)

---

## 🛠️ Metodologia

### 🔹 1. Tratamento de dados (Python)

- Correção de CSVs com quebras de linhas por registro
- Reestruturação de campos com regex
- Padronização de dados textuais

### 🔹 2. Modelagem de dados (PostgreSQL)

- Construção de **modelo estrela (star schema)**
- Criação de tabelas fato e dimensões:
  - dim_classificacao_programatica
  - dim_credor_pagamento
  - dim_credor_principal
  - dim_estrutura_administrativa
  - dim_medicamentos
  - dim_municipios_ibge
  - dim_tipo_pagamento
  - empenho
  - fato_nota_ordem_bancaria
  - liquidacao
  - liquidacao_subelemento
  - processo_sei

### 🔹 3. Classificação da judicialização

- Regras baseadas em:   
  - Elemento de despesa ("Sentenças Judiciais")
  - Texto do objeto (NLP simplificado com regex)

### 🔹 4. Identificação de padrões
- Extração de medicamentos mais frequentes
- Filtragem de falsos positivos (educação, trabalhista, etc.)
- Regras de exclusão por contexto

### 📈 Principais resultados
- 💰 R$ 585 milhões identificados em gastos
- 📄 +12.000 pagamentos classificados
- 💊 Identificação de medicamentos mais recorrentes
- 🧠 Criação de modelo replicável de classificação

### 📊 Dashboard

<img width="1329" height="749" alt="image" src="https://github.com/user-attachments/assets/8d4526bf-e1a4-4ba9-8721-0cff1cab99fe" />
<br>
<img width="1329" height="754" alt="image" src="https://github.com/user-attachments/assets/376f6e4e-2536-4ad9-a9a1-786f6e76c5f7" />
<br>
<img width="1319" height="746" alt="image" src="https://github.com/user-attachments/assets/a3b2c2a7-adfa-4b7b-a16f-0e8598d807dc" />


### 🛠️ Tecnologias Utilizadas
- Python
- PostgreSQL
- Power BI
