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

  # Fingerprint OR password auth (fingerprint times out after 10s)
  security.pam.services.sudo = {
    fprintAuth = false;
    rules.auth.fprintd = {
      order = 11300;
      control = "sufficient";
      modulePath = "pam_fprintd.so";
      args = [ "timeout=10" ];
    };
  };

  security.pam.services.hyprlock.fprintAuth = true;
}
