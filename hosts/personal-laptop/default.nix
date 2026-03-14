{ inputs, configModules, ... }:

{
  networking.hostName = "personal-laptop";

  imports = [
    ./hardware-configuration.nix
    ./luks.nix
    configModules.base
    configModules.desktop
    configModules.programs
    inputs.walker.nixosModules.default
  ];

  # Fingerprint reader (Framework 16)
  services.fprintd.enable = true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.hyprlock.fprintAuth = true;
}
