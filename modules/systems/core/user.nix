{ metaOwner, ... }:

{
  flake.nixosModules.user = { pkgs, ... }: {
    users.users.${metaOwner.username} = {
      isNormalUser = true;
      description = metaOwner.fullName;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
      ];
      shell = pkgs.zsh;
    };

    security.sudo.wheelNeedsPassword = true;
    programs.zsh.enable = true;
  };
}
