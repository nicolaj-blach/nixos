{ ... }:

{
  # Bluetooth TUI; also opened from the bar
  flake.homeManagerModules.bluetui =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.bluetui ];

      custom.niri.binds."Mod+Shift+B" = [
        "kitty-popup-large"
        "-e"
        "bluetui"
      ];
    };
}
