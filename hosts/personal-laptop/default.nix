{ inputs, configModules, ... }:

{
  networking.hostName = "personal-laptop";

  imports = [
    ./hardware-configuration.nix
    ./luks.nix
    configModules.base
    configModules.desktop
    configModules.programs
    configModules.fingerPrint
    inputs.walker.nixosModules.default
  ];
}
