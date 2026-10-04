{ ... }:

{
  flake.nixosModules.steam = { pkgs, ... }: {
    # Steam
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
      extraPackages = with pkgs; [
        xorg.libXcursor
        xorg.libXi
        xorg.libXinerama
        xorg.libXScrnSaver
      ];
    };

    # Steam scaling for HiDPI
    environment.sessionVariables.STEAM_FORCE_DESKTOPUI_SCALING = "1.25";

    # Gamemode - optimizes system for gaming
    programs.gamemode = {
      enable = true;
      enableRenice = true;
    };

    # Controller support
    hardware.xpadneo.enable = true;
    hardware.steam-hardware.enable = true;

    # OpenGL/Vulkan support
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    environment.systemPackages = with pkgs; [
      protonup-qt
      mangohud
      vkbasalt
      r2modman
    ];
  };
}
