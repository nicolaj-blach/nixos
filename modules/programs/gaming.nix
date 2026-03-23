{
  pkgs,
  ...
}:

{
  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  # Gamemode - optimizes system for gaming
  programs.gamemode = {
    enable = true;
    enableRenice = true;
  };

  # Controller support
  hardware.xpadneo.enable = true; # Xbox wireless controller
  hardware.steam-hardware.enable = true; # Steam controller and other Steam hardware

  environment.systemPackages = with pkgs; [
    # Minecraft
    prismlauncher # Modrinth-compatible Minecraft launcher

    # Gaming utilities
    protonup-qt # Manage Proton-GE versions
    mangohud # Performance overlay (NVIDIA-optimized)
    vkbasalt # NVIDIA ReShade-like post-processing
    libvdpau-va-gl # VA-API to VDPAU bridge for video acceleration
    (python3.withPackages (ps: [ ps.psutil ])) # Required by mangohud
  ];

  # OpenGL/Vulkan support
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 32-bit libs for Proton/Wine games
  };
}
