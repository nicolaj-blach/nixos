{ inputs, ... }:

{
  # Clipboard history daemon; fsel --cclip (Mod+Shift+V) reads it
  flake.homeManagerModules.cclip =
    { pkgs, ... }:
    let
      cclip = pkgs.stdenv.mkDerivation {
        pname = "cclip";
        version = "unstable";
        src = inputs.cclip;

        nativeBuildInputs = with pkgs; [
          meson
          ninja
          pkg-config
          wayland-scanner
          scdoc
          git
        ];

        buildInputs = with pkgs; [
          wayland
          sqlite
          xxHash
        ];

        mesonFlags = [ "-Dman=true" ];

        meta = {
          description = "Clipboard manager for Wayland";
          homepage = "https://github.com/heather7283/cclip";
          license = pkgs.lib.licenses.gpl3Plus;
          platforms = pkgs.lib.platforms.linux;
        };
      };
    in
    {
      home.packages = [ cclip ];

      custom.niri.startup = [
        [
          "cclipd"
          "-s"
          "2"
          "-t"
          "image/png"
          "-t"
          "image/*"
          "-t"
          "text/plain;charset=utf-8"
          "-t"
          "text/*"
        ]
      ];
    };
}
