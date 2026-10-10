{ ... }:

{
  flake.homeManagerModules.superfile =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      home = config.home.homeDirectory;

      dirIcons = import ../_dir-icons.nix;

      spf-dir-editor = pkgs.writeShellScriptBin "spf-dir-editor" ''
        if [ -n "$INSIDE_EMACS" ]; then
          exec emacsclient -n "$@"
        fi
        exec emacsclient -c -n "$@"
      '';

      # superfile has no config for folder icons or sidebar labels, so patch them in:
      # lowercase labels for the XDG sidebar entries, and dirIcons for folder names.
      superfile = pkgs.superfile.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./invert-selection.patch ];
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/internal/ui/sidebar/directory_utils.go \
            ${
              lib.concatMapStrings (n: "--replace-fail '\"${n}\"}' '\"${lib.toLower n}\"}' ") [
                "Home"
                "Downloads"
                "Documents"
                "Pictures"
                "Videos"
                "Music"
                "Templates"
                "PublicShare"
              ]
            } \
            --replace-fail 'icon.Download + icon.Space' '"${dirIcons.downloads}" + icon.Space' \
            --replace-fail 'icon.Documents + icon.Space' '"${dirIcons.documents}" + icon.Space' \
            --replace-fail 'icon.Pictures + icon.Space' '"${dirIcons.pictures}" + icon.Space' \
            --replace-fail 'icon.Videos + icon.Space' '"${dirIcons.videos}" + icon.Space' \
            --replace-fail 'icon.Music + icon.Space' '"${dirIcons.music}" + icon.Space' \
            --replace-fail 'icon.Templates + icon.Space' '"${dirIcons.templates}" + icon.Space' \
            --replace-fail '		{Location: xdg.UserDirs.PublicShare, Name: icon.PublicShare + icon.Space + "publicshare"},' ""
          substituteInPlace src/config/icon/icon.go \
            --replace-fail '"superfile": {Icon:' '${
              lib.concatStrings (
                lib.mapAttrsToList (name: glyph: "\"${name}\": {Icon: \"${glyph}\", Color: \"NONE\"}, ") dirIcons
              )
            }"superfile": {Icon:'
        '';
      });
    in
    {
      # superfile's cd_on_quit wrapper: after quitting, cd to the last folder
      programs.zsh.initContent = ''
        spf() {
          local lastdir="''${XDG_STATE_HOME:-$HOME/.local/state}/superfile/lastdir"
          command superfile "$@"
          if [[ -f "$lastdir" ]]; then
            . "$lastdir"
            rm -f -- "$lastdir"
          fi
        }
      '';

      home.packages = [
        pkgs.exiftool
        spf-dir-editor
      ];

      custom.niri.binds."Mod+E" = [
        "kitty"
        "--class"
        "superfile"
        "-e"
        "superfile"
      ];

      xdg.mimeApps.defaultApplications."inode/directory" = "superfile.desktop";

      xdg.desktopEntries.superfile = {
        name = "superfile";
        genericName = "File Manager";
        exec = "kitty --class superfile -e superfile %F";
        icon = "system-file-manager";
        terminal = false;
        categories = [
          "System"
          "FileTools"
          "FileManager"
        ];
        mimeType = [ "inode/directory" ];
      };

      programs.superfile = {
        enable = true;
        package = superfile;
        firstUseCheck = false;
        themes.onedark-pro =
          let
            bg = "#282c34";
            bgDark = "#21252b";
            bgLight = "#2c313a";
            selection = "#3e4451";
            fg = "#abb2bf";
            comment = "#5c6370";
            border = "#3e4451";
            red = "#e06c75";
            green = "#98c379";
            yellow = "#e5c07b";
            blue = "#61afef";
            magenta = "#c678dd";
            cyan = "#56b6c2";
          in
          {
            code_syntax_highlight = "onedark";

            file_panel_border = border;
            sidebar_border = border;
            footer_border = border;

            file_panel_border_active = blue;
            sidebar_border_active = magenta;
            footer_border_active = green;
            modal_border_active = cyan;

            full_screen_bg = bg;
            file_panel_bg = bg;
            sidebar_bg = bgDark;
            footer_bg = bgDark;
            modal_bg = bgLight;

            full_screen_fg = fg;
            file_panel_fg = fg;
            sidebar_fg = fg;
            footer_fg = fg;
            modal_fg = fg;

            cursor = blue;
            correct = green;
            error = red;
            hint = cyan;
            cancel = red;
            gradient_color = [
              blue
              magenta
            ];

            file_panel_top_directory_icon = green;
            file_panel_top_path = blue;
            file_panel_item_selected_fg = blue;
            file_panel_item_selected_bg = selection;

            sidebar_title = magenta;
            sidebar_item_selected_fg = blue;
            sidebar_item_selected_bg = selection;
            sidebar_divider = comment;

            modal_cancel_fg = bg;
            modal_cancel_bg = red;
            modal_confirm_fg = bg;
            modal_confirm_bg = green;

            help_menu_hotkey = yellow;
            help_menu_title = blue;
          };
        settings = lib.importTOML ./config.toml;
        hotkeys = lib.importTOML ./hotkeys.toml;
        pinnedFolders = [
          {
            name = "${dirIcons.nixos} nixos";
            location = "${home}/setup/nixos";
          }
          {
            name = "${dirIcons.projects} projects";
            location = "${home}/projects";
          }
          {
            name = "${dirIcons.notes} notes";
            location = "${home}/notes";
          }
          {
            name = "${dirIcons.media} media";
            location = "${home}/media";
          }
        ];
      };
    };
}
