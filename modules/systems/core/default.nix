{ self, ... }:

{
  flake.nixosModules.core = { pkgs, ... }: {
    imports = [
      self.nixosModules.boot
      self.nixosModules.user
      self.nixosModules.nix-settings
      self.nixosModules.locale
      self.nixosModules.networking
    ];

    environment.systemPackages = with pkgs; [
      wget
      curl
      git
      vim
      htop
      tree
    ];
  };
}
