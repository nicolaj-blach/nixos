{ ... }:

{
  # Audio mixer TUI; also opened from the bar
  flake.homeManagerModules.wiremix =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.wiremix ];

      custom.niri.binds."Mod+Shift+S" = [
        "kitty-popup-large"
        "-e"
        "wiremix"
      ];
    };
}
