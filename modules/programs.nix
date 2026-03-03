{ pkgs, inputs, username, ... }:

let
  zen-browser = let
    zenBeta = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta;
  in pkgs.symlinkJoin {
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

  # Remove the PEP 668 marker so pip install works outside of venvs
  mutablePython = pkgs.symlinkJoin {
    name = "python3-mutable";
    paths = [ pkgs.python313 ];
    postBuild = ''
      rm -f $out/lib/python3.13/EXTERNALLY-MANAGED
    '';
  };
in
{
  environment.systemPackages = with pkgs; [
    # Dependencies
    wget
    gcc
    jq
    libnotify

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

    # Desktop
    swww
    mako
    imagemagick
    chafa
    brightnessctl
    playerctl

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
    inputs.wlctl.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Dev tools
    cargo
    bun
    nodejs_24
    statix
    dotnetCorePackages.runtime_10_0-bin
    uv
    python313
    python313Packages.pip
    python313Packages.venvShellHook
    python313Packages.dbus-python
    python313Packages.into-dbus-python
    python313Packages.dbus-python-client-gen
    ags

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
    (protonmail-desktop.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        ln -s $out/share/applications/proton-mail.desktop $out/share/proton-mail/proton-mail.desktop
      '';
    }))
    aerc

    # Apps
    inkscape
    vesktop
    zen-browser
  ];

  programs.nix-ld.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.GTK_USE_PORTAL = "1";
  environment.sessionVariables.EDITOR = "nvim";
  environment.sessionVariables.VISUAL = "nvim";
  programs.firefox.enable = true;

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 5";
    flake = "/home/${username}/nixos";
  };
}
