{ inputs, configModules, ... }:

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
}
