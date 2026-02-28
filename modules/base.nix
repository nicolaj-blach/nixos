{ lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Copenhagen";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  fonts.packages = with lib; with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  system.stateVersion = "25.11";
}
