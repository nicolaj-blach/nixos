{ ... }:

{
  flake.nixosModules.services =
    { pkgs, ... }:
    {
      # SwayOSD libinput backend for caps/num/scroll lock detection
      systemd.services.swayosd-libinput-backend = {
        description = "SwayOSD libinput backend";
        wantedBy = [ "graphical.target" ];
        partOf = [ "graphical.target" ];
        after = [ "graphical.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.swayosd}/bin/swayosd-libinput-backend";
          Restart = "on-failure";
        };
      };

      services = {
        # D-Bus policy that lets the backend own org.erikreider.swayosd
        dbus.packages = [ pkgs.swayosd ];
        libinput.enable = true;
        udisks2.enable = true;
      };
    };
}
