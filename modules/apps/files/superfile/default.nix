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
        # superfile refuses to start unless every field is present, so this is the
        # full default config.toml with our changes
        settings = {
          theme = "onedark-pro";
          editor = "";
          dir_editor = "spf-dir-editor";
          auto_check_update = false;
          cd_on_quit = true;
          default_open_file_preview = true;
          show_image_preview = true;
          show_panel_footer_info = true;
          default_directory = ".";
          file_size_use_si = false;
          default_sort_type = 0;
          sort_order_reversed = false;
          case_sensitive_sort = false;
          shell_close_on_success = false;
          debug = false;
          ignore_missing_fields = false;
          code_previewer = "bat";
          nerdfont = true;
          transparent_background = false;
          file_preview_width = 0;
          sidebar_width = 20;
          border_top = "─";
          border_bottom = "─";
          border_left = "│";
          border_right = "│";
          border_top_left = "┌";
          border_top_right = "┐";
          border_bottom_left = "└";
          border_bottom_right = "┘";
          border_middle_left = "├";
          border_middle_right = "┤";
          metadata = true;
          enable_md5_checksum = false;
          zoxide_support = true;
        };
        # superfile's vimHotkeys.toml, plus h/l for parent/open and the missing prompt key
        hotkeys = {
          confirm = [
            "enter"
            "l"
          ];
          quit = [
            "ctrl+c"
            ""
          ];
          list_up = [
            "k"
            ""
          ];
          list_down = [
            "j"
            ""
          ];
          page_up = [
            "pgup"
            ""
          ];
          page_down = [
            "pgdown"
            ""
          ];
          create_new_file_panel = [
            "n"
            ""
          ];
          close_file_panel = [
            "q"
            ""
          ];
          next_file_panel = [
            "tab"
            "L"
          ];
          previous_file_panel = [
            "shift+tab"
            "H"
          ];
          toggle_file_preview_panel = [
            "f"
            ""
          ];
          open_sort_options_menu = [
            "o"
            ""
          ];
          toggle_reverse_sort = [
            "R"
            ""
          ];
          focus_on_process_bar = [
            "ctrl+p"
            ""
          ];
          focus_on_sidebar = [
            "ctrl+s"
            ""
          ];
          focus_on_metadata = [
            "ctrl+d"
            ""
          ];
          file_panel_item_create = [
            "a"
            ""
          ];
          file_panel_item_rename = [
            "r"
            ""
          ];
          copy_items = [
            "y"
            ""
          ];
          cut_items = [
            "x"
            ""
          ];
          paste_items = [
            "p"
            ""
          ];
          delete_items = [
            "d"
            ""
          ];
          extract_file = [
            "ctrl+e"
            ""
          ];
          compress_file = [
            "ctrl+a"
            ""
          ];
          open_file_with_editor = [
            "e"
            ""
          ];
          open_current_directory_with_editor = [
            "E"
            ""
          ];
          pinned_directory = [
            "P"
            ""
          ];
          toggle_dot_file = [
            "."
            ""
          ];
          change_panel_mode = [
            "m"
            ""
          ];
          open_help_menu = [
            "?"
            ""
          ];
          open_command_line = [
            ":"
            ""
          ];
          open_spf_prompt = [
            ">"
            ""
          ];
          copy_path = [
            "Y"
            ""
          ];
          copy_present_working_directory = [
            "c"
            ""
          ];
          toggle_footer = [
            "ctrl+f"
            ""
          ];
          confirm_typing = [
            "enter"
            ""
          ];
          cancel_typing = [
            "esc"
            ""
          ];
          parent_directory = [
            "h"
            "-"
          ];
          search_bar = [
            "/"
            ""
          ];
          file_panel_select_mode_items_select_down = [
            "J"
            ""
          ];
          file_panel_select_mode_items_select_up = [
            "K"
            ""
          ];
          file_panel_select_all_items = [
            "A"
            ""
          ];
          file_panel_select_mode_invert_selection = [
            "I"
            ""
          ];
        };
        pinnedFolders = [
          {
            name = "${dirIcons.nixos} nixos";
            location = "${home}/nixos";
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
