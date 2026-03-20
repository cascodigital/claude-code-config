# Claude Code Config — Portable Multi-Machine Setup

![Status](https://img.shields.io/badge/Status-Active-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)
![Author](https://img.shields.io/badge/Author-Casco%20Digital-orange)

![Claude Code](https://img.shields.io/badge/Claude_Code-CLI-blueviolet?style=flat-square)
![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=flat-square&logo=python&logoColor=white)
![Node](https://img.shields.io/badge/Node.js-18+-339933?style=flat-square&logo=nodedotjs&logoColor=white)

Configuração portátil do [Claude Code](https://docs.anthropic.com/en/docs/claude-code) para múltiplas máquinas (Windows, Linux, Mac). Inclui skills personalizadas, template de MCPs e script de setup automatizado.

---

## O Problema

Claude Code armazena toda a configuração em `~/.claude/`. Ao usar múltiplas máquinas, manter skills, instruções e MCPs sincronizados exige uma estratégia. Esta é a minha.

---

## 🏗️ Estrutura

```
~/.claude/
├── CLAUDE.md              # Instruções globais (personalidade, regras, contexto)
├── settings.json          # Permissões e modelo padrão
├── mcp-template.jsonc     # Template portátil dos MCPs (com placeholders)
├── setup.sh               # Script de setup (gera .claude.json + instala deps)
├── .mcp-secrets           # API keys e senhas (LOCAL, gitignored)
├── .claude.json           # Config real dos MCPs (LOCAL, gerado pelo setup.sh)
├── skills/                # Skills customizadas (sincronizadas via git)
│   ├── skill-a/SKILL.md
│   ├── skill-b/SKILL.md
│   └── ...
└── mcp-servers/           # Código dos MCP servers (LOCAL, gitignored)
    ├── my-node-mcp/       # package.json + index.js
    └── my-python-mcp/     # requirements.txt + server.py + .env
```

### O que sincroniza vs. o que é local

| Sincroniza (git) | Local por máquina |
|:---|:---|
| `CLAUDE.md` | `.claude.json` (gerado pelo setup.sh) |
| `settings.json` | `.mcp-secrets` (API keys) |
| `skills/` | `mcp-servers/` (node_modules, venvs) |
| `mcp-template.jsonc` | `settings.local.json` |
| `setup.sh` | `projects/`, `cache/`, `sessions/` |

---

## 🚀 Setup — Máquina Nova

### 1. Clonar

```bash
git clone https://github.com/SEU_USER/claude-config.git ~/.claude
```

> Se `~/.claude` já existe: `mv ~/.claude ~/.claude.bak`

### 2. Copiar fontes dos MCP servers

Os `mcp-servers/` não vão no repo (contêm `node_modules` e `venvs` específicos por OS).
Copie apenas os **fontes** via SSH de uma máquina existente:

```bash
rsync -av \
  --exclude='node_modules' \
  --exclude='venv' \
  --exclude='.venv' \
  --exclude='__pycache__' \
  usuario@MAQUINA_ORIGEM:~/.claude/mcp-servers/ ~/.claude/mcp-servers/
```

Isso copia apenas `.py`, `requirements.txt`, `package.json`, `.env` — tudo leve e portátil.
O `setup.sh` cria venvs e `node_modules` corretos para o OS da máquina nova.

> **Os arquivos `.py` são portáteis entre Windows e Linux.** O que muda entre OS (paths de venv, separadores) é resolvido pelo `setup.sh`.

### 3. Rodar o setup

```bash
cd ~/.claude && ./setup.sh
```

O script:
1. **Detecta o OS** (Windows/Linux/Mac)
2. **Pede API keys** interativamente (salva em `.mcp-secrets`, uma vez só)
3. **Gera `~/.claude.json`** com paths corretos para o OS
4. **Verifica/instala** dependências de cada MCP (npm install / pip install)
5. **Avisa** o que está faltando (.env, tokens, etc.)

### 4. Reiniciar Claude Code

Feche e reabra o Claude Code para carregar os MCPs.

---

## 🔄 Dia a Dia

### Editou uma skill?

```bash
cd ~/.claude
git add -A && git commit -m "update skill-x" && git push
```

### Atualizar outra máquina?

```bash
cd ~/.claude && git pull
```

### Adicionou um MCP novo?

1. Adicionar entrada no `mcp-template.jsonc`
2. Adicionar lógica de install no `setup.sh` (função `install_node_mcp` ou `install_python_mcp`)
3. Commit + push
4. Na outra máquina: `git pull && ./setup.sh`

---

## ⚙️ Como Funciona

### `mcp-template.jsonc`

Template com placeholders que o `setup.sh` substitui por valores reais:

```jsonc
// Placeholders disponíveis:
// {{HOME}}        → /home/user (Linux) ou C:/Users/user (Windows)
// {{HOME_NATIVE}} → mesmo que HOME, formato nativo do OS
// {{VENV_BIN}}    → bin (Linux/Mac) ou Scripts (Windows)
// {{EXE}}         → vazio (Linux/Mac) ou .exe (Windows)
// {{SECRET_NAME}} → valor do .mcp-secrets

{
  "mcpServers": {
    "my-python-mcp": {
      "type": "stdio",
      "command": "{{HOME}}/.claude/mcp-servers/my-mcp/venv/{{VENV_BIN}}/python{{EXE}}",
      "args": ["{{HOME}}/.claude/mcp-servers/my-mcp/server.py"],
      "env": {
        "API_KEY": "{{MY_API_KEY}}"
      }
    }
  }
}
```

### `.mcp-secrets`

Arquivo local (gitignored) criado pelo `setup.sh` na primeira execução:

```bash
# Gerado por setup.sh — NÃO commitar
MY_API_KEY="sk-abc123..."
ANOTHER_SECRET="xyz..."
```

### `setup.sh`

Script bash que:
- Detecta OS via `uname`
- Lê secrets de `.mcp-secrets` (ou pede interativamente)
- Substitui placeholders no template
- Mescla com `.claude.json` existente (preserva campos que não são MCPs)
- Cria venvs e instala deps para cada MCP que ainda não tem

---

## 📁 Skills

Skills são arquivos `SKILL.md` dentro de `~/.claude/skills/<nome>/`. Claude Code as carrega automaticamente quando invocadas.

### Skills portáteis (copiam direto entre OS)

Skills que são "pura persona" — sem paths, sem comandos OS-specific:
- Assistentes com personalidade
- Análises baseadas em API/MCP
- Workflows de texto/decisão

### Skills OS-specific (precisam de paths)

Skills que referenciam caminhos de arquivos, scripts locais ou comandos específicos de OS precisam de seção de paths adaptável:

```markdown
#### Paths (ajuste por OS)
- **Home:** `C:\Users\user\` (Windows) | `~/` (Linux)
- **Python:** `py` (Windows) | `python3` (Linux)
- **Temp:** `%TEMP%` (Windows) | `/tmp/` (Linux)
```

---

## 🔒 Segurança

| Item | Onde fica | No repo? |
|:---|:---|:---|
| API keys, senhas | `.mcp-secrets` | **Não** (gitignored) |
| Tokens de autenticação | dentro de `mcp-servers/` | **Não** (gitignored) |
| URLs de serviço | `mcp-template.jsonc` | Sim (sem auth) |
| Skills e instruções | `skills/`, `CLAUDE.md` | Sim |

> **Nunca commite** `.mcp-secrets`, `.env`, `oauth.json`, ou qualquer arquivo com credenciais.

---

## 🛠️ Adaptando para seu uso

### 1. Fork este repo

### 2. Edite `CLAUDE.md` com suas instruções

Substitua o conteúdo por suas regras, contexto e preferências.

### 3. Crie suas skills em `skills/`

Cada skill é uma pasta com um `SKILL.md`. Veja os exemplos no repo.

### 4. Configure seus MCPs em `mcp-template.jsonc`

Adicione seus MCP servers com placeholders para paths e secrets.

### 5. Atualize `setup.sh`

Adicione as chamadas `install_node_mcp` / `install_python_mcp` para seus MCPs, e `ask_secret` para seus secrets.

### 6. Rode `./setup.sh` e pronto

---

## 📋 Checklist — Máquina Nova

```
[ ] git clone do repo
[ ] rsync dos mcp-servers (fontes) de máquina existente
[ ] ./setup.sh (gera config, instala deps, pede secrets)
[ ] Reiniciar Claude Code
[ ] Verificar MCPs funcionando (testar um comando)
[ ] Login nos MCPs que precisam de auth (ms365, etc.)
```

---

## License

MIT — use, adapte, compartilhe.
