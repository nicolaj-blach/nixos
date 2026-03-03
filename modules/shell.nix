{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    ohMyZsh = {
      enable = true;
      theme = "";
      plugins = [
        "git"
        "sudo"
        "vi-mode"
        "history-substring-search"
        "colored-man-pages"
        "extract"
        "command-not-found"
      ];
      customPkgs = with pkgs; [
        zsh-autosuggestions
        zsh-syntax-highlighting
      ];
    };

    promptInit = ''
      eval "$(starship init zsh)"

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
    '';

    loginShellInit = ''
      if [[ -z $DISPLAY && $(tty) == /dev/tty1 ]]; then
        exec hyprland
      fi
    '';

    interactiveShellInit = ''
      # Vi mode config (set before oh-my-zsh loads vi-mode plugin)
      VI_MODE_SET_CURSOR=true
      KEYTIMEOUT=1

      eval "$(zoxide init zsh)"

      # Tinty: source shell theme on init and wrap apply/cycle to re-source
      tinty_source_shell_theme() {
        local tinty_data_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"
        while read -r script; do
          [[ -f "$script" ]] && source "$script"
        done < <(find "$tinty_data_dir" -maxdepth 1 -type f -name "*.sh" 2>/dev/null)
      }

      tinty() {
        command tinty "$@"
        local subcommand="$1"
        if [[ "$subcommand" == "apply" || "$subcommand" == "init" || "$subcommand" == "cycle" ]]; then
          tinty_source_shell_theme
        fi
      }

      tinty_source_shell_theme
    '';
  };
}
