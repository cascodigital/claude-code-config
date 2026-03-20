---
name: skmimi
description: >
  Gerencia um canal de YouTube tech/home lab apresentado por uma mascote.
  Use quando o usuário mencionar episódio, canal, roteiro, ou qualquer tema de home lab/self-hosting.
  Gera roteiro completo, descrição YouTube, tags, thumbnail brief, checklist de produção e áudio via TTS.
---

# Canal YouTube — Tech/Home Lab

## Contexto do Canal

<!-- PERSONALIZE: Ajuste mascote, nicho e identidade visual -->
- **Mascote:** Personagem que apresenta o canal (overlay no canto do vídeo)
- **Nicho:** Home Lab / Self-hosting / Tech acessível com profundidade real
- **Formato padrão (slides):** Roteiro → TTS gera áudio → slides gerados por script → vídeo montado em editor
- **Formato demonstrativo (screencast):** Vídeo gravado → áudios de transição por bloco → montado em editor com slides de seção
- **Frequência:** 1 episódio/semana

## Persona da Mascote

<!-- PERSONALIZE: Defina a personalidade da sua mascote -->
- Tom: calmo, levemente irônico, didático sem ser condescendente
- Trata o ouvinte como adulto inteligente que só não conhece o assunto ainda
- Catchphrase final: defina uma frase de encerramento consistente

## Instructions

### Step 1: Identificar o Episódio
Se o usuário mencionou um tema ou número, use esse. Se não, sugira o próximo pendente.

### Step 2: Gerar Pacote Completo

Entregue na ordem:

#### 2.1 — TÍTULO E DESCRIÇÃO YOUTUBE
```
TÍTULO: [título chamativo, máximo 60 caracteres]

DESCRIÇÃO:
[Parágrafo 1 — gancho: o problema que o episódio resolve]
[Parágrafo 2 — o que vai aprender]
[Parágrafo 3 — CTA]

Timestamps:
00:00 — Introdução
[outros conforme roteiro]
```

#### 2.2 — ROTEIRO COMPLETO
Cada bloco: o que a mascote fala + o que aparece na tela.

```
[ABERTURA]
MASCOTE: [abertura característica]
TELA: [o que mostrar]

[BLOCO 1 — O Problema]
MASCOTE: [narrativa]
TELA: [visual]

[BLOCO 2 — O Conceito]
...

[FECHAMENTO]
MASCOTE: [CTA + catchphrase]
TELA: [tela final]
```

#### 2.3 — VOZ (TTS)
<!-- PERSONALIZE: Ajuste para seu provedor de TTS -->
Gerada via script TTS. O script filtra automaticamente — só processa linhas `MASCOTE:`.

#### 2.4 — THUMBNAIL BRIEF
Descrição para gerar no Canva ou gerador de imagens IA.

#### 2.5 — TAGS YOUTUBE
15-20 tags mix de gerais + específicas, PT + EN.

#### 2.6 — CTA DO EPISÓDIO
1 CTA específico (não genérico).

#### 2.7 — CHECKLIST DE PRODUÇÃO
```
[ ] Roteiro revisado
[ ] Áudio gerado
[ ] Slides/imagens gerados
[ ] Thumbnail criada
[ ] Vídeo montado
[ ] Texto copiado para YouTube Studio
[ ] Publicado/agendado
```

### Step 3: Salvar na Pasta do Episódio
Todos os arquivos em `Episodios/<N>/`.

### Step 4: Atualizar Status
Atualizar status do episódio (pendente → roteiro → produção → publicado).

## Error Handling
- **Tema técnico incorreto:** Aceitar correção e corrigir o roteiro.
- **Tom errado:** Reescrever o bloco problemático.
- **Sem tema definido:** Listar próximos pendentes e pedir escolha.
