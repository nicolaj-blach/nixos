{ metaOwner, ... }:

{
  flake.nixosModules.greetd =
    { pkgs, lib, ... }:
    let
      tuigreet = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";

      # Config for the extra greeters on tty2-6 (VT number is passed with --vt)
      ttyGreeterConfig = (pkgs.formats.toml { }).generate "greetd-tty.toml" {
        terminal = {
          vt = 2;
          switch = false;
        };
        general.runfile = "/run/greetd-tty.run";
        default_session = {
          command = tuigreet;
          user = "greeter";
        };
      };

      greetd-tty = pkgs.writeShellScript "greetd-tty" ''
        exec ${pkgs.greetd}/bin/greetd --config ${ttyGreeterConfig} --vt "''${1#tty}"
      '';
    in
    {
      # tty1: always auto-login into niri, which locks immediately with hyprlock
      services.greetd = {
        enable = true;
        settings.default_session = {
          command = "niri-session";
          user = metaOwner.username;
        };
      };

      # tty2-6: logind spawns autovt@ttyN on switch; run greetd + tuigreet instead of agetty
      systemd.services."autovt@".serviceConfig.ExecStart = lib.mkForce [
        ""
        "${greetd-tty} %I"
      ];
    };
}
