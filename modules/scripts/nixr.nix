{ ... }:

{
  programs.zsh.interactiveShellInit = ''
    nixr() {
      local red=$'\e[31m' green=$'\e[32m' yellow=$'\e[33m' cyan=$'\e[36m' reset=$'\e[0m'

      if [[ -z "$1" ]]; then
        echo "''${red}Usage: nixr <message>''${reset}"
        return 1
      fi

      local msg="$*"
      local nixdir=~/nixos
      local committed=0

      # Step 1: Commit current changes if any
      if git -C "$nixdir" status --porcelain | grep -q .; then
        echo "''${cyan}Committing changes...''${reset}"
        git -C "$nixdir" add -A && git -C "$nixdir" commit -m "$msg" || {
          echo "''${red}Commit failed''${reset}"
          return 1
        }
        committed=1
      else
        echo "''${yellow}No changes to commit, switching with existing HEAD''${reset}"
      fi

      # Sanitize message for NixOS label (only [a-zA-Z0-9:_.-] allowed)
      local label
      label=$(echo "$msg" | tr ' ' '_' | tr -cd 'a-zA-Z0-9:_.-')

      # Step 2: Try nh os switch
      echo "''${cyan}Building and switching...''${reset}"
      if NIXOS_LABEL="$label" nh os switch "$nixdir" -- --impure; then
        # Step 3: Push on success
        echo "''${green}Build successful, pushing...''${reset}"
        git -C "$nixdir" push
      else
        echo "''${red}Build failed!''${reset}"
        if [[ "$committed" -eq 1 ]]; then
          echo "''${yellow}Reverting commit (keeping files)...''${reset}"
          git -C "$nixdir" reset --soft HEAD~1
        fi
        return 1
      fi
    }
  '';
}
