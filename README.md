# Dotfiles

Este repositório reúne arquivos de configuração e scripts usados para preparar e manter um ambiente de desenvolvimento pessoal. A intenção é centralizar ajustes, facilitar a reinstalação do sistema e manter configurações importantes versionadas.

## Conteúdo

Atualmente, o repositório contém configurações e scripts organizados por ferramenta. Outras configurações de terminal e linha de comando poderão ser adicionadas conforme o ambiente evoluir.

## OpenCode e OpenAgentsControl

O script [`opencode/install-opencode-oac.sh`](opencode/install-opencode-oac.sh) automatiza a instalação e a configuração inicial do [OpenCode](https://opencode.ai/) com o [OpenAgentsControl](https://github.com/darrenhinde/OpenAgentsControl) em sistemas baseados em Ubuntu ou Debian.

Consulte a [documentação do instalador](opencode/README.md) para conhecer seu funcionamento, os modelos configurados, os requisitos e as instruções de uso.

## Configurações baseadas no Omakub

As configurações comuns deste repositório, incluindo ferramentas como [Zellij](https://zellij.dev/), [Alacritty](https://alacritty.org/) e Bash, são baseadas nas configurações e convenções do [Omakub](https://omakub.org/), com adaptações para preferências e necessidades pessoais.

O Omakub serve como ponto de partida para a experiência de terminal e desenvolvimento, enquanto este repositório mantém as personalizações feitas sobre essa base.

O script [`terminal/configure-omakub-terminal.sh`](terminal/configure-omakub-terminal.sh) aumenta o contraste da seleção no tema Matte Black do Alacritty e habilita molduras completas no Zellij:

```bash
./terminal/configure-omakub-terminal.sh
```

O script pode ser executado novamente sem duplicar configurações. Antes da primeira alteração, ele cria arquivos de backup com o sufixo `.dotfiles-backup`.
