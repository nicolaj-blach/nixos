{ pkgs, username, ... }:

{
  # Autologin on tty1
  systemd.services."getty@tty1".overrideStrategy = "asDropin";
  systemd.services."getty@tty1".serviceConfig.ExecStart = [
    ""
    "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${pkgs.shadow}/bin/login --autologin ${username} --noclear %I $TERM"
  ];

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
    pipewire = {
      enable = true;
      pulse.enable = true;
    };

    libinput.enable = true;
    udisks2.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
