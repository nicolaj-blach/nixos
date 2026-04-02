{
  inputs,
  configModules,
  config,
  ...
}:

{
  networking.hostName = "personal-desktop";

  imports = [
    ./hardware-configuration.nix
    ./luks.nix
    ./windows.nix
    configModules.base
    configModules.desktop
    configModules.programs
    inputs.walker.nixosModules.default
  ];

  # NVIDIA proprietary drivers for gaming (desktop only)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
  };

  # NVIDIA OpenGL fixes for Ghostty/GTK apps (reduces random freezes)
  environment.sessionVariables = {
    __GL_YIELD = "usleep";
    __GL_THREADED_OPTIMIZATION = "0";
    __GL_MaxFramesAllowed = "1";
  };
}
