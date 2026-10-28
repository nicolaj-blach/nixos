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

      lookup-password = "${pkgs.libsecret}/bin/secret-tool lookup service protonmail-bridge";

      # Bridge makes a password per machine; copy it from `--cli` `info` into the
      # keyring if missing. Runs before Bridge starts, as the CLI needs its lock.
      store-bridge-password = pkgs.writeShellScript "store-bridge-password" ''
        ${lookup-password} >/dev/null 2>&1 && exit 0
        # input sent before the shell is ready is dropped, so keep asking
        password=$( (for _ in $(seq 20); do sleep 3; echo info; done) \
          | timeout 60 ${config.services.protonmail-bridge.package}/bin/protonmail-bridge --cli 2>/dev/null \
          | ${pkgs.gawk}/bin/awk '/^Password:/ { print $2; exit }') || true
        if [ -z "$password" ]; then
          echo "No Bridge password found; log in with protonmail-bridge --cli" >&2
          exit 0
        fi
        printf %s "$password" | ${pkgs.libsecret}/bin/secret-tool store \
          --label="Proton Bridge" service protonmail-bridge
      '';

      # Bridge already running without a stored password: restart it once per boot
      ensure-bridge-password = pkgs.writeShellScript "ensure-bridge-password" ''
        ${lookup-password} >/dev/null 2>&1 && exit 0
        flag="$XDG_RUNTIME_DIR/bridge-password-attempted"
        [ -e "$flag" ] && exit 0
        touch "$flag"
        ${systemctl} --user restart protonmail-bridge.service
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
          ExecStartPre = [
            "${wait-for-keyring}"
            "${store-bridge-password}"
          ];
          TimeoutStartSec = "infinity";
        };

        home.packages = [ pkgs.libsecret ];

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
            passwordCommand = lookup-password;
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
        systemd.user.services.mbsync = {
          Unit.After = [ "protonmail-bridge.service" ];
          Service.ExecStartPre = [ "${ensure-bridge-password}" ];
        };

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
