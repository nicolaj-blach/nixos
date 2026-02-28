{ username, ... }:

{
  programs.zsh = {
    enable = true;
    loginShellInit = ''
      if [[ -z $DISPLAY && $(tty) == /dev/tty1 ]]; then
        exec hyprland
      fi
    '';
    interactiveShellInit = ''
      eval "$(zoxide init zsh)"

      nixr() {
        if [[ -z "$1" ]]; then
          echo "Usage: nixr <message>"
          return 1
        fi

        local msg="$*"
        local nixdir=~/nixos
        local committed=0

        # Step 1: Commit current changes if any
        if git -C "$nixdir" status --porcelain | grep -q .; then
          git -C "$nixdir" add -A && git -C "$nixdir" commit -m "$msg" || { echo "Commit failed"; return 1; }
          committed=1
        else
          echo "No changes to commit, switching with existing HEAD"
        fi

        # Sanitize message for NixOS label (only [a-zA-Z0-9:_.-] allowed)
        local label
        label=$(echo "$msg" | tr ' ' '_' | tr -cd 'a-zA-Z0-9:_.-')

        # Step 2: Try nh os switch
        if NIXOS_LABEL="$label" nh os switch "$nixdir" -- --impure; then
          # Step 3: Push on success
          echo "Build successful, pushing..."
          git -C "$nixdir" push
        else
          echo "Build failed!"
          if [[ "$committed" -eq 1 ]]; then
            echo "Reverting commit (keeping files)..."
            git -C "$nixdir" reset --soft HEAD~1
          fi
          return 1
        fi
      }
    '';
    shellAliases = {
      # Nix
      nixu = "sudo nix flake update /home/${username}/nixos";
      nixl = "nixos-rebuild list-generations";
      nhs = "nh search";
      stowd = "stow -t ~ ~/nixos/dotfiles";

      # Navigation
      cd = "z";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # List
      ls = "eza -lh --group-directories-first --icons=auto";
      lsa = "ls -a";
      la = "ls -lah";
      lt = "eza --tree --level=2 --long --icons --git";
      lta = "lt -a";

      # Find
      ff = "fzf --preview 'bat --style=numbers --color=always {}'";
      ffind = "fd --type f | fzf";

      # Git
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      gco = "git checkout";
      gb = "git branch";
      gss = "git status -s";
      lg = "lazygit";

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
      cat = "bat";
      clear = "clear && fastfetch";
      please = "sudo";

      # AI
      oc = "opencode";
      occ = "opencode -c";
    };
  };
}
