{ ... }:

{
  flake.nixosModules.boot =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.boot.loader.limine;

      # Limine centres both the wallpaper and the menu, so the logo sits at the top
      # of a tall canvas to end up above the generation list
      bootLogo =
        pkgs.runCommand "limine-logo.png"
          {
            nativeBuildInputs = [
              pkgs.librsvg
              pkgs.imagemagick
            ];
          }
          ''
            rsvg-convert -h 140 ${../../../assets/logo.svg} -o logo.png
            magick -size 240x800 xc:'#282c34' logo.png -gravity north -geometry +0+40 -composite $out
          '';

      # Entry names "{gen} - {label}" instead of "Generation {gen}"
      patchedLimineInstall = pkgs.runCommand "limine-install-patched" { } ''
        cp ${pkgs.path}/nixos/modules/system/boot/loader/limine/limine-install.py $out
        chmod +w $out
        substituteInPlace $out \
          --replace-fail \
            "entry += f'Generation {gen}' + '\\n'" \
            "entry += f'{gen} - {boot_spec.label.replace(\"_\", \" \")}' + '\\n'"
        substituteInPlace $out \
          --replace-fail \
            "entry += config_entry(depth, boot_spec, f'Generation {gen}', str(time))" \
            "entry += config_entry(depth, boot_spec, f'{gen} - {boot_spec.label.replace(\"_\", \" \")}', str(time))"
      '';

      limineInstallConfig = pkgs.writeText "limine-install.json" (
        builtins.toJSON {
          inherit (config.system.nixos) distroName;
          nixPath = config.nix.package;
          efiBootMgrPath = pkgs.efibootmgr;
          liminePath = cfg.package;
          efiMountPoint = config.boot.loader.efi.efiSysMountPoint;
          inherit (config) fileSystems;
          luksDevices = builtins.attrNames config.boot.initrd.luks.devices;
          inherit (config.boot.loader.efi) canTouchEfiVariables;
          inherit (cfg)
            efiSupport
            secureBoot
            biosSupport
            biosDevice
            partitionIndex
            force
            enrollConfig
            style
            resolution
            enableEditor
            extraConfig
            extraEntries
            additionalFiles
            validateChecksums
            panicOnChecksumMismatch
            ;
          efiRemovable = cfg.efiInstallAsRemovable;
          maxGenerations = if cfg.maxGenerations == null then 0 else cfg.maxGenerations;
          hostArchitecture = pkgs.stdenv.hostPlatform.parsed.cpu;
          timeout = if config.boot.loader.timeout == null then "no" else config.boot.loader.timeout;
        }
      );
    in
    {
      boot.loader = {
        systemd-boot.enable = lib.mkDefault false;
        efi.canTouchEfiVariables = true;
        timeout = 3;

        limine = {
          enable = lib.mkDefault true;
          maxGenerations = 10;
          enableEditor = false;

          style = {
            wallpapers = [ bootLogo ];
            wallpaperStyle = "centered";
            backdrop = "282c34";

            interface = {
              branding = "N-B";
              brandingColor = "56b6c2";
              helpHidden = false;
            };

            graphicalTerminal = {
              foreground = "abb2bf";
              background = "ee282c34";
              brightForeground = "c8ccd4";
              brightBackground = "ee353b45";
              margin = 8;
              marginGradient = 0;
              # black;red;green;brown;blue;magenta;cyan;gray
              palette = "282c34;e06c75;98c379;e5c07b;61afef;c678dd;56b6c2;abb2bf";
              brightPalette = "545862;e06c75;98c379;e5c07b;61afef;c678dd;56b6c2;c8ccd4";
              font.scale = "2x2";
            };
          };
        };
      };

      system.build.installBootLoader = lib.mkIf cfg.enable (
        lib.mkForce (
          pkgs.replaceVarsWith {
            src = patchedLimineInstall;
            isExecutable = true;
            replacements = {
              python3 = pkgs.python3.withPackages (ps: [ ps.psutil ]);
              configPath = limineInstallConfig;
            };
          }
        )
      );

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
