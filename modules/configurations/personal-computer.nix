{
  self,
  inputs,
  metaOwner,
  ...
}:

{
  flake.nixosModules.personal-computer = { lib, ... }: {
    imports = [
      # External modules
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-index-database.nixosModules.nix-index

      # Core system modules
      self.nixosModules.cclip
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
      self.nixosModules.gaming

      # Services
      self.nixosModules.services

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

      users.${metaOwner.username} = { ... }: {
        imports = [
          # Desktop environment
          self.homeManagerModules.niri
          self.homeManagerModules.hyprlock
          self.homeManagerModules.mako

          # Apps
          self.homeManagerModules.zen-browser
          self.homeManagerModules.emacs
          self.homeManagerModules.kitty
          self.homeManagerModules.pi-coding-agent
          self.homeManagerModules.git
          self.homeManagerModules.devenv
          self.homeManagerModules.otter-launcher
          self.homeManagerModules.fsel
          self.homeManagerModules.quickshell-bar

          # Shell
          self.homeManagerModules.zsh

          # System integration
          self.homeManagerModules.kanata
        ];

        # Enable niri (Home Manager config)
        custom.niri.enable = true;
        custom.hyprlock.enable = true;
        custom.mako.enable = true;
        services.quickshell-bar = {
          enable = true;
          autostart = false;
          systemMenuCommand = [
            "kitty-popup"
            "-e"
            "fsel-system"
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

        home.stateVersion = "25.11";
      };
    };

    system.stateVersion = "25.11";
  };
}
