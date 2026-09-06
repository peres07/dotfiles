#!/usr/bin/env bash
set -Eeuo pipefail

# Reaplica somente o perfil original de modelos do OpenAgentsControl.
# Não instala nem atualiza OpenCode, OpenAgentsControl ou dependências.

OAC_DIR="${HOME}/.config/opencode"
AGENT_DIR="${OAC_DIR}/agent"
BACKUP_DIR="${OAC_DIR}/backups/agents-$(date +%Y%m%d-%H%M%S)"

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[AVISO]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[ERRO]\033[0m %s\n' "$*" >&2; exit 1; }

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

check_requirements() {
  command_exists python3 || die "python3 não está disponível."
  [[ -d "${AGENT_DIR}" ]] || die "Diretório de agentes do OAC não encontrado em ${AGENT_DIR}"
}

backup_agents() {
  log "Criando backup dos agentes"
  mkdir -p "${BACKUP_DIR}"
  cp -a "${AGENT_DIR}/." "${BACKUP_DIR}/"
  ok "Backup criado em ${BACKUP_DIR}"
}

configure_models() {
  log "Reaplicando o perfil original de modelos"

  python3 <<'PY'
from pathlib import Path

base = Path.home() / ".config/opencode/agent"

models = {
    base / "core/openagent.md": "openai/gpt-5.6-sol",
    base / "core/opencoder.md": "openai/gpt-5.6-sol",
    base / "subagents/code/build-agent.md": "opencode-go/deepseek-v4-flash",
    base / "subagents/code/coder-agent.md": "opencode-go/deepseek-v4-flash",
    base / "subagents/code/reviewer.md": "opencode-go/deepseek-v4-pro",
    base / "subagents/code/test-engineer.md": "opencode-go/deepseek-v4-flash",
    base / "subagents/core/contextscout.md": "opencode-go/deepseek-v4-flash",
    base / "subagents/core/documentation.md": "opencode-go/glm-5.3",
    base / "subagents/core/externalscout.md": "opencode-go/deepseek-v4-flash",
    base / "subagents/core/task-manager.md": "opencode-go/deepseek-v4-flash",
    base / "subagents/development/devops-specialist.md": "opencode-go/deepseek-v4-pro",
    base / "subagents/development/frontend-specialist.md": "opencode-go/deepseek-v4-flash",
    base / "subagents/system-builder/context-organizer.md": "opencode-go/deepseek-v4-flash",
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

    lines = text[:end].splitlines()
    rest = text[end:]

    for index, line in enumerate(lines):
        if line.startswith("model:"):
            if line.split(":", 1)[1].strip() == model:
                print(f"[OK] {path.name}: já está em {model}")
                return
            lines[index] = f"model: {model}"
            break
    else:
        insert_at = next(
            (index + 1 for index, line in enumerate(lines) if line.startswith("description:")),
            2,
        )
        lines.insert(insert_at, f"model: {model}")

    path.write_text("\n".join(lines) + rest, encoding="utf-8")
    print(f"[OK] {path.name} -> {model}")

for path, model in models.items():
    set_model(path, model)
PY
}

validate_model_ids() {
  if ! command_exists opencode; then
    warn "OpenCode não encontrado; os arquivos foram alterados sem validar o catálogo."
    return
  fi

  log "Validando os modelos do perfil original"

  local required_models=(
    "openai/gpt-5.6-sol"
    "opencode-go/deepseek-v4-flash"
    "opencode-go/deepseek-v4-pro"
    "opencode-go/glm-5.3"
  )
  local models_output

  if ! models_output="$(opencode models 2>/dev/null)"; then
    warn "Não foi possível listar modelos. Valide após conectar OpenAI e OpenCode Go."
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

print_summary() {
  cat <<'EOF'

Perfil original reaplicado.

Provedores necessários no OpenCode:
  - OpenAI -> ChatGPT Plus/Pro
  - OpenCode Go

Reinicie o OpenCode para que os agentes recarreguem a configuração.
EOF
}

main() {
  check_requirements
  backup_agents
  configure_models
  validate_model_ids
  print_summary
}

main "$@"
