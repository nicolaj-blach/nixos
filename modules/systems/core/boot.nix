{ ... }:

{
  flake.nixosModules.boot = { lib, pkgs, ... }: {
    boot.loader = {
      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = 10;
        editor = false;
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    security.tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };

    environment.systemPackages = with pkgs; [
      sbctl
      tpm2-tss
      tpm2-tools
    ];
  };
}
