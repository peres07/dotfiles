#!/usr/bin/env bash
set -Eeuo pipefail

# Aplica somente modelos disponíveis no ChatGPT Plus aos agentes do OAC.
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
  log "Aplicando o perfil ChatGPT Plus"

  python3 <<'PY'
from pathlib import Path

base = Path.home() / ".config/opencode/agent"

# Sol: tarefas críticas e código complexo.
# Terra: equilíbrio entre qualidade, velocidade e consumo de cota.
# Luna: descoberta e organização de contexto com menor latência.
models = {
    base / "core/openagent.md": "openai/gpt-5.6-sol",
    base / "core/opencoder.md": "openai/gpt-5.6-sol",
    base / "subagents/code/build-agent.md": "openai/gpt-5.6-terra",
    base / "subagents/code/coder-agent.md": "openai/gpt-5.6-sol",
    base / "subagents/code/reviewer.md": "openai/gpt-5.6-sol",
    base / "subagents/code/test-engineer.md": "openai/gpt-5.6-terra",
    base / "subagents/core/contextscout.md": "openai/gpt-5.6-luna",
    base / "subagents/core/documentation.md": "openai/gpt-5.6-terra",
    base / "subagents/core/externalscout.md": "openai/gpt-5.6-terra",
    base / "subagents/core/task-manager.md": "openai/gpt-5.6-terra",
    base / "subagents/development/devops-specialist.md": "openai/gpt-5.6-sol",
    base / "subagents/development/frontend-specialist.md": "openai/gpt-5.6-terra",
    base / "subagents/system-builder/context-organizer.md": "openai/gpt-5.6-luna",
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

  log "Validando os modelos ChatGPT Plus"

  local required_models=(
    "openai/gpt-5.6-luna"
    "openai/gpt-5.6-terra"
    "openai/gpt-5.6-sol"
  )
  local models_output

  if ! models_output="$(opencode models 2>/dev/null)"; then
    warn "Não foi possível listar modelos. Valide após conectar a OpenAI."
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

Perfil ChatGPT Plus aplicado.

Distribuição:
  - Sol:   OpenAgent, OpenCoder, CoderAgent, CodeReviewer e OpenDevopsSpecialist
  - Terra: BuildAgent, TestEngineer, DocWriter, ExternalScout, TaskManager e OpenFrontendSpecialist
  - Luna:  ContextScout e ContextOrganizer

Conecte somente OpenAI -> ChatGPT Plus/Pro em /connect.
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
