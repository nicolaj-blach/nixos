{ inputs, ... }:

{
  # Wifi TUI; also opened from the bar
  flake.homeManagerModules.wlctl =
    { pkgs, ... }:
    {
      home.packages = [ inputs.wlctl.packages.${pkgs.stdenv.hostPlatform.system}.default ];

      custom.niri.binds."Mod+Shift+W" = [
        "kitty-popup-large"
        "-e"
        "wlctl"
      ];
    };
}
