{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Dependencies
    wget
    gcc

    # CLI tools
    stow
    eza
    fzf
    zoxide
    bat
    tldr
    cowsay
    fastfetch
    terminaltexteffects
    fd
    ripgrep

    # Editors
    vim
    neovim

    # Git
    git
    gh
    lazygit

    # Terminal
    ghostty
    zsh
    swww

    # TUI
    yazi
    btop
    bluez
    bluetui
    wiremix
    lazydocker
    ticker
    opencode

    # Dev tools
    bun
    dotnetCorePackages.runtime_10_0-bin
    uv

    # Apps
    discord
    inputs.zen-browser.packages.${pkgs.system}.beta
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    neovim
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.firefox.enable = true;
}
