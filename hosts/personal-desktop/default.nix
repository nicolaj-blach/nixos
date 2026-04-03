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
}
