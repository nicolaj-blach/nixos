{ ... }:

{
  programs.zsh.interactiveShellInit = ''
    nixs() {
      local red=$'\e[31m' green=$'\e[32m' yellow=$'\e[33m' cyan=$'\e[36m' reset=$'\e[0m'

      local selection
      selection=$(nixos-rebuild list-generations 2>/dev/null | awk '
        BEGIN {
          reset  = "\033[0m"
          bold   = "\033[1m"
          blue   = "\033[34m"
          green  = "\033[32m"
          cyan   = "\033[36m"
        }
        NR == 1 {
          printf "%s%-6s  %-20s  %s%s\n", blue bold, "Gen", "Date", "Description", reset
          next
        }
        $NF == "True" { next }
        {
          version = $4
          gsub(/_/, " ", version)
          printf "%-6s  %s%s %s%s  %s%s%s\n", \
            $1, cyan, $2, $3, reset, green, version, reset
        }
      ' | fzf --ansi --header-lines=1 --tac --no-sort --tiebreak=begin)
      [[ -z "$selection" ]] && return 0

      local gen
      gen=$(echo "$selection" | awk '{print $1}')

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
