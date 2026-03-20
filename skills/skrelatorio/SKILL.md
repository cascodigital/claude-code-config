---
name: skrelatorio
description: >
  Gera relatório mensal de suporte via GLPI.
  Use quando o usuário mencionar relatório, report, mensal, resumo de chamados.
---

# Relatório Mensal de Suporte

## Identidade
Sub-mente analítica. Gera relatórios de chamados do GLPI para apresentar aos clientes.

---

## Trigger
Ativada quando o usuário menciona: "relatório", "report", "mensal", "resumo de chamados".

---

## Referência: Entidades (Empresas) e E-mails

<!-- PERSONALIZE: Adicione suas empresas e e-mails de clientes -->
| ID | Empresa    | E-mail do cliente               |
|----|------------|---------------------------------|
| 2  | Empresa A  | contato@empresaa.com.br         |
| 3  | Empresa B  | —                               |

> Se o e-mail do cliente não estiver na tabela acima, pergunte ao usuário antes de criar o rascunho.

## Referência: Categorias de Chamado

| ID | Categoria          |
|----|--------------------|
| 1  | Hardware           |
| 2  | Software           |
| 3  | Rede               |
| 4  | Outros             |
| 5  | Impressoras        |
| 6  | Backup             |
| 7  | M365               |
| 8  | Acesso / Senhas    |

---

## Fluxo Principal

### 1. Identificar parâmetros
- **Empresa:** obrigatório — pergunte se não informada
- **Período:** mês/ano (padrão: mês anterior ao atual)

### 2. Buscar dados
Use `list_tickets` com `entities_id` da empresa. Filtre por data no período usando `date_creation`.

**Status:** 1=Novo, 2=Em andamento, 3=Planejado, 4=Pendente, 5=Resolvido, 6=Fechado

### 3. Calcular métricas
- Total de chamados abertos no período
- Total resolvidos/fechados (status 5 ou 6)
- Ainda abertos ao final do período
- Chamados por categoria
- **Tempo total trabalhado** — campo `actiontime` (em segundos → converter)
  - Se `actiontime` for 0 em todos, informe "Não registrado"
  - **NUNCA use `solve_delay_stat`** — conta tempo corrido, gera valores absurdos
- Tempo médio trabalhado por chamado

### 4. Gerar relatório

**SEMPRE faça as três entregas:**

#### A) Exibir no terminal
Mostre o relatório completo em markdown.

#### B) Salvar PDF
<!-- PERSONALIZE: Ajuste os paths para seu OS -->
1. Salve HTML estilizado em temp
2. Converta com `wkhtmltopdf`
3. Informe o caminho do PDF

#### C) Criar rascunho no Outlook
Via MCP `ms365`, crie rascunho com o PDF anexado.

**Template do corpo do e-mail:**
```html
<p>Prezado(a),</p>
<p>Segue em anexo o relatório de suporte técnico referente ao mês de <strong>[Mês/Ano]</strong>.</p>
<p>No período, registramos <strong>[N] chamados</strong>, todos resolvidos com taxa de resolução de <strong>[X]%</strong>.</p>
<p>Qualquer dúvida, estamos à disposição.</p>
<br>
<p>Atenciosamente,<br>
<strong>[Seu Nome]</strong><br>
[Sua Empresa] — Suporte e Infraestrutura de TI</p>
```

---

## Regras

- **Nunca** inventar dados.
- **Sempre** converter tempos para unidades legíveis.
- **Sempre** exibir no terminal E gerar PDF.
- Categorias sem chamados não precisam aparecer na tabela.
- O relatório deve ser profissional — o cliente vai ler.
- Omitir chamados de teste (títulos com "[TESTE]").
