{
  pkgs,
  inputs,
  username,
  config,
  ...
}:

let
  cclip = pkgs.stdenv.mkDerivation {
    pname = "cclip";
    version = "3.3.1";

    src = inputs.cclip;

    nativeBuildInputs = with pkgs; [
      meson
      ninja
      pkg-config
      wayland-scanner
      scdoc
      git
    ];

    buildInputs = with pkgs; [
      wayland
      sqlite
      xxHash
    ];

    mesonFlags = [ "-Dman=true" ];

    meta = {
      description = "Clipboard manager for Wayland";
      homepage = "https://github.com/heather7283/cclip";
      license = pkgs.lib.licenses.gpl3Plus;
      platforms = pkgs.lib.platforms.linux;
    };
  };
in

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

  # cclipd clipboard history daemon (for fsel --cclip)
  # Started via Hyprland exec-once since graphical-session.target isn't reliably activated
  systemd.user.services.cclipd = {
    description = "cclip clipboard manager daemon";
    serviceConfig = {
      ExecStart = "${cclip}/bin/cclipd -s 2 -t 'image/png' -t 'image/*' -t 'text/plain;charset=utf-8' -t 'text/*' -t '*'";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
