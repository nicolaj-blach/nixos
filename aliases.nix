{
  programs.zsh = {
    enable = true;
    shellAliases = {
      # nix
      nixr = "sudo nixos-rebuild switch --flake ~/nixos#personal-laptop";

      # file system
      cd = "z";
      ls = "eza -lh --group-directories-first --icons=auto";
      lsa = "ls -a";
      lt="eza --tree --level=2 --long --icons --git";
      lta="lt -a";
      ff = "fzf --preview 'bat --style=numbers --color=always {}'";
      
      # git
      gs = "git status";
    }; 
  };
}
