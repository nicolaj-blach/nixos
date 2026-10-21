{ ... }:
{
  flake.homeManagerModules.zsh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.zsh;
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
            FZF_CTRL_T_OPTS = "--walker-skip .git,node_modules,target,.direnv --preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'";
            FZF_ALT_C_COMMAND = "fd --type d --strip-cwd-prefix --hidden --follow --exclude .git";
            FZF_ALT_C_OPTS = "--walker-skip .git,node_modules,target,.direnv --preview 'eza --tree --level=2 --icons --color=always {}'";

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

          initContent = builtins.replaceStrings [ "@autopair@" ] [ "${pkgs.zsh-autopair}" ] (
            builtins.readFile ./init.zsh
          );

          profileExtra = ''
            # User scripts
            export PATH="$HOME/.local/bin:$PATH"
          '';
        };

        # Zoxide
        programs.zoxide.enable = true;

        # fzf
        programs.fzf.enable = true;

        # bat
        programs.bat.enable = true;

        # eza
        programs.eza = {
          enable = true;
          theme.filenames = lib.mapAttrs (_: glyph: { icon.glyph = glyph; }) (
            import ../../files/_dir-icons.nix
          );
        };
      };
    };
}
