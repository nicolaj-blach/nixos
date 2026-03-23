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
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
    modesetting.enable = true;
    powerManagement.enable = true;
  };
}
