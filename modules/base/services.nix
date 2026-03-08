{ pkgs, username, ... }:

{
  # Autologin on tty1
  systemd.services."getty@tty1".overrideStrategy = "asDropin";
  systemd.services."getty@tty1".serviceConfig.ExecStart = [
    ""
    "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${pkgs.shadow}/bin/login --autologin ${username} --noclear %I $TERM"
  ];

  services = {
    pipewire = {
      enable = true;
      pulse.enable = true;
    };

    libinput.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
