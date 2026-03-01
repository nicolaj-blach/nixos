{ inputs, ... }:

{
  networking.hostName = "personal-laptop";

  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/user.nix
    ../../modules/programs.nix
    ../../modules/shell.nix
    ../../modules/aliases.nix
    ../../modules/scripts/nixr.nix
    ../../modules/scripts/nixl.nix
    ../../modules/scripts/nixs.nix
    ../../modules/services.nix
    ../../modules/hyprland.nix
    ../../modules/desktop.nix
    inputs.walker.nixosModules.default
  ];
}
