{ metaOwner, ... }:

{
  # Proton Mail through Bridge: mbsync <-> ~/mail, mu for mu4e, msmtp for sending.
  # The Gmail aliases are external (receive-only) addresses in Proton.
  flake.homeManagerModules.protonmail =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.custom.protonmail;
      maildir = "${config.home.homeDirectory}/mail";
      bridgeCert = "${config.xdg.configHome}/protonmail/bridge-v3/cert.pem";
      systemctl = "${pkgs.systemd}/bin/systemctl";

      # gnome-keyring is locked until the first hyprlock unlock; Bridge resets
      # its vault after repeated keychain failures, so wait instead of failing.
      wait-for-keyring = pkgs.writeShellScript "wait-for-keyring" ''
        until ${pkgs.systemd}/bin/busctl --user get-property org.freedesktop.secrets \
          /org/freedesktop/secrets/aliases/default org.freedesktop.Secret.Collection Locked \
          2>/dev/null | grep -q '^b false$'; do
          sleep 5
        done
      '';

      # mu4e holds the mu database while running, so let it re-index instead (+mu4e.el)
      mail-index = pkgs.writeShellScript "mail-index" ''
        running=$(${config.programs.emacs.finalPackage}/bin/emacsclient -e \
          "(and (fboundp '+mail-index) (+mail-index))" 2>/dev/null)
        [ "$running" = t ] || ${config.programs.mu.package}/bin/mu index --quiet || true
      '';
    in
    {
      options.custom.protonmail.enable = lib.mkEnableOption "Proton Mail with mu4e";

      config = lib.mkIf cfg.enable {
        services.protonmail-bridge.enable = true;
        systemd.user.services.protonmail-bridge.Service = {
          ExecStartPre = "${wait-for-keyring}";
          TimeoutStartSec = "infinity";
        };

        programs.mbsync.enable = true;
        programs.msmtp.enable = true;
        programs.mu.enable = true;
        programs.emacs.extraPackages = epkgs: [ epkgs.mu4e ];

        accounts.email = {
          maildirBasePath = maildir;
          accounts.proton = {
            primary = true;
            realName = metaOwner.fullName;
            address = metaOwner.email;
            aliases = [
              "me@nicolaj.dev"
              "nico188f@gmail.com"
              "nico188f2@gmail.com"
            ];
            userName = metaOwner.email;
            passwordCommand = "${pkgs.coreutils}/bin/cat /run/secrets/protonmail-bridge";
            maildir.path = "";

            imap = {
              host = "127.0.0.1";
              port = 1143;
              tls = {
                useStartTls = true;
                certificatesFile = bridgeCert;
              };
            };
            smtp = {
              host = "127.0.0.1";
              port = 1025;
              tls = {
                useStartTls = true;
                certificatesFile = bridgeCert;
              };
            };

            folders = {
              inbox = "INBOX";
              sent = "Sent";
              drafts = "Drafts";
              trash = "Trash";
            };

            mbsync = {
              enable = true;
              create = "both";
              remove = "none";
              expunge = "both";
              patterns = [
                "*"
                "!All Mail"
                "!Starred"
              ];
              extraConfig.local = {
                Path = "${maildir}/";
                Inbox = "${maildir}/INBOX";
              };
              extraConfig.channel.CopyArrivalDate = "yes";
            };

            msmtp.enable = true;
            mu.enable = true;

            imapnotify = {
              enable = true;
              boxes = [ "INBOX" ];
              onNotify = "${systemctl} --user start mbsync.service";
              # goimapnotify can't take a CA file; Bridge only listens on localhost
              extraConfig.tlsOptions = {
                starttls = true;
                rejectUnauthorized = false;
              };
            };
          };
        };

        services.mbsync = {
          enable = true;
          frequency = "*:0/5";
          postExec = "${mail-index}";
        };
        systemd.user.services.mbsync.Unit.After = [ "protonmail-bridge.service" ];

        services.imapnotify = {
          enable = true;
          path = [ pkgs.bash ];
        };

        custom.niri.binds."Mod+M" = [
          "emacsclient"
          "-c"
          "-e"
          "(=mu4e)"
        ];
      };
    };
}
