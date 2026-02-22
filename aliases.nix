{
  program.zsh = {
    eneble = true;
    shellAliases = {
      # nix
      nixr = "nixos-rebuild switch --flake ~/nixos#personal-laptop";

      # file system
      lsa = "ls -a";
      
      # git
      gs = "git status";
    }; 
  };
}
