{ ... }:

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
    '';
    shellAliases = {
      # Nix
      nixr = "sudo nixos-rebuild switch --flake ~/nixos#$(hostname)";
      nixu = "sudo nix flake update";
      nixl = "nixos-rebuild list-generations";

      # Navigation
      cd = "z";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # List
      ls = "eza -lh --group-directories-first --icons=auto";
      lsa = "ls -a";
      ll = "ls -lh";
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
    };
  };
}
