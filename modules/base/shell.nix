_:

{
  programs.zsh.enable = true;

  # Link zsh plugin dirs into /run/current-system/sw/share/ so
  # the Stow-managed ~/.zshrc can source them by stable path.
  environment.pathsToLink = [
    "/share/oh-my-zsh"
    "/share/zsh/plugins/fast-syntax-highlighting"
    "/share/zsh-autopair"
  ];
}
