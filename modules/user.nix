{ pkgs, ... }:

{
  users.users.nicolaj-blach = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };
}
