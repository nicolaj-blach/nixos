{ pkgs, ... }:

{
  users.users.nicolaj-blach = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      tree
    ];
    shell = pkgs.zsh;
  };
}
