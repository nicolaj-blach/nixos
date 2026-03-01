{ ... }:

{
  programs.zsh.interactiveShellInit = ''
    nixs() {
      local red=$'\e[31m' green=$'\e[32m' yellow=$'\e[33m' cyan=$'\e[36m' reset=$'\e[0m'

      local selection
      selection=$(nixl | grep -v '^\*' | fzf --ansi --header-lines=1 --tac --no-sort --tiebreak=begin)
      [[ -z "$selection" ]] && return 0

      local gen
      gen=$(echo "$selection" | awk '{print $1}' | tr -cd '0-9')

      if [[ -z "$gen" ]]; then
        echo "''${red}Could not parse generation number''${reset}"
        return 1
      fi

      echo "''${cyan}Switching to generation ''${gen}...''${reset}"
      sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation "$gen" && \
        sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch && \
        echo "''${green}Switched to generation ''${gen}''${reset}"
    }
  '';
}
