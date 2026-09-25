{
  description = "NixOS configuration";

  inputs = {
    self.submodules = true;

    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
    astal = {
      url = "github:Aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ags = {
      url = "github:Aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal";
    };

    ags-bar = {
      url = "github:nicolaj-blach/ags-bar";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal";
      inputs.ags.follows = "ags";
    };

    agent-markdown-files = {
      url = "github:nicolaj-blach/agent-markdown-files";
      flake = false;
    };

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

      systems = [ "x86_64-linux" ];

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
