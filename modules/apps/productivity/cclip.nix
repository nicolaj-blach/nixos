{ inputs, ... }:

let
  cclipPackage =
    pkgs:
    pkgs.stdenv.mkDerivation {
      pname = "cclip";
      version = "unstable";
      src = inputs.cclip;

      nativeBuildInputs = with pkgs; [
        meson
        ninja
        pkg-config
        wayland-scanner
        git
      ];

      buildInputs = with pkgs; [
        wayland
        sqlite
        xxHash
      ];

      meta = {
        description = "Clipboard manager for Wayland";
        homepage = "https://github.com/heather7283/cclip";
        license = pkgs.lib.licenses.gpl3Plus;
        platforms = pkgs.lib.platforms.linux;
      };
    };
in
{
  flake.nixosModules.cclip =
    { pkgs, ... }:
    {
      environment.systemPackages = [ (cclipPackage pkgs) ];
    };
}
