{
  description = "NixOS Flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";

    # Pin to older commit to avoid crash
    hyprland.url = "github:hyprwm/Hyprland/6dc42e0f6d777109b6c8203dccf5c5d421b1fa04";

    split-monitor-workspaces = {
      url = "github:zjeffer/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
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
    };

    nix-search-tv = {
      url = "github:3timeslazy/nix-search-tv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cclip = {
      url = "github:heather7283/cclip";
      flake = false;
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
