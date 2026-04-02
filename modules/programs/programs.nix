{
  pkgs,
  inputs,
  username,
  ...
}:

let
  zen-browser =
    let
      zenBeta = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta;
    in
    pkgs.symlinkJoin {
      name = "zen";
      paths = [ zenBeta ];
      postBuild = ''
        # Replace the zen-beta binary symlink with a renamed wrapper
        rm $out/bin/zen-beta
        cp ${zenBeta}/bin/zen-beta $out/bin/zen
        chmod +x $out/bin/zen

        # Replace the desktop file with corrected names
        rm $out/share/applications/zen-beta.desktop
        substitute ${zenBeta}/share/applications/zen-beta.desktop $out/share/applications/zen.desktop \
          --replace-fail "Name=Zen Browser (Beta)" "Name=Zen Browser" \
          --replace-fail "Exec=zen-beta" "Exec=zen" \
          --replace-fail "StartupWMClass=zen-beta" "StartupWMClass=zen-beta"
      '';
    };
in
{
  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Use gcc lib from Hyprland flake for GLIBCXX_3.4.34 compatibility
        inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.system}.stdenv.cc.cc.lib
        zlib
        openssl
        curl
        icu
      ];
    };
    firefox.enable = true;

    git = {
      enable = true;
      config.pull.rebase = true;
    };

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 7d --keep 5";
      flake = "/home/${username}/nixos";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      # Core Dependencies
      wget
      gcc
      jq
      libnotify
      glib

      # Shell & Terminal
      ghostty
      zsh
      oh-my-zsh
      zsh-autosuggestions
      zsh-syntax-highlighting
      zsh-autopair
      starship
      carapace

      # File Management
      yazi
      stow
      eza
      fd
      ripgrep
      fzf
      zoxide
      tree
      unzip
      dua

      # Text & Viewing
      bat
      glow
      tldr
      lue
      ansifilter
      pandoc

      # Editors
      vim
      neovim
      vscode

      # Git & VCS
      git
      gh
      diffnav
      gh-dash
      lazygit
      onefetch
      gitlogue
      gitnr
      mani

      # Dev Languages
      cargo
      bun
      nodejs_24
      go
      dotnetCorePackages.sdk_10_0-bin
      uv
      python313
      python313Packages.pip
      python313Packages.venvShellHook
      python313Packages.dbus-python
      python313Packages.into-dbus-python
      python313Packages.dbus-python-client-gen

      # Dev Tools
      gnumake
      lazydocker
      lazysql
      posting

      # Nix Tooling
      statix
      nixfmt
      tinty
      ags

      # System Monitoring
      btop
      fastfetch
      speedtest-cli

      # TUI Apps
      bluetui
      bluez
      wiremix
      ticker
      opencode
      jiratui
      basalt
      smassh
      inputs.wlctl.packages.${pkgs.stdenv.hostPlatform.system}.default
      hyprmon

      # Desktop Utilities
      swww
      swayosd
      mako
      brightnessctl
      playerctl
      udiskie
      wl-clipboard
      libqalculate

      # Media & Images
      imagemagick
      chafa
      imv
      ansilove

      # Screenshot & Color
      grim
      slurp
      satty
      hyprpicker

      # Security & Auth
      sbctl
      tpm2-tss
      tpm2-tools
      gnupg
      pinentry-curses
      pinentry-gnome3

      # Email
      protonmail-bridge
      aerc
      neomutt
      urlscan
      lynx

      # Communication
      vesktop
      discordo

      # Browsers
      zen-browser
      chromium

      # Applications
      inkscape
      obsidian
      (llm.withPlugins { llm-gemini = true; })

      # Fun & Visual
      cowsay
      fortune
      terminaltexteffects
      pipes-rs
      cmatrix

      # Disk & Partition
      parted
    ];
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      GTK_USE_PORTAL = "1";
      BROWSER = "zen";

      # NVIDIA OpenGL fixes for Ghostty/GTK apps (reduces random freezes)
      __GL_YIELD = "usleep"; # Prevents busy-wait GPU stalls
      __GL_THREADED_OPTIMIZATION = "0"; # Disable threaded GL (can cause freezes)
      __GL_MaxFramesAllowed = "1"; # Reduce frame queue depth
    };
  };
}
