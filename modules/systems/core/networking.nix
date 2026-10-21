{ ... }:

{
  flake.nixosModules.networking = { pkgs, ... }: {
    networking.networkmanager = {
      enable = true;
      plugins = [ pkgs.networkmanager-openconnect ];
      ensureProfiles.profiles.AAU = {
        connection = {
          id = "AAU";
          type = "vpn";
          autoconnect = false;
        };
        vpn = {
          service-type = "org.freedesktop.NetworkManager.openconnect";
          protocol = "anyconnect";
          gateway = "ssl-vpn1.aau.dk";
          cookie-flags = "2";
          gateway-flags = "2";
          gwcert-flags = "2";
        };
        ipv4.method = "auto";
        ipv6.method = "auto";
      };
    };
    environment.systemPackages = [ pkgs.openconnect ];
    networking.firewall.enable = true;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
