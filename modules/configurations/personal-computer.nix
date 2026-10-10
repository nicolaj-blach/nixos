{
  self,
  inputs,
  metaOwner,
  ...
}:

{
  flake.nixosModules.personal-computer = { unstablePkgs, ... }: {
    imports = [
      # External modules
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-index-database.nixosModules.nix-index

      # Core system modules
      self.nixosModules.boot
      self.nixosModules.plymouth
      self.nixosModules.user
      self.nixosModules.nix-settings
      self.nixosModules.locale
      self.nixosModules.networking

      # Desktop environment
      self.nixosModules.niri
      self.nixosModules.hyprlock
      self.nixosModules.quickshell-bar
      self.nixosModules.greetd
      self.nixosModules.theming

      # Hardware
      self.nixosModules.pipewire
      self.nixosModules.bluetooth

      # Services
      self.nixosModules.services

      # Apps
      self.nixosModules.steam
      self.nixosModules.bit

      # Input
      self.nixosModules.kanata

      # Shell
      self.nixosModules.zsh

      # Packages
      self.nixosModules.packages
    ];

    services.openssh.enable = true;

    # Enable comma with prebuilt nix-index database
    programs.nix-index-database.comma.enable = true;
    programs.nix-index.enable = true;
    programs.nix-index.enableZshIntegration = true;
    programs.command-not-found.enable = false;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs metaOwner; };
      sharedModules = [ { _module.args = { inherit unstablePkgs; }; } ];

      users.${metaOwner.username} = { ... }: {
        imports = [
          # Desktop environment
          self.homeManagerModules.niri
          self.homeManagerModules.hyprlock
          self.homeManagerModules.mako

          self.homeManagerModules.quickshell-bar
          self.homeManagerModules.xdg-dirs
          self.homeManagerModules.desktop-services

          # Apps
          self.homeManagerModules.pi-coding-agent
          self.homeManagerModules.zen-browser
          self.homeManagerModules.chromium
          self.homeManagerModules.google-chrome
          self.homeManagerModules.git
          self.homeManagerModules.devenv
          self.homeManagerModules.emacs
          self.homeManagerModules.superfile
          self.homeManagerModules.yazi
          self.homeManagerModules.prismlauncher
          self.homeManagerModules.otter-launcher
          self.homeManagerModules.fsel
          self.homeManagerModules.cclip
          self.homeManagerModules.qalculate
          self.homeManagerModules.system-info
          self.homeManagerModules.television
          self.homeManagerModules.wlctl
          self.homeManagerModules.bluetui
          self.homeManagerModules.wiremix
          self.homeManagerModules.vesktop
          self.homeManagerModules.kitty
          self.homeManagerModules.ghostty

          # Shell
          self.homeManagerModules.zsh
          self.homeManagerModules.starship
          self.homeManagerModules.atuin

          # System integration
          self.homeManagerModules.kanata
        ];

        custom.niri.enable = true;
        custom.hyprlock.enable = true;
        custom.mako.enable = true;
        services.quickshell-bar = {
          enable = true;
          systemMenuCommand = [
            "kitty-popup"
            "-e"
            "fsel-system"
          ];
          wifiCommand = [
            "kitty-popup-large"
            "-e"
            "wlctl"
          ];
          bluetoothCommand = [
            "kitty-popup-large"
            "-e"
            "bluetui"
          ];
          audioCommand = [
            "kitty-popup-large"
            "-e"
            "wiremix"
          ];
        };

        # Enable apps
        programs.zen-browser.enable = true;
        custom.emacs.enable = true;
        programs.kitty.enable = true;
        programs.pi-coding-agent.enable = true;
        programs.git.enable = true;
        programs.devenv.enable = true;
        programs.otter-launcher.enable = true;
        programs.fsel.enable = true;
        programs.zsh.enable = true;
        programs.qalculate.enable = true;

        xdg.mimeApps.enable = true;

        home.stateVersion = "25.11";
      };
    };

    system.stateVersion = "25.11";
  };
}
