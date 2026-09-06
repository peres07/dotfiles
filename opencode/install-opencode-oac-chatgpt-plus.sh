#!/usr/bin/env bash
set -Eeuo pipefail

# ==============================================================================
# OpenCode + OpenAgentsControl bootstrap — ChatGPT Plus
# Ubuntu/Debian
#
# Instala:
#   - curl, git, jq, python3
#   - OpenCode
#   - OpenAgentsControl (perfil developer) globalmente em ~/.config/opencode
#   - Configura todos os agentes com modelos disponíveis no ChatGPT Plus
#
# NÃO armazena credenciais.
# Após a instalação, use /connect dentro do OpenCode para conectar:
#   - OpenAI -> ChatGPT Plus/Pro
# ==============================================================================

OAC_DIR="${HOME}/.config/opencode"
AGENT_DIR="${OAC_DIR}/agent"
TMP_INSTALLER="/tmp/oac-install.sh"
BACKUP_DIR="${OAC_DIR}/backups/agents-$(date +%Y%m%d-%H%M%S)"

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[AVISO]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[ERRO]\033[0m %s\n' "$*" >&2; exit 1; }

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_ubuntu_like() {
  if [[ ! -f /etc/os-release ]]; then
    die "Não foi possível identificar a distribuição."
  fi

  # shellcheck disable=SC1091
  source /etc/os-release

  case "${ID:-}" in
    ubuntu|debian|linuxmint|pop) ;;
    *)
      warn "Distribuição detectada: ${PRETTY_NAME:-desconhecida}. O script foi pensado para Ubuntu/Debian."
      ;;
  esac
}

install_dependencies() {
  log "Instalando dependências básicas"
  sudo apt update
  sudo apt install -y curl git jq python3 ca-certificates
}

ensure_opencode_path() {
  local path_line='export PATH="$HOME/.opencode/bin:$PATH"'
  local shell_rc

  # Disponibiliza o OpenCode imediatamente nesta execução do script.
  export PATH="${HOME}/.opencode/bin:${PATH}"

  # Persiste o PATH para novos terminais.
  case "${SHELL:-}" in
    */zsh)
      shell_rc="${HOME}/.zshrc"
      ;;
    *)
      shell_rc="${HOME}/.bashrc"
      ;;
  esac

  touch "${shell_rc}"

  if grep -Fqx "${path_line}" "${shell_rc}"; then
    ok "PATH do OpenCode já configurado em ${shell_rc}"
  else
    {
      printf '\n# OpenCode\n'
      printf '%s\n' "${path_line}"
    } >> "${shell_rc}"
    ok "PATH do OpenCode adicionado permanentemente em ${shell_rc}"
  fi
}

install_opencode() {
  ensure_opencode_path
  if command_exists opencode; then
    ok "OpenCode já instalado: $(opencode --version 2>/dev/null || echo 'versão não detectada')"
    return
  fi

  log "Instalando OpenCode"
  curl -fsSL https://opencode.ai/install | bash

  # Garante novamente o PATH após a instalação.
  ensure_opencode_path

  if ! command_exists opencode; then
    warn "OpenCode foi instalado, mas o binário não foi encontrado em ${HOME}/.opencode/bin."
  else
    ok "OpenCode instalado: $(opencode --version)"
  fi
}

install_oac() {
  log "Instalando/atualizando OpenAgentsControl em ${OAC_DIR}"
  mkdir -p "${OAC_DIR}"

  curl -fsSL \
    https://raw.githubusercontent.com/darrenhinde/OpenAgentsControl/main/install.sh \
    -o "${TMP_INSTALLER}"

  bash "${TMP_INSTALLER}" developer --install-dir "${OAC_DIR}"

  [[ -d "${AGENT_DIR}" ]] || die "Diretório de agentes do OAC não encontrado em ${AGENT_DIR}"
  ok "OpenAgentsControl instalado"
}

backup_agents() {
  log "Criando backup dos agentes antes de alterar modelos"
  mkdir -p "${BACKUP_DIR}"
  cp -a "${AGENT_DIR}/." "${BACKUP_DIR}/"
  ok "Backup criado em ${BACKUP_DIR}"
}

