{ inputs, ... }:

{
  # `tv nix`: fuzzy nixpkgs search (Mod+Shift+N and otter `pkg`)
  flake.homeManagerModules.television =
    { pkgs, ... }:
    {
      home.packages = [ inputs.nix-search-tv.packages.${pkgs.stdenv.hostPlatform.system}.default ];

      programs.television = {
        enable = true;
        channels.nix = {
          metadata = {
            name = "nix";
            requirements = [ "nix-search-tv" ];
          };
          source.command = "nix-search-tv print";
          preview.command = "nix-search-tv preview {}";
        };
      };

      custom.niri.binds."Mod+Shift+N" = [
        "kitty-popup-large"
        "-e"
        "tv"
        "nix"
      ];
    };
}
