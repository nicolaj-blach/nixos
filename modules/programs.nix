{ pkgs, inputs, ... }:

let
  zen-browser = let
    zenBeta = inputs.zen-browser.packages.${pkgs.system}.beta;
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
in
{
  environment.systemPackages = with pkgs; [
    # Dependencies
    wget
    gcc

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
    swww

    # TUI
    yazi
    btop
    bluez
    bluetui
    wiremix
    lazydocker
    ticker
    opencode

    # Dev tools
    bun
    nodejs_24
    dotnetCorePackages.runtime_10_0-bin
    uv
    python315
    python313Packages.pip
    python313Packages.venvShellHook

    # Apps
    vesktop
    zen-browser
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    neovim
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.firefox.enable = true;
}
