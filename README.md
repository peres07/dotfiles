# Dotfiles

Este repositório reúne arquivos de configuração e scripts usados para preparar e manter um ambiente de desenvolvimento pessoal. A intenção é centralizar ajustes, facilitar a reinstalação do sistema e manter configurações importantes versionadas.

## Conteúdo

Atualmente, o repositório contém o script `install-opencode-oac.sh`. Outras configurações de ferramentas de terminal e linha de comando poderão ser adicionadas conforme o ambiente evoluir.

## OpenCode e OpenAgentsControl

O arquivo `install-opencode-oac.sh` automatiza a instalação e a configuração inicial do [OpenCode](https://opencode.ai/) com o [OpenAgentsControl](https://github.com/darrenhinde/OpenAgentsControl) em sistemas baseados em Ubuntu ou Debian.

O script:

- instala dependências básicas, como `curl`, `git`, `jq` e `python3`;
- instala o OpenCode e adiciona seu executável ao `PATH`;
- instala o perfil `developer` do OpenAgentsControl em `~/.config/opencode`;
- cria um backup dos agentes antes de alterar suas configurações;
- define os modelos utilizados por cada agente;
- valida a configuração e a disponibilidade dos modelos;
- apresenta os próximos passos para conectar os provedores e testar os agentes.

O script não armazena credenciais. A autenticação deve ser feita dentro do OpenCode com o comando `/connect`.

Para executá-lo:

```bash
chmod +x install-opencode-oac.sh
./install-opencode-oac.sh
```

> Antes de executar scripts de instalação, revise o conteúdo e confirme se as configurações são adequadas ao seu ambiente.

## Configurações baseadas no Omakub

As configurações comuns deste repositório, incluindo ferramentas como [Zellij](https://zellij.dev/), [Alacritty](https://alacritty.org/) e Bash, são baseadas nas configurações e convenções do [Omakub](https://omakub.org/), com adaptações para preferências e necessidades pessoais.

O Omakub serve como ponto de partida para a experiência de terminal e desenvolvimento, enquanto este repositório mantém as personalizações feitas sobre essa base.
