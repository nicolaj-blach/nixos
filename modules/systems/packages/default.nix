{ inputs, ... }:
{
  flake.nixosModules.packages =
    { pkgs, ... }:
    {
      programs = {
        nix-ld = {
          enable = true;
          libraries = with pkgs; [
            zlib
            openssl
            curl
            icu
            inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.system}.stdenv.cc.cc.lib
          ];
        };

        bazecor.enable = true;

        nh = {
          enable = true;
          clean.enable = true;
          clean.extraArgs = "--keep-since 7d --keep 5";
        };
      };

      environment = {
        sessionVariables = {
          NIXOS_OZONE_WL = "1";
          GTK_USE_PORTAL = "1";
          BROWSER = "zen-beta";
        };

        systemPackages = with pkgs; [
          # Core Dependencies
          wget
          gcc
          jq
          libnotify
          glib

          # File Management
          yazi
          stow
          eza
          fd
          ripgrep
          fzf
          television
          zoxide
          tree
          unzip
          dua

          # Text & Viewing
          bat
          glow
          tldr
          ansifilter
          pandoc

          # Editors
          vim
          neovim

          # Git & VCS
          git
          gh
          diffnav
          gh-dash
          lazygit
          onefetch

          # Dev Languages
          cargo
          bun
          nodejs_24
          go
          uv
          python313
          python313Packages.pip

          # Dev Tools
          gnumake
          posting
          vscode
          lazydocker
          lazysql

          # Nix Tooling
          statix
          nixfmt
          tinty
          devenv

          # System Monitoring
          btop
          fastfetch
          speedtest-cli

          # TUI Apps
          bluetui
          bluez
          wiremix
          smassh
          inputs.wlctl.packages.${pkgs.stdenv.hostPlatform.system}.default
          opencode
          inputs.nix-search-tv.packages.${pkgs.stdenv.hostPlatform.system}.default
          inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.fsel
          inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.nirimon
          inputs.otter-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default
          wl-mirror

          # Desktop Utilities
          fuzzel
          swww
          swayosd
          mako
          brightnessctl
          playerctl
          udiskie
          wl-clipboard
          wtype
          bemoji
          libqalculate
          gnuplot

          # Media & Images
          imagemagick
          chafa
          imv

          # Screenshot & Color
          grim
          slurp
          satty
          hyprpicker

          # Security & Auth
          sbctl
          gnupg
          pinentry-curses
          pinentry-gnome3

          # Email
          aerc

          # Communication
          vesktop

          # Terminals
          ghostty

          # Browsers
          chromium

          # Applications
          inkscape
          obsidian

          # Fun & Visual
          cowsay
          fortune
          cmatrix
          pipes-rs
          terminaltexteffects

          # Disk
          parted
        ];
      };
    };
}
