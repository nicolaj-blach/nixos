{
  pkgs,
  lib,
  ...
}:

let
  # Base16 OneDark colors
  base00 = "282c34"; # Background
  base05 = "abb2bf"; # Foreground
  base03 = "5c6370"; # Comments (muted)

  # Convert ANSI logo to PNG and scale 2x
  logoImage =
    pkgs.runCommand "nb-logo-png"
      {
        nativeBuildInputs = with pkgs; [
          ansilove
          imagemagick
        ];
      }
      ''
        ansilove -o raw.png ${../../assets/ansiLogo.txt}
        magick raw.png \
          -background '#${base00}' \
          -alpha remove \
          -alpha off \
          -filter point \
          -resize 200% \
          logo.png
        cp logo.png $out
      '';

  # Generate spinner frames (simple rotating dots)
  spinnerFrames =
    pkgs.runCommand "nb-spinner-frames"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        mkdir -p $out
        size=64
        dot_radius=4
        ring_radius=24
        frames=30

        for i in $(seq 0 $((frames - 1))); do
          angle=$(echo "scale=4; $i * 360 / $frames" | ${pkgs.bc}/bin/bc)

          # Create base transparent image and rotate in one command
          magick -size ''${size}x''${size} xc:none \
            -fill '#${base05}' \
            -draw "circle $((size/2)),$((size/2 - ring_radius)) $((size/2)),$((size/2 - ring_radius + dot_radius))" \
            -background none -rotate $angle \
            -gravity center -extent ''${size}x''${size} \
            $out/throbber-$(printf "%04d" $i).png
        done
      '';

  # Password entry field image
  entryImage =
    pkgs.runCommand "nb-entry-png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        magick -size 400x60 xc:'#${base00}' \
          -stroke '#${base03}' \
          -strokewidth 2 \
          -fill none \
          -draw "rectangle 1,1 398,58" \
          entry.png
        cp entry.png $out
      '';

  # Password bullet
  bulletImage =
    pkgs.runCommand "nb-bullet-png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        magick -size 16x16 xc:none \
          -fill '#${base05}' \
          -draw "circle 8,8 8,2" \
          bullet.png
        cp bullet.png $out
      '';

  # Lock icon
  lockImage =
    pkgs.runCommand "nb-lock-png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        magick -size 32x32 xc:none \
          -fill '#${base05}' \
          -draw "roundrectangle 4,14 28,30 2,2" \
          -fill none \
          -stroke '#${base05}' \
          -strokewidth 3 \
          -draw "arc 8,4 24,20 0,180" \
          lock.png
        cp lock.png $out
      '';

  # Plymouth theme package
  plymouthTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "nb-plymouth-theme";
    version = "1.0";

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/share/plymouth/themes/nb
      cd $out/share/plymouth/themes/nb

      # Copy images
      mkdir -p images
      cp ${logoImage} images/logo.png
      cp ${entryImage} images/entry.png
      cp ${bulletImage} images/bullet.png
      cp ${lockImage} images/lock.png

      # Copy spinner frames
      for frame in ${spinnerFrames}/throbber-*.png; do
        cp $frame images/
      done

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
      TitleVerticalAlignment=.75
      HorizontalAlignment=.5
      VerticalAlignment=.5
      WatermarkHorizontalAlignment=.5
      WatermarkVerticalAlignment=.5
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
