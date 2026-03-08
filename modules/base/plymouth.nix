{
  pkgs,
  ...
}:

let
  # Base16 OneDark colors
  base00 = "282c34";
  base05 = "abb2bf";
  base03 = "5c6370";

  # Scale down logo to 25%
  scaledLogo =
    pkgs.runCommand "nb-logo-scaled"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        magick ${../../assets/logo.png} -resize 25% $out
      '';

  # Plymouth theme package
  plymouthTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "nb-plymouth-theme";
    version = "1.0";

    dontUnpack = true;

    # Copy spinner frames from nixos-bgrt theme
    bgrtTheme = pkgs.nixos-bgrt-plymouth;

    installPhase = ''
      mkdir -p $out/share/plymouth/themes/nb/images
      cd $out/share/plymouth/themes/nb

      # Copy scaled logo
      cp ${scaledLogo} images/watermark.png

      # Copy UI assets from nixos-bgrt (no spinner)
      cp $bgrtTheme/share/plymouth/themes/nixos-bgrt/images/bullet.png images/
      cp $bgrtTheme/share/plymouth/themes/nixos-bgrt/images/entry.png images/
      cp $bgrtTheme/share/plymouth/themes/nixos-bgrt/images/lock.png images/
      cp $bgrtTheme/share/plymouth/themes/nixos-bgrt/images/capslock.png images/
      cp $bgrtTheme/share/plymouth/themes/nixos-bgrt/images/keyboard.png images/

      # Create theme descriptor
      cat > nb.plymouth << EOF
      [Plymouth Theme]
      Name=N-B
      Description=Minimal boot theme with N-B logo
      ModuleName=two-step

      [two-step]
      Font=JetBrainsMono Nerd Font 12
      TitleFont=JetBrainsMono Nerd Font 16
      ImageDir=$out/share/plymouth/themes/nb/images
      DialogHorizontalAlignment=.5
      DialogVerticalAlignment=.85
      TitleHorizontalAlignment=.5
      TitleVerticalAlignment=.382
      HorizontalAlignment=.5
      VerticalAlignment=.7
      WatermarkHorizontalAlignment=.5
      WatermarkVerticalAlignment=.38
      Transition=none
      TransitionDuration=0.0
      BackgroundStartColor=0x${base00}
      BackgroundEndColor=0x${base00}
      ProgressBarBackgroundColor=0x${base03}
      ProgressBarForegroundColor=0x${base05}
      MessageBelowAnimation=true

      [boot-up]
      UseEndAnimation=false
      UseFirmwareBackground=false

      [shutdown]
      UseEndAnimation=false
      UseFirmwareBackground=false

      [reboot]
      UseEndAnimation=false
      UseFirmwareBackground=false
      EOF
    '';
  };
in
{
  boot.plymouth = {
    enable = true;
    theme = "nb";
    themePackages = [ plymouthTheme ];
  };

  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "rd.udev.log_level=3"
    "systemd.show_status=auto"
  ];

  boot.consoleLogLevel = 0;
}
