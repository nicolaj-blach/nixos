{ inputs, ... }:

{
  flake.nixosModules.nix-settings = { ... }: {
    nix = {
      registry.nixpkgs.flake = inputs.nixpkgs;
      nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        warn-dirty = false;
        trusted-users = [
          "root"
          "@wheel"
        ];
        substituters = [
          "https://cache.nixos.org"
          "https://hyprland.cachix.org"
          "https://nix-community.cachix.org"
          "https://cache.numtide.com"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
      };

      # gc disabled - using programs.nh.clean instead
      # gc = {
      #   automatic = true;
      #   dates = "weekly";
      #   options = "--delete-older-than 7d";
      # };

      optimise = {
        automatic = true;
        dates = [ "weekly" ];
      };
    };

    nixpkgs.config.allowUnfree = true;
  };
}
