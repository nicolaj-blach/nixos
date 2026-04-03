{
  pkgs,
  inputs,
  username,
  ...
}:

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

    syncthing = {
      enable = true;
      user = username;
      dataDir = "/home/${username}";
      configDir = "/home/${username}/.config/syncthing";
      openDefaultPorts = true;
      settings.folders."silverbullet-space".path = "/home/${username}/notes";
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # cliphist clipboard history daemon (for clipboard picker)
  systemd.user.services.cliphist = {
    description = "cliphist clipboard history";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
