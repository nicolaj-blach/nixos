{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.boot.loader.limine;

  # Patched Limine install script with custom entry naming: "{gen} - {label}"
  patchedLimineInstall = pkgs.runCommand "limine-install-patched" { } ''
    cp ${pkgs.path}/nixos/modules/system/boot/loader/limine/limine-install.py $out
    chmod +w $out

    # Change submenu "Generation {gen}" to "{gen} - {label}" format
    substituteInPlace $out \
      --replace-fail \
        "entry += f'Generation {gen}' + '\\n'" \
        "entry += f'{gen} - {boot_spec.label.replace(\"_\", \" \")}' + '\\n'"

    # Change non-specialisation entry to same format
    substituteInPlace $out \
      --replace-fail \
        "entry += config_entry(depth, boot_spec, f'Generation {gen}', str(time))" \
        "entry += config_entry(depth, boot_spec, f'{gen} - {boot_spec.label.replace(\"_\", \" \")}', str(time))"
  '';

  limineInstallConfig = pkgs.writeText "limine-install.json" (
    builtins.toJSON {
      nixPath = config.nix.package;
      efiBootMgrPath = pkgs.efibootmgr;
      liminePath = cfg.package;
      efiMountPoint = config.boot.loader.efi.efiSysMountPoint;
      inherit (config) fileSystems;
      luksDevices = builtins.attrNames config.boot.initrd.luks.devices;
      inherit (config.boot.loader.efi) canTouchEfiVariables;
      inherit (cfg) efiSupport;
      efiRemovable = cfg.efiInstallAsRemovable;
      inherit (cfg) secureBoot;
      inherit (cfg) biosSupport;
      inherit (cfg) biosDevice;
      inherit (cfg) partitionIndex;
      inherit (cfg) force;
      inherit (cfg) enrollConfig;
      inherit (cfg) style;
      maxGenerations = if cfg.maxGenerations == null then 0 else cfg.maxGenerations;
      hostArchitecture = pkgs.stdenv.hostPlatform.parsed.cpu;
      timeout = if config.boot.loader.timeout != null then config.boot.loader.timeout else 10;
      inherit (cfg) enableEditor;
      inherit (cfg) extraConfig;
      inherit (cfg) extraEntries;
      inherit (cfg) additionalFiles;
      inherit (cfg) validateChecksums;
      inherit (cfg) panicOnChecksumMismatch;
    }
  );
in
{
  nixpkgs.config.allowUnfree = true;
  boot = {

    # systemd-based initrd (required for TPM2 auto-unlock)
    initrd.systemd.enable = true;

    loader.efi.canTouchEfiVariables = true;

    loader.limine = {
      enable = true;
      maxGenerations = 10;
      enableEditor = false;

      # Secure Boot (run sbctl create-keys + sbctl enroll-keys first)
      secureBoot.enable = true;

      style = {
        wallpapers = [ ];
        wallpaperStyle = "stretched";
        backdrop = "282c34";

        interface = {
          branding = "N-B";
          brandingColor = 6;
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

  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };

  # TPM2 support (for LUKS auto-unlock after enrollment)
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  users.users.${username}.extraGroups = [ "tss" ];

  time.timeZone = "Europe/Copenhagen";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  fonts.packages =
    with lib;
    with pkgs;
    [
      nerd-fonts.jetbrains-mono
    ];

  system.stateVersion = "25.11";

  # Override Limine install script with custom entry naming
  system.build.installBootLoader = lib.mkForce (
    pkgs.replaceVarsWith {
      src = patchedLimineInstall;
      isExecutable = true;
      replacements = {
        python3 = pkgs.python3.withPackages (ps: [ ps.psutil ]);
        configPath = limineInstallConfig;
      };
    }
  );
}
