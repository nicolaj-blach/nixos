{ ... }:
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
            stdenv.cc.cc.lib
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
          stow
          ripgrep
          zoxide
          tree
          unzip
          dua

          # Text & Viewing
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

          # System Monitoring
          speedtest-cli

          # TUI Apps
          bluez
          smassh
          opencode
          wl-mirror

          # Desktop Utilities
          fuzzel
          brightnessctl
          udiskie
          wl-clipboard
          wtype
          bemoji
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
