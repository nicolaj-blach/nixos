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
      self.nixosModules.niri
      self.nixosModules.quickshell-bar
      self.nixosModules.greetd
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
          self.homeManagerModules.niri

          # Apps
          self.homeManagerModules.zen-browser
          self.homeManagerModules.emacs
          self.homeManagerModules.kitty
          self.homeManagerModules.pi-coding-agent
          self.homeManagerModules.git
          self.homeManagerModules.devenv

          # System integration
          self.homeManagerModules.kanata
        ];

        # Enable niri (Home Manager config)
        custom.niri.enable = true;

        # Enable apps
        programs.zen-browser.enable = true;
        custom.emacs.enable = true;
        programs.kitty.enable = true;
        programs.pi-coding-agent.enable = true;
        programs.git.enable = true;
        programs.devenv.enable = true;

        home.stateVersion = "25.11";
      };
    };

    system.stateVersion = "25.11";
  };
}
