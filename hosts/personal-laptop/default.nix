{ inputs, ... }:

{
  networking.hostName = "personal-laptop";

  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/user.nix
    ../../modules/programs.nix
    ../../modules/shell.nix
    ../../modules/services.nix
    ../../modules/protonmail-bridge.nix
    ../../modules/hyprland.nix
    ../../modules/desktop.nix
    ../../modules/ags.nix
    inputs.walker.nixosModules.default
  ];
}
