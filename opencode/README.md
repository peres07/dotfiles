# Instalação do OpenCode com OpenAgentsControl

O script [`install-opencode-oac.sh`](install-opencode-oac.sh) prepara uma instalação do [OpenCode](https://opencode.ai/) com o perfil `developer` do [OpenAgentsControl](https://github.com/darrenhinde/OpenAgentsControl). Ele foi criado para sistemas baseados em Ubuntu ou Debian.

## O que o script faz

Durante a execução, o instalador:

1. identifica a distribuição Linux;
2. instala `curl`, `git`, `jq`, `python3` e `ca-certificates` com o APT;
3. instala o OpenCode, caso ele ainda não esteja disponível;
4. adiciona `~/.opencode/bin` ao `PATH` no `.bashrc` ou `.zshrc`;
5. instala ou atualiza o OpenAgentsControl em `~/.config/opencode`;
6. cria um backup dos agentes em `~/.config/opencode/backups/agents-<data-e-hora>`;
7. configura um modelo para cada agente;
8. verifica os arquivos dos agentes e a disponibilidade dos modelos;
9. apresenta as instruções para autenticação e uso.

## Modelos configurados

| Agente | Modelo |
| --- | --- |
| OpenAgent | `openai/gpt-5.6-sol` |
| OpenCoder | `openai/gpt-5.6-sol` |
| BuildAgent | `opencode-go/deepseek-v4.1-flash` |
| CoderAgent | `opencode-go/deepseek-v4.1-flash` |
| CodeReviewer | `opencode-go/deepseek-v4.1-flash` |
| TestEngineer | `opencode-go/deepseek-v4.1-flash` |
| ContextScout | `opencode-go/deepseek-v4.1-flash` |
| DocWriter | `opencode-go/glm-5.3` |
| ExternalScout | `opencode-go/deepseek-v4.1-flash` |
| TaskManager | `opencode-go/deepseek-v4.1-flash` |
| OpenDevopsSpecialist | `opencode-go/deepseek-v4.1-flash` |
| OpenFrontendSpecialist | `opencode-go/deepseek-v4.1-flash` |
| ContextOrganizer | `opencode-go/deepseek-v4.1-flash` |

O script altera o campo `model:` do frontmatter de cada agente. Se uma versão futura do OpenAgentsControl mudar seus arquivos ou adicionar agentes, os arquivos não encontrados e os agentes sem modelo serão apresentados como avisos.

## Requisitos

- uma distribuição baseada em Ubuntu ou Debian;
- acesso ao `sudo` para instalar dependências;
- conexão com a internet;
- uma conta compatível com os provedores OpenAI e OpenCode Go para acessar os modelos configurados.

## Execução

Na raiz deste repositório, execute:

```bash
chmod +x opencode/install-opencode-oac.sh
./opencode/install-opencode-oac.sh
```

O script pode ser executado novamente para atualizar o OpenAgentsControl e reaplicar a configuração dos modelos. Um novo backup dos agentes é criado antes de cada alteração.

## Autenticação e próximos passos

O instalador não armazena credenciais. Depois da instalação:

1. recarregue a configuração do shell, se necessário:

   ```bash
   source ~/.bashrc
   ```

   Para Zsh, use `source ~/.zshrc`.

2. inicie o OpenCode:

   ```bash
   opencode
   ```

3. execute `/connect` e conecte os provedores OpenAI e OpenCode Go;
4. confira os modelos com `/models` ou `opencode models`;
5. teste os agentes principais com `opencode --agent OpenAgent` e `opencode --agent OpenCoder`;
6. dentro de cada projeto, execute `/add-context` para gerar um contexto específico.

## Segurança

O script baixa e executa instaladores remotos, modifica arquivos de configuração do shell e instala pacotes com privilégios administrativos. Revise seu conteúdo antes da execução e confirme se os comandos e modelos são adequados ao seu ambiente.
