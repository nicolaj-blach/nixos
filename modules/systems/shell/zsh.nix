{ ... }:

{
  flake.nixosModules.zsh =
    { pkgs, ... }:
    {
      programs.zsh.enable = true;

      # Required packages for zsh configuration
      environment.systemPackages = with pkgs; [
        # Shell tools
        starship
        zoxide
        carapace
        fzf
        fd
        bat
        eza
        btop
        fastfetch

        # zsh plugins
        oh-my-zsh
        zsh-autosuggestions
        zsh-syntax-highlighting
        zsh-autopair
      ];

      # Link zsh plugin dirs into /run/current-system/sw/share/
      environment.pathsToLink = [
        "/share/oh-my-zsh"
        "/share/zsh-syntax-highlighting"
        "/share/zsh-autopair"
        "/share/zsh"
      ];
    };
}
