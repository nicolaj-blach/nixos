{
  programs.zsh = {
    enable = true;
    shellAliases = {
      # nix
      nixr = "sudo nixos-rebuild switch --flake ~/nixos#personal-laptop";

      # file system
      lsa = "ls -a";
      
      # git
      gs = "git status";
    }; 
  };
}
