{
  description = "NixOS configuration";

  inputs = {
    self.submodules = true;

    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    # Unreleased niri for multi-monitor portal screenshots (flameshot); see AGENTS.md
    niri-src = {
      url = "github:niri-wm/niri";
      flake = false;
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi-config.url = "github:nicolaj-blach/pi-config";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    doom-emacs = {
      url = "github:doomemacs/doomemacs";
      flake = false;
    };
    ghostel = {
      url = "github:dakra/ghostel";
      flake = false;
    };
    otter-launcher.url = "github:kuokuo123/otter-launcher";

    cclip = {
      url = "github:heather7283/cclip";
      flake = false;
    };
    nix-search-tv.url = "github:3timeslazy/nix-search-tv";

    wlctl = {
      url = "github:aashish-thapa/wlctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell-bar = {
      url = "github:nicolaj-blach/quickshell-bar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      secretsRoot = ./secrets;
      hasSecrets = builtins.pathExists (secretsRoot + "/github.yaml");
      metaOwner = {
        username = "nicolaj-blach";
        fullName = "Nicolaj Blach Jensen";
        email = "me@nicolaj-blach.dev";
      };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ (inputs.import-tree ./modules) ];

      _module.args = {
        inherit
          inputs
          secretsRoot
          hasSecrets
          metaOwner
          ;
      };

      perSystem = { pkgs, ... }: {
        packages = { };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nil
            nixfmt-rfc-style
            statix
            age
            sops
          ];
        };
      };
    };
}
