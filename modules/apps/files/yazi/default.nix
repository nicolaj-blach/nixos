{ ... }:

{
  flake.homeManagerModules.yazi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      dirIcons = import ../_dir-icons.nix;
    in
    {
      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
        shellWrapperName = "y";
        theme.icon.prepend_dirs = lib.mapAttrsToList (name: text: { inherit name text; }) dirIcons;
        settings.mgr = {
          show_hidden = false;
          sort_dir_first = true;
        };
      };

      # File dialogs (xdg portal) open yazi in a floating popup
      xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
        env=TERMCMD=kitty --class popup-large --title file-picker
        default_dir=${config.home.homeDirectory}/downloads
        create_help_file=0
        open_mode=suggested
        save_mode=default
      '';
    };
}
