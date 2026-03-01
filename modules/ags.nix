{ pkgs, inputs, ... }:

let
  astal = inputs.astal;
  agsPackage = inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.default;

  myBar = pkgs.stdenv.mkDerivation {
    pname = "my-bar";
    version = "0.1.0";

    src = ../dotfiles/.config/ags;

    nativeBuildInputs = with pkgs; [
      wrapGAppsHook3
      gobject-introspection
      agsPackage
    ];

    buildInputs = with pkgs; [
      glib
      gjs
      astal.packages.${pkgs.stdenv.hostPlatform.system}.io
      astal.packages.${pkgs.stdenv.hostPlatform.system}.astal4
      astal.packages.${pkgs.stdenv.hostPlatform.system}.battery
      astal.packages.${pkgs.stdenv.hostPlatform.system}.wireplumber
      astal.packages.${pkgs.stdenv.hostPlatform.system}.network
      astal.packages.${pkgs.stdenv.hostPlatform.system}.hyprland
    ];

    installPhase = ''
      mkdir -p $out/bin
      ags bundle app.tsx $out/bin/my-bar
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
  environment.systemPackages = [ myBar ];
}
