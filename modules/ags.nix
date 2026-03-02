{ pkgs, inputs, ... }:

let
  astal = inputs.astal;
  system = pkgs.stdenv.hostPlatform.system;
  agsPackage = inputs.ags.packages.${system}.default;

  astalLibs = with astal.packages.${system}; [
    io
    astal4
    battery
    wireplumber
    network
    hyprland
  ];

  topBar = pkgs.stdenv.mkDerivation {
    pname = "top-bar";
    version = "0.1.0";

    src = ../dotfiles/.config/ags;

    nativeBuildInputs = with pkgs; [
      wrapGAppsHook3
      gobject-introspection
      agsPackage
    ];

    buildInputs = [ pkgs.glib pkgs.gjs ] ++ astalLibs;

    installPhase = ''
      mkdir -p $out/bin
      ags bundle app.tsx $out/bin/top-bar --gtk 4
    '';

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix PATH : ${pkgs.lib.makeBinPath [
          pkgs.hyprland
        ]}
      )
    '';
  };
in
{
  services.upower.enable = true;
  environment.systemPackages = [
    topBar
    agsPackage
  ] ++ astalLibs;
}
