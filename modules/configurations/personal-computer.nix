{
  self,
  inputs,
  metaOwner,
  ...
}:

{
  flake.nixosModules.personal-computer = { lib, ... }: {
    imports = [
      # Core system modules
      self.nixosModules.boot
      self.nixosModules.user
      self.nixosModules.nix-settings
      self.nixosModules.locale
      self.nixosModules.networking

      # Desktop environment
      self.nixosModules.hyprland
      self.nixosModules.ags
      self.nixosModules.flameshot
      self.nixosModules.theming

      # Hardware
      self.nixosModules.pipewire
      self.nixosModules.bluetooth
      self.nixosModules.gaming

      # Services
      self.nixosModules.services
      self.nixosModules.syncthing

      # Input
      self.nixosModules.kanata

      # Shell
      self.nixosModules.zsh

      # Packages
      self.nixosModules.packages
    ];

    services.openssh.enable = true;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs metaOwner; };

      users.${metaOwner.username} = { ... }: {
        imports = [
          # Desktop environment
          self.homeManagerModules.hyprland
          self.homeManagerModules.hyprland-window-rules
          self.homeManagerModules.ags

          # Apps
          self.homeManagerModules.zen-browser
          self.homeManagerModules.otter-launcher
          self.homeManagerModules.emacs
          self.homeManagerModules.pi-coding-agent
          self.homeManagerModules.git
          self.homeManagerModules.devenv

          # System integration
          self.homeManagerModules.flameshot
          self.homeManagerModules.kanata
        ];

        # Enable Hyprland (Home Manager config)
        wayland.windowManager.hyprland.enable = true;

        # Enable apps
        programs.zen-browser.enable = true;
        # programs.otter-launcher.enable = true;  # FIXME: Disabled - crates.io network issues
        custom.emacs.enable = true;
        programs.pi-coding-agent.enable = true;
        programs.git.enable = true;
        programs.devenv.enable = true;

        # Enable services
        custom.flameshot.enable = true;
        services.ags-bar.enable = true;

        home.stateVersion = "25.11";
      };
    };

    system.stateVersion = "25.11";
  };
}
