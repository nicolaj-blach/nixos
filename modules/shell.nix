{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "git"
        "sudo"
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

    loginShellInit = ''
      if [[ -z $DISPLAY && $(tty) == /dev/tty1 ]]; then
        exec hyprland
      fi
    '';

    interactiveShellInit = ''
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