configure_models() {
  log "Configurando modelos ChatGPT Plus por agente"

  python3 <<'PY'
from pathlib import Path

home = Path.home()
base = home / ".config/opencode/agent"

# Sol para tarefas de maior impacto, Terra para o trabalho cotidiano e Luna
# para descoberta/organização de contexto com menor latência e consumo de cota.
models = {
    base / "core/openagent.md":
        "openai/gpt-5.6-sol",

    base / "core/opencoder.md":
        "openai/gpt-5.6-sol",

    base / "subagents/code/build-agent.md":
        "openai/gpt-5.6-terra",

    base / "subagents/code/coder-agent.md":
        "openai/gpt-5.6-sol",

    base / "subagents/code/reviewer.md":
        "openai/gpt-5.6-sol",

    base / "subagents/code/test-engineer.md":
        "openai/gpt-5.6-terra",

    base / "subagents/core/contextscout.md":
        "openai/gpt-5.6-luna",

    base / "subagents/core/documentation.md":
        "openai/gpt-5.6-terra",

    base / "subagents/core/externalscout.md":
        "openai/gpt-5.6-terra",

    base / "subagents/core/task-manager.md":
        "openai/gpt-5.6-terra",

    base / "subagents/development/devops-specialist.md":
        "openai/gpt-5.6-sol",

    base / "subagents/development/frontend-specialist.md":
        "openai/gpt-5.6-terra",

    base / "subagents/system-builder/context-organizer.md":
        "openai/gpt-5.6-luna",
}

def set_model(path: Path, model: str) -> None:
    if not path.exists():
        print(f"[AVISO] Arquivo não encontrado: {path}")
        return

    text = path.read_text(encoding="utf-8")

    if not text.startswith("---\n"):
        print(f"[AVISO] Sem frontmatter YAML: {path}")
        return

    end = text.find("\n---", 4)
    if end == -1:
        print(f"[AVISO] Frontmatter sem fechamento: {path}")
        return

    frontmatter = text[:end]
    rest = text[end:]
    lines = frontmatter.splitlines()

    replaced = False
    for i, line in enumerate(lines):
        if line.startswith("model:"):
            current = line.split(":", 1)[1].strip()
            if current == model:
                print(f"[OK] {path.name}: já está em {model}")
                return
            lines[i] = f"model: {model}"
            replaced = True
            break

    if not replaced:
        insert_at = 2
        for i, line in enumerate(lines):
            if line.startswith("description:"):
                insert_at = i + 1
                break
        lines.insert(insert_at, f"model: {model}")

    path.write_text("\n".join(lines) + rest, encoding="utf-8")
    print(f"[OK] {path.name} -> {model}")

for path, model in models.items():
    set_model(path, model)
PY
}

validate_agents() {
  log "Modelos configurados"

  local missing=0

  while IFS= read -r f; do
    printf '%-28s ' "$(basename "$f"):"
    if grep -q '^model:' "$f"; then
      grep '^model:' "$f" | head -1
    else
      printf 'SEM MODELO\n'
      missing=1
    fi
  done < <(find "${AGENT_DIR}" -type f -name '*.md' | sort)

  if [[ "${missing}" -eq 1 ]]; then
    warn "Há arquivos de agente sem model:. Isso pode ser normal se uma versão futura do OAC adicionar novos agentes."
  fi
}

validate_model_ids() {
  if ! command_exists opencode; then
    return
  fi

  log "Validando disponibilidade dos modelos ChatGPT Plus configurados"

  local required_models=(
    "openai/gpt-5.6-luna"
    "openai/gpt-5.6-terra"
    "openai/gpt-5.6-sol"
  )

  local models_output
  if ! models_output="$(opencode models 2>/dev/null)"; then
    warn "Não foi possível listar modelos agora. Faça a validação após conectar a OpenAI."
    return
  fi

  for model in "${required_models[@]}"; do
    if grep -Fxq "${model}" <<<"${models_output}"; then
      ok "${model}"
    else
      warn "Modelo não encontrado atualmente: ${model}"
    fi
  done
}

print_next_steps() {
  cat <<'EOF'

===============================================================================
INSTALAÇÃO CONCLUÍDA — PERFIL CHATGPT PLUS
===============================================================================

1. O script configura automaticamente ~/.opencode/bin no PATH permanente.
   Se este terminal já estava aberto antes da instalação, você também pode executar:

   source ~/.bashrc

   (ou source ~/.zshrc, caso use Zsh)

2. Execute:

   opencode

3. Dentro do OpenCode, conecte o provedor:

   /connect

   - OpenAI -> autentique com sua conta ChatGPT Plus/Pro

4. Confira os modelos:

   /models

   ou, fora da TUI:

   opencode models

5. Teste os agentes principais:

   opencode --agent OpenAgent

   e:

   opencode --agent OpenCoder

6. Em cada projeto, entre no diretório e execute o fluxo de contexto do OAC:

   /add-context

   Isso cria contexto específico do projeto sem misturar regras de projetos diferentes.

-------------------------------------------------------------------------------
MODELOS CONFIGURADOS — CHATGPT PLUS
-------------------------------------------------------------------------------

OpenAgent              -> openai/gpt-5.6-sol
OpenCoder              -> openai/gpt-5.6-sol

BuildAgent             -> openai/gpt-5.6-terra
CoderAgent             -> openai/gpt-5.6-sol
CodeReviewer           -> openai/gpt-5.6-sol
TestEngineer           -> openai/gpt-5.6-terra

ContextScout           -> openai/gpt-5.6-luna
DocWriter              -> openai/gpt-5.6-terra
ExternalScout          -> openai/gpt-5.6-terra
TaskManager            -> openai/gpt-5.6-terra

OpenDevopsSpecialist   -> openai/gpt-5.6-sol
OpenFrontendSpecialist -> openai/gpt-5.6-terra

ContextOrganizer       -> openai/gpt-5.6-luna

===============================================================================
EOF
}

main() {
  require_ubuntu_like
  install_dependencies
  install_opencode
  install_oac
  backup_agents
  configure_models
  validate_agents
  validate_model_ids
  print_next_steps
}

main "$@"
