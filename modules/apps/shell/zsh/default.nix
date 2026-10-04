{ ... }:
{
  flake.homeManagerModules.zsh =
    {
      config,
      lib,
      pkgs,
      osConfig,
      unstablePkgs,
      ...
    }:
    let
      cfg = config.programs.zsh;
      # Atuin AI only where the local AI gateway runs (modules/systems/ai)
      aiEnabled = osConfig.ai.enable or false;
    in
    {
      config = lib.mkIf cfg.enable {
        programs.zsh = {
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
          enableCompletion = true;

          oh-my-zsh = {
            enable = true;
            plugins = [
              "git"
              "sudo"
              "vi-mode"
              "history-substring-search"
              "colored-man-pages"
              "extract"
              "copypath"
              "copyfile"
              "fancy-ctrl-z"
              "magic-enter"
              "systemd"
              "bgnotify"
            ];
          };

          plugins = [
            {
              name = "fzf-tab";
              src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
            }
            {
              name = "you-should-use";
              src = "${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use";
            }
            {
              name = "nix-shell";
              src = "${pkgs.zsh-nix-shell}/share/zsh/plugins/zsh-nix-shell";
            }
          ];

          sessionVariables = {
            EDITOR = "emacsclient -c";
            VISUAL = "emacsclient -c";
            KEYTIMEOUT = "1";
            MAGIC_ENTER_GIT_COMMAND = "gst";
            MAGIC_ENTER_OTHER_COMMAND = "ls";
            bgnotify_threshold = "30";

            # fzf configuration
            FZF_DEFAULT_COMMAND = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";
            FZF_CTRL_T_COMMAND = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";
            FZF_CTRL_T_OPTS = ''
              --walker-skip .git,node_modules,target,.direnv
              --preview 'bat -n --color=always {}'
              --bind 'ctrl-/:change-preview-window(down|hidden|)' '';
            FZF_ALT_C_COMMAND = "fd --type d --strip-cwd-prefix --hidden --follow --exclude .git";
            FZF_ALT_C_OPTS = ''
              --walker-skip .git,node_modules,target,.direnv
              --preview 'eza --tree --level=2 --icons --color=always {}' '';

            # Carapace bridges
            CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";

            # nix-ld library path
            LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
          };

          shellAliases = {
            # Navigation
            cd = "z";
            ".." = "cd ..";
            "..." = "cd ../..";
            "...." = "cd ../../..";

            # List
            ls = "eza -lh --group-directories-first --icons=auto";
            lsa = "ls -a";
            la = "ls -lah";
            lm = "eza -lh --sort=modified --icons=auto";
            lt = "eza --tree --level=2 --long --icons --git";
            lta = "lt -a";

            # Find
            ff = "fzf --preview 'bat --style=numbers --color=always {}'";
            ffind = "fd --type f | fzf";

            # Git
            lg = "lazygit";
            ghd = "gh-dash";

            # System
            htop = "btop";
            psg = "ps aux | grep";
            df = "df -h";
            du = "du -h";
            free = "free -h";

            # Network
            ping = "ping -c 5";
            wget = "wget -c";

            # Misc
            bat = "bat --theme=base16-256";
            clear = "clear && fe";
            please = "sudo";

            # Clipboard
            cpi = "wl-copy";
            cpp = "copypath";
            cpf = "copyfile";
            cb = "wl-paste";

            # AI
            oc = "opencode";
            occ = "opencode -c";

            # Terminal tricks
            pipes = "pipes-rs -k curved --palette darker -p 5 -r 0.95";
            matrix = "cmatrix";
          };

          initExtra = ''
            # Vi mode config (must be set before oh-my-zsh loads vi-mode plugin)
            VI_MODE_SET_CURSOR=true

            # zsh-autopair
            source ${pkgs.zsh-autopair}/share/zsh/zsh-autopair/autopair.zsh

            # Secondary prompt
            PROMPT2="    "

            # Shift+Enter inserts newline without executing
            insert-newline() { LBUFFER+=$'\n'; }
            zle -N insert-newline
            bindkey '^[[13;2u' insert-newline

            # Reset to insert mode on every new prompt
            __reset_vi_mode() { zle vi-insert 2>/dev/null; }
            if [[ -z "''${widgets[zle-line-init]+x}" ]]; then
              zle -N zle-line-init __reset_vi_mode
            else
              __orig_line_init="''${widgets[zle-line-init]#user:}"
              function zle-line-init() {
                "''${__orig_line_init}" 2>/dev/null
                zle vi-insert 2>/dev/null
              }
              zle -N zle-line-init
            fi

            # Transient prompt: redraw current prompt without vi indicator on Enter
            function zle-line-finish() {
              __saved_prompt="$PROMPT"
              PROMPT=$' \e[1;32m>\e[0m '
              zle reset-prompt
              PROMPT="$__saved_prompt"
            }
            zle -N zle-line-finish

            # Zoxide
            eval "$(zoxide init zsh)"

            # Carapace: multi-shell completion engine
            zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
            source <(carapace _carapace)

            zstyle ':completion:*:descriptions' format '[%d]'
            zstyle ':completion:*' menu no
            zstyle ':fzf-tab:complete:*:*' fzf-preview '[[ -d $realpath ]] && eza -1 --color=always --icons=always $realpath || bat -n --color=always $realpath 2>/dev/null'
            zstyle ':fzf-tab:*' use-fzf-default-opts yes

            # fzf shell integration (CTRL-T, ALT-C keybindings + fuzzy completion; CTRL-R is atuin)
            source <(fzf --zsh)

            # fzf: completion with fd (faster than default walker)
            _fzf_compgen_path() {
              fd --hidden --follow --exclude .git . "$1"
            }
            _fzf_compgen_dir() {
              fd --type d --hidden --follow --exclude .git . "$1"
            }

            # GPG (required for pinentry to work in terminal)
            export GPG_TTY=$(tty)

            # Inside Emacs (ghostel): open files in the current frame instead of a new one
            if [[ -n "$INSIDE_EMACS" ]]; then
              export EDITOR="emacsclient" VISUAL="emacsclient"
            fi

            # Local overrides (API keys, secrets -- not tracked in git)
            [[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
          '';

          # Run last so atuin, not fzf, owns Ctrl+R in every keymap
          initContent = lib.mkOrder 2000 ''
            bindkey -M emacs '^r' atuin-search
            bindkey -M viins '^r' atuin-search-viins
            bindkey -M vicmd '^r' atuin-search-vicmd

            # Atuin AI: ? on an empty prompt (atuin only binds it in the emacs keymap)
            (( ''${+widgets[self-atuin-ai-question-mark]} )) && bindkey -M viins '?' self-atuin-ai-question-mark

            # Token for the local AI gateway (atuin-ai-server)
            [[ -r /run/secrets/ai-gateway-token ]] && export ATUIN_AI__API_TOKEN="$(< /run/secrets/ai-gateway-token)"

            # Atuin AI model chosen with `aim` (ai-model); re-read before every prompt
            if (( $+commands[ai-model] )); then
              alias aim=ai-model
              _atuin_ai_model() {
                local f="''${XDG_STATE_HOME:-$HOME/.local/state}/atuin/ai-model"
                if [[ -s $f ]]; then
                  export ATUIN_AI__MODEL="$(< $f)"
                else
                  unset ATUIN_AI__MODEL
                fi
              }
              autoload -Uz add-zsh-hook
              add-zsh-hook precmd _atuin_ai_model
              _atuin_ai_model

              # Refresh every tool's model list after the local models change
              ollama() {
                command ollama "$@" || return
                case $1 in
                  pull|rm|cp|create) ai-refresh &! ;;
                esac
              }
            fi
          '';

          profileExtra = ''
            # User scripts
            export PATH="$HOME/.local/bin:$PATH"
          '';
        };

        # Starship prompt
        programs.starship = {
          enable = true;
          settings = {
            format = " $directory$git_branch$git_status$git_state$nix_shell$python$nodejs$rust$cmd_duration$fill$time$line_break$character";

            character = {
              success_symbol = "[ >](bold green)";
              error_symbol = "[ >](bold red)";
              vimcmd_symbol = " [\\[N\\] >](bold purple)";
            };

            directory = {
              style = "bold blue";
              truncation_length = 4;
              truncate_to_repo = true;
              format = "[$path]($style)[$read_only]($read_only_style) ";
              read_only = " ro";
              read_only_style = "red";
            };

            git_branch = {
              style = "purple";
              format = "[$symbol$branch(:$remote_branch)]($style) ";
              symbol = "";
            };

            git_status = {
              style = "red";
              format = "([$all_status$ahead_behind]($style) )";
              modified = "!";
              untracked = "?";
              staged = "+";
              deleted = "x";
              renamed = "r";
              conflicted = "c";
              ahead = "^\${count}";
              behind = "v\${count}";
              diverged = "^\${ahead_count}v\${behind_count}";
            };

            git_state = {
              style = "yellow";
              format = "[\\($state( $progress_current/$progress_total)\\)]($style)";
            };

            nix_shell = {
              style = "cyan";
              format = "[\\[$name\\]]($style) ";
              symbol = "";
              impure_msg = "";
              pure_msg = "";
              unknown_msg = "";
            };

            python = {
              style = "yellow";
              format = "[\${symbol}\${pyenv_prefix}(\${version} )((\$virtualenv) )]($style)";
              symbol = "py ";
            };

            nodejs = {
              style = "green";
              format = "[$symbol($version )]($style)";
              symbol = "node ";
            };

            rust = {
              style = "red";
              format = "[$symbol($version )]($style)";
              symbol = "rs ";
            };

            cmd_duration = {
              style = "yellow";
              format = "[$duration]($style) ";
              min_time = 2000;
            };

            fill = {
              symbol = " ";
            };

            time = {
              disabled = false;
              style = "dimmed white";
              format = "[\\[$time\\]]($style)";
              time_format = "%H:%M";
            };

            line_break = {
              disabled = false;
            };

            continuation_prompt = "     ";
          };
        };

        # Zoxide
        programs.zoxide.enable = true;

        # fzf
        programs.fzf.enable = true;

        # atuin: Ctrl+R history search (Up stays on history-substring-search)
        programs.atuin = {
          enable = true;
          # 18.21 for Atuin AI (? on an empty prompt) and pty-proxy
          package = unstablePkgs.atuin;
          enableZshIntegration = true;
          daemon.enable = aiEnabled;
          flags = [ "--disable-up-arrow" ];
          settings = {
            ai = {
              enabled = aiEnabled;
              endpoint = "http://127.0.0.1:8080";
              endpoint_protocol = "oss";
              tips = false;
            };
            pty_proxy.enabled = aiEnabled;
            auto_sync = false;
            update_check = false;
            style = "compact";
            inline_height = 15;
            show_preview = true;
            enter_accept = false;
            keymap_mode = "vim-insert";
            filter_mode = "global";
            search_mode = "fuzzy";
            history_filter = [
              "^ls$"
              "^cd$"
              "^clear$"
              "^fe$"
            ];
            theme.name = "onedark";
          };
          themes.onedark = {
            theme.name = "onedark";
            colors = {
              Base = "#abb2bf";
              Title = "#61afef";
              Important = "#61afef";
              Guidance = "#c678dd";
              Annotation = "#5c6370";
              Muted = "#5c6370";
              AlertInfo = "#98c379";
              AlertWarn = "#e5c07b";
              AlertError = "#e06c75";
            };
          };
        };

        # bat
        programs.bat.enable = true;

        # eza
        programs.eza = {
          enable = true;
          theme.filenames = lib.mapAttrs (_: glyph: { icon.glyph = glyph; }) (import ../../files/_dir-icons.nix);
        };
      };
    };
}
