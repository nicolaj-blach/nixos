{ ... }:

{
  flake.nixosModules.plymouth =
    { pkgs, ... }:
    let
      base00 = "282c34";
      base03 = "5c6370";
      base05 = "abb2bf";

      logo = pkgs.runCommand "nb-plymouth-logo.png" { nativeBuildInputs = [ pkgs.librsvg ]; } ''
        rsvg-convert -h 200 ${../../../assets/logo.svg} -o $out
      '';

      theme = pkgs.stdenvNoCC.mkDerivation {
        pname = "nb-plymouth-theme";
        version = "1.0";
        dontUnpack = true;

        installPhase = ''
          dir=$out/share/plymouth/themes/nb
          mkdir -p $dir/images
          cp ${logo} $dir/images/watermark.png
          bgrt=${pkgs.nixos-bgrt-plymouth}/share/plymouth/themes/nixos-bgrt/images
          for img in bullet entry lock capslock keyboard; do
            cp $bgrt/$img.png $dir/images/
          done

          cat > $dir/nb.plymouth << EOF
          [Plymouth Theme]
          Name=N-B
          Description=Minimal boot theme with N-B logo
          ModuleName=two-step

          [two-step]
          Font=JetBrainsMono Nerd Font 12
          TitleFont=JetBrainsMono Nerd Font 16
          ImageDir=$dir/images
          DialogHorizontalAlignment=.5
          DialogVerticalAlignment=.75
          TitleHorizontalAlignment=.5
          TitleVerticalAlignment=.382
          HorizontalAlignment=.5
          VerticalAlignment=.7
          WatermarkHorizontalAlignment=.5
          WatermarkVerticalAlignment=.45
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
      boot = {
        plymouth = {
          enable = true;
          theme = "nb";
          themePackages = [ theme ];
        };

        initrd.systemd.enable = true;
        consoleLogLevel = 0;
        initrd.verbose = false;
        kernelParams = [
          "quiet"
          "rd.udev.log_level=3"
          "systemd.show_status=auto"
        ];
      };
    };
}
