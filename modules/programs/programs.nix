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
        stdenv.cc.cc.lib
        zlib
        openssl
        curl
        icu
      ];
    };
    firefox.enable = true;

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 7d --keep 5";
      flake = "/home/${username}/nixos";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      # Dependencies
      wget
      gcc
      jq
      libnotify
      glib

      # CLI tools
      stow
      eza
      fzf
      zoxide
      bat
      tldr
      cowsay
      fastfetch
      terminaltexteffects
      fd
      ripgrep
      unzip
      tree
      tinty
      speedtest-cli
      starship
      glow
      ansilove
      parted
      (llm.withPlugins { llm-gemini = true; })

      # Editors
      vim
      neovim
      vscode

      # Git
      git
      gh
      lazygit

      # Terminal
      ghostty
      zsh
      oh-my-zsh
      zsh-autosuggestions
      zsh-syntax-highlighting
      zsh-autopair

      # Desktop
      swww
      mako
      imagemagick
      chafa
      brightnessctl
      playerctl
      udiskie

      # TUI
      yazi
      btop
      bluez
      bluetui
      wiremix
      lazydocker
      ticker
      opencode
      jiratui
      basalt
      inputs.wlctl.packages.${pkgs.stdenv.hostPlatform.system}.default

      # Dev tools
      cargo
      bun
      nodejs_24
      go
      statix
      dotnetCorePackages.sdk_10_0-bin
      uv
      python313
      python313Packages.pip
      python313Packages.venvShellHook
      python313Packages.dbus-python
      python313Packages.into-dbus-python
      python313Packages.dbus-python-client-gen
      ags
      gnumake
      nixfmt

      # Security
      sbctl
      tpm2-tss
      tpm2-tools

      # Clipboard
      wl-clipboard

      # Screenshot
      grim
      slurp
      satty

      # Color picker
      hyprpicker

      # Image viewer
      imv

      # Email
      protonmail-bridge
      aerc
      neomutt
      urlscan
      gnupg
      pinentry-curses
      pinentry-gnome3
      chromium

      # Apps
      inkscape
      vesktop
      zen-browser
      obsidian
    ];
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      GTK_USE_PORTAL = "1";
      BROWSER = "zen";
    };
  };
}
