{
  lib,
  pkgs,
  username,
  ...
}:

{
  nixpkgs.config.allowUnfree = true;
  boot = {

    # systemd-based initrd (required for TPM2 auto-unlock)
    initrd.systemd.enable = true;

    loader.efi.canTouchEfiVariables = true;

    loader.limine = {
      enable = true;
      maxGenerations = 10;
      enableEditor = false;

      # Secure Boot (run sbctl create-keys + sbctl enroll-keys first)
      secureBoot.enable = true;

      style = {
        wallpapers = [ ];
        wallpaperStyle = "stretched";
        backdrop = "282c34";

        interface = {
          branding = "N-B";
          brandingColor = 6;
          helpHidden = false;
        };

        graphicalTerminal = {
          foreground = "abb2bf";
          background = "ee282c34";
          brightForeground = "c8ccd4";
          brightBackground = "ee353b45";
          margin = 8;
          marginGradient = 0;
          # black;red;green;brown;blue;magenta;cyan;gray
          palette = "282c34;e06c75;98c379;e5c07b;61afef;c678dd;56b6c2;abb2bf";
          brightPalette = "545862;e06c75;98c379;e5c07b;61afef;c678dd;56b6c2;c8ccd4";
          font.scale = "2x2";
        };
      };
    };
  };

  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };

  # TPM2 support (for LUKS auto-unlock after enrollment)
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  users.users.${username}.extraGroups = [ "tss" ];

  time.timeZone = "Europe/Copenhagen";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  fonts.packages =
    with lib;
    with pkgs;
    [
      nerd-fonts.jetbrains-mono
    ];

  system.stateVersion = "25.11";
}
