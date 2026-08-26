#!/usr/bin/env bash
set -Eeuo pipefail

ALACRITTY_THEME="${HOME}/.config/alacritty/theme.toml"
ZELLIJ_CONFIG="${HOME}/.config/zellij/config.kdl"

for file in "${ALACRITTY_THEME}" "${ZELLIJ_CONFIG}"; do
  if [[ ! -f "${file}" ]]; then
    printf 'Erro: arquivo nao encontrado: %s\n' "${file}" >&2
    exit 1
  fi
done

python3 - "${ALACRITTY_THEME}" "${ZELLIJ_CONFIG}" <<'PY'
from pathlib import Path
import re
import shutil
import sys

alacritty_theme = Path(sys.argv[1])
zellij_config = Path(sys.argv[2])


def save(path: Path, content: str) -> None:
    current = path.read_text(encoding="utf-8")
    if current == content:
        print(f"[OK] Ja configurado: {path}")
        return

    backup = path.with_name(f"{path.name}.dotfiles-backup")
    if not backup.exists():
        shutil.copy2(path, backup)
        print(f"[OK] Backup criado: {backup}")

    path.write_text(content, encoding="utf-8")
    print(f"[OK] Configuracao aplicada: {path}")


def configure_alacritty(path: Path) -> str:
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    section_start = None
    section_end = len(lines)

    for index, line in enumerate(lines):
        if line.strip() == "[colors.selection]":
            section_start = index
            continue
        if section_start is not None and re.match(r"^\s*\[.+]\s*$", line):
            section_end = index
            break

    if section_start is None:
        separator = "" if not lines or lines[-1].endswith("\n") else "\n"
        return "".join(lines) + separator + "\n[colors.selection]\nbackground = \"#555555\"\n"

    for index in range(section_start + 1, section_end):
        if re.match(r"^\s*background\s*=", lines[index]):
            indent = lines[index][: len(lines[index]) - len(lines[index].lstrip())]
            lines[index] = f'{indent}background = "#555555"\n'
            return "".join(lines)

    lines.insert(section_start + 1, 'background = "#555555"\n')
    return "".join(lines)


def configure_zellij(path: Path) -> str:
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    configured = []
    has_frames = False
    has_style = False

    for line in lines:
        if re.match(r"^\s*pane_frames\s+", line):
            if not has_frames:
                configured.append("pane_frames true\n")
                has_frames = True
            continue
        if re.match(r"^\s*pane_frame_style\s+", line):
            if not has_style:
                configured.append('pane_frame_style "full"\n')
                has_style = True
            continue
        if re.match(r"^\s*pane_frames_style\s+", line):
            continue
        configured.append(line)

    missing = []
    if not has_frames:
        missing.append("pane_frames true\n")
    if not has_style:
        missing.append('pane_frame_style "full"\n')

    if missing:
        insert_at = next(
            (
                index + 1
                for index, line in enumerate(configured)
                if re.match(r"^\s*default_layout\s+", line)
            ),
            len(configured),
        )
        configured[insert_at:insert_at] = missing

    return "".join(configured)


save(alacritty_theme, configure_alacritty(alacritty_theme))
save(zellij_config, configure_zellij(zellij_config))
PY

printf '\nConfiguracao concluida. Reinicie a sessao do Zellij para exibir as molduras.\n'
