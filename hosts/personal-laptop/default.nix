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
    ../../modules/theme.nix
    inputs.walker.nixosModules.default
  ];
}
