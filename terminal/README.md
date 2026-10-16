# Terminal do Ubuntu no Linux Mint Cinnamon

Instala o conjunto usado neste PC: Alacritty (Matte Black, seleção mais legível,
fonte CaskaydiaMono Nerd Font 9pt, F11 para tela cheia), Zellij 0.45.0 (tema
Matte Black, layout compacto, modo locked, molduras completas e atalhos de
painéis/abas), Bash com prompt Omakub, histórico, autocomplete e atalhos do
Readline, fzf, zoxide, eza, bat, fd, btop e fastfetch.

No Mint, em uma sessão Cinnamon com rede e `sudo`, rode como **usuário normal**:

```bash
git clone https://github.com/peres07/dotfiles.git
cd dotfiles
bash terminal/install-mint-terminal.sh
```

Abra uma nova janela do Alacritty (menu ou Ctrl+Alt+T). O script define o
Alacritty como terminal padrão do Cinnamon quando o schema está disponível.
Dentro do Zellij, **Alt+N** cria um painel, **Alt+H/J/K/L** navega entre
painéis e abas, **Ctrl+G** abre os modos, **Ctrl+G → T → N** cria uma aba e
**F11** alterna tela cheia. As setas para cima/baixo buscam comandos do
histórico pelo prefixo digitado; `cd` usa zoxide e `ff` usa fzf com preview.

O instalador usa pacotes apt quando disponíveis. Para versões do Mint sem
`eza`/`fastfetch` no apt, baixa os binários oficiais do GitHub; instala Zellij
0.45.0 e a fonte Nerd Font v3.4.0 diretamente dos respectivos releases.
Detecta automaticamente o formato de configuração do Alacritty 0.13 ou mais
recente.
Requer arquitetura x86_64 ou aarch64 para esses downloads. Não instala o
desktop GNOME nem o Omakub completo. O tema, fonte e atalhos são do terminal;
atalhos globais do Cinnamon permanecem os do notebook.

Configurações existentes diferentes recebem um backup `.backup.AAAAMMDD-HHMMSS`
antes de ser substituídas; links simbólicos são preservados. `.bashrc` e
`.inputrc` recebem uma única linha gerenciada, preservando o conteúdo anterior.
Rodar novamente é seguro. Para reaplicar somente os arquivos versionados,
sem instalar pacotes, use:

```bash
bash terminal/install-mint-terminal.sh --config-only
```

Os arquivos instalados estão em `terminal/mint/`. Ajustes locais de `.bashrc`,
tema ou tamanho de fonte podem ser feitos depois da instalação. A configuração
de desenvolvimento (linguagens do mise, editores, Docker e apps do desktop)
não faz parte deste terminal.
