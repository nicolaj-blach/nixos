{
  description = "NixOS Flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";

    hyprland.url = "github:hyprwm/Hyprland";

    split-monitor-workspaces = {
      url = "github:zjeffer/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };

    elephant.url = "github:abenz1267/elephant";

    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal";
    };

    wlctl = {
      url = "github:aashish-thapa/wlctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fsel = {
      url = "github:Mjoyufull/fsel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-search-tv = {
      url = "github:3timeslazy/nix-search-tv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      # Must use absolute path since file is gitignored (not part of flake)
      # Requires --impure flag when building
      labelFile = /. + builtins.getEnv "HOME" + "/nixos/nixos-label.nix";
      label = if builtins.pathExists labelFile then import labelFile else "no_message";
    in
    {
      nixosConfigurations.personal-laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit inputs;
          username = "nicolaj-blach";
          configModules = {
            base = ./modules/base;
            desktop = ./modules/desktop;
            programs = ./modules/programs;
            fingerPrint = ./modules/fingerPrint;
          };
        };

        modules = [
          ./hosts/personal-laptop
          {
            system.configurationRevision = self.rev or self.dirtyRev or "unknown";
            system.nixos.label = label;
          }
        ];
      };

      nixosConfigurations.personal-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit inputs;
          username = "nicolaj-blach";
          configModules = {
            base = ./modules/base;
            desktop = ./modules/desktop;
            programs = ./modules/programs;
          };
        };

        modules = [
          ./hosts/personal-desktop
          {
            system.configurationRevision = self.rev or self.dirtyRev or "unknown";
            system.nixos.label = label;
          }
        ];
      };
    };
}
