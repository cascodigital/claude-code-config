---
name: skacoes
description: Trading Room para análise técnica e fundamentalista de ações B3 e internacionais. Use para análise de tickers, price action e decisão de trade.
---

# Skill: Trading Room

**Timeframe:** Swing trade (2–10 dias úteis).
**Regra de Ouro:** Sem dados, sem opinião. Volume pífio (liquidez baixa) = FORA por padrão.

## ⛔ FALHA DE FERRAMENTA — PROTOCOLO OBRIGATÓRIO

**SE O MCP `stock-analysis` FALHAR, RETORNAR ERRO OU DADOS VAZIOS:**
**A ANÁLISE DEVE SER INTERROMPIDA IMEDIATAMENTE.**
**NÃO ESTIMAR. NÃO INVENTAR. NÃO CONTINUAR.**
**INFORMAR O ERRO AO USUÁRIO E AGUARDAR CORREÇÃO DA FERRAMENTA ANTES DE PROSSEGUIR.**

> A ferramenta é a única fonte de dados válida. Sem ela, qualquer análise é invenção.

---

## Ferramentas

<!-- PERSONALIZE: Ajuste o endereço do seu MCP stock-analysis -->
**Fonte única:** MCP `stock-analysis`. Duas tools disponíveis:

1. `analisar_acao` — análise rápida: RSI, MACD, SMAs, tendência, price action.
2. `analise_completa` — análise completa: tudo acima + Fibonacci (3 meses) + volume ratio (normalização intraday) + últimos 5 candles com corpo/sombras.

**Use `analise_completa` como padrão.** Use `analisar_acao` apenas para BOVA11 e checks rápidos.

Aceita tickers B3 (`PETR4.SA`) e internacionais (`AAPL`, `BTC-USD`).

---

## Análise Técnica

- **Variação > 3%:**
  - Volume alto + candle com corpo grande e sombras pequenas → **rompimento**
  - Volume baixo + sombras longas → **exaustão** — aguardar confirmação
- **Volume (`vol_ratio` da API):**
  - `vol_ratio < 0.5` → volume pífio → **FORA** independente do sinal técnico
  - `vol_ratio 0.5–1.0` → sinal com peso reduzido — posição menor
  - `vol_ratio >= 1.0` → volume confirma o movimento
  - *Intraday: a API projeta o volume automaticamente quando o pregão está aberto.*
- **RSI (papel individual):**
  - RSI > 70 → sobrecomprado: usar Alvo Conservador, apertar stop
  - RSI < 30 → possível reversão: aguardar price action confirmar antes de entrar
  - RSI 30–70 → zona neutra: MACD e volume decidem
- **Price Action:** Martelo ou Estrela Cadente = sinal válido **somente** se:
  1. Formou sobre suporte relevante (SMA, Fibonacci ou fundo anterior)
  2. MACD não está em cruzamento bearish contrariando o sinal
  3. `vol_ratio >= 0.5`
  4. Candle seguinte fecha na direção do sinal (confirmação)
  - Qualquer condição não cumprida → rebaixar para "observar".
- **Saída:** Stop Loss e Alvo sempre em **PERCENTUAL**.

## Fibonacci

Calculado pela API (swing high/low dos últimos 3 meses — 63 pregões).
Apresentar **todos os 7 níveis retornados pela API** e marcar onde o preço atual se encontra. Referências-chave para decisão:

| Nível | Significado |
|-------|-------------|
| 61,8% | Zona de maior concentração de ordens — reversões frequentes |
| 50,0% | Suporte psicológico |
| 38,2% | Retração saudável em tendência forte |
| 78,6% | Último suporte antes de perder a estrutura |

- Preço em nível Fib + `vol_ratio >= 1.0` → sinal reforçado
- Preço em nível Fib + `vol_ratio 0.5–1.0` → sinal válido, peso reduzido
- Fibonacci sozinho, sem outros indicadores alinhados → **não acionar**

## Análise Fundamentalista

- **Forensic Search:** Busque "fraude", "CVM", "processo", "fato relevante" (últimos 7 dias).
- **Scorecard:** 🟢 Investment Grade | 🟡 Speculative | 🔴 Junk.

## BOVA11 — Contexto Macro (Obrigatório)

**Rodar `analisar_acao` em BOVA11.SA antes de qualquer veredito.**

| BOVA11 | Modo |
|--------|------|
| **>8% acima da SMA20** | **NÃO ABRIR novas posições** — mercado sobrecomprado |
| **>5% acima da SMA20** | **Muito seletivo** — só entrar se todos os filtros estiverem perfeitos |
| Acima SMA20 + MACD bullish | Normal — tamanho cheio |
| Abaixo SMA20 **ou** MACD bearish | Posição reduzida — setup mais exigente |
| Abaixo SMA20 **e** MACD bearish | Máximo 1 posição — **5%** (tamanho mínimo) |
| Abaixo SMA50 | Trade cirúrgico ou **FORA** |

## Gestão de Risco

- **Máximo de posições:** 3 | **Exposição máxima:** 30% do capital
- **Alocação por tipo de decisão:**

| Decisão | Alocação |
|---------|----------|
| COMPRA FORTE (Investment Grade) + BOVA11 favorável | 7–10% |
| COMPRA TÁTICA (Reversão em baixa) | 5% |
| TRADE CURTO (Speculative) | 5% |
| Qualquer setup + BOVA11 abaixo SMA20 | 5–7% |

- **Diversificação setorial:** máximo 1 posição por setor simultaneamente.
- **3 stops consecutivos:** pausa obrigatória de 5 dias úteis.

## Matriz de Decisão

| Técnico | Price Action | Fundamento | Volume | DECISÃO |
| :--- | :--- | :--- | :--- | :--- |
| Qualquer | — | Qualquer | < 0.5x | **FORA** |
| 📉 BAIXA | — | 🔴 Junk | Qualquer | **VENDA/FORA** |
| 📉 BAIXA | 🔥 REJEIÇÃO SUPORTE | 🟢 Investment | >= 0.5x | **COMPRA TÁTICA** (5%) |
| 📈 ALTA | — | 🟢 Investment | >= 0.5x | **COMPRA FORTE** (7–10%) |
| 📈 ALTA | — | 🟡 Speculative | >= 0.5x | **TRADE CURTO** (5%) |
| 📈 ALTA | 💀 REJEIÇÃO TOPO | Qualquer | Qualquer | **NÃO ENTRAR** |

## OCO — Obrigatório em vereditos de COMPRA

**Regra:** Entrar 100%, sair 100%. Definir **UM** alvo antes de entrar. Não alterar após entrada.

```
🎯 OCO (Ordem Cancela Ordem) — escolher UM alvo:
  ┌──────────────────────────────────────────────────┐
  │ Alvo Conservador: +[X]%   (referência Fib 50%)   │
  │ Alvo Agressivo:   +[Y]%   (referência Fib 38%)   │
  │ Stop Loss:        -[Z]%   (referência Fib 78,6%) │
  └──────────────────────────────────────────────────┘
```

---

## Checklist de Execução (seguir nesta ordem)

1. **MCP ativo?** → Se falhar: parar imediatamente, informar erro.
2. **BOVA11** → `analisar_acao BOVA11.SA` → definir modo operacional.
3. **Papel** → `analise_completa [TICKER]` → registrar indicadores.
4. **Forense** → buscar notícias/CVM últimos 7 dias → definir Scorecard.
5. **Diversificação** → perguntar: *"Você tem posição aberta em [setor]?"*
6. **Decisão** → aplicar Matriz + macro → montar OCO.
