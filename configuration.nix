{ config, lib, pkgs, inputs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  imports =
    [ 
      ./hardware-configuration.nix
      ./aliases.nix

      inputs.walker.nixosModules.default
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "personal-laptop"; 

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Copenhagen";

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  programs.hyprlock.enable = true;

  services.getty.autologinUser = "nicolaj-blach";
  programs.zsh.loginShellInit = ''
    if [[ -z $DISPLAY && $(tty) == /dev/tty1 ]]; then
      exec hyprland
    fi
    eval "$(zoxide init zsh)"
  '';

  programs.walker.enable = true;

  services.printing.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nicolaj-blach = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
    shell = pkgs.zsh;
  };

  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    # dependencies
    wget
    gcc

    # cli tools
    eza
    fzf
    zoxide
    bat
    tldr
    cowsay
    fastfetch
    
    # editors
    vim
    neovim

    # git
    git
    gh
    lazygit

    # terminal
    ghostty
    zsh
    swww

    # apps
    discord-ptb
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    neovim
  ];
  
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11"; 
}
