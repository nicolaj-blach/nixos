{ inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/user.nix
    ../../modules/programs.nix
    ../../modules/shell.nix
    ../../modules/services.nix
    ../../modules/hyprland.nix
    inputs.walker.nixosModules.default
  ];
}
