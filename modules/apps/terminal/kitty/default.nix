{ ... }:
{
  flake.homeManagerModules.kitty =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.kitty;

      # Wrapper script for popup windows with padding
      kitty-popup = pkgs.writeShellScriptBin "kitty-popup" ''
        exec kitty --class popup -o window_padding_width=8 "$@"
      '';

      kitty-popup-term = pkgs.writeShellScriptBin "kitty-popup-term" ''
        exec kitty --class popup-term -o window_padding_width=8 "$@"
      '';

      kitty-popup-large = pkgs.writeShellScriptBin "kitty-popup-large" ''
        exec kitty --class popup-large -o window_padding_width=8 "$@"
      '';

      kitty-popup-assistant = pkgs.writeShellScriptBin "kitty-popup-assistant" ''
        exec kitty --class popup-assistant -o window_padding_width=8 "$@"
      '';

      # OneDark color scheme (matching doom-one)
      # OneDark color scheme (matching quickshell bar)
      colorsConf = ''
        # vim:ft=kitty

        ## name:     base16 OneDark
        ## author:   Lalit Magant (http://github.com/tilal6991)

        # The basic colors
        background #282c34
        foreground #abb2bf
        selection_background #abb2bf
        selection_foreground #3e4451

        # Cursor colors
        cursor #abb2bf
        cursor_text_color #282c34

        # URL underline color when hovering with mouse
        url_color #565c64

        # Kitty window border colors
        active_border_color #545862
        inactive_border_color #353b45

        # OS Window titlebar colors
        wayland_titlebar_color #282c34

        # Tab bar colors
        active_tab_background #282c34
        active_tab_foreground #abb2bf
        inactive_tab_background #353b45
        inactive_tab_foreground #565c64
        tab_bar_background #353b45

        # The 16 terminal colors
        # normal
        color0 #282c34
        color1 #e06c75
        color2 #98c379
        color3 #e5c07b
        color4 #61afef
        color5 #c678dd
        color6 #56b6c2
        color7 #abb2bf

        # bright
        color8 #545862
        color9 #e06c75
        color10 #98c379
        color11 #e5c07b
        color12 #61afef
        color13 #c678dd
        color14 #56b6c2
        color15 #c8ccd4

        # extended base16 colors
        color16 #d19a66
        color17 #be5046
        color18 #353b45
        color19 #3e4451
        color20 #565c64
        color21 #b6bdca
      '';
    in
    {
      config = lib.mkIf cfg.enable {
        custom.niri.binds."Mod+Shift+Return" = [ "kitty" ];

        # Floating popups (see the kitty-popup-* wrappers above)
        custom.niri.extraConfig = ''
          window-rule {
              match app-id="popup"
              open-floating true
              default-column-width { fixed 450; }
              default-window-height { fixed 500; }
          }

          window-rule {
              match app-id="popup-term"
              open-floating true
              default-column-width { fixed 700; }
              default-window-height { fixed 500; }
          }

          window-rule {
              match app-id="popup-large"
              match app-id="popup-assistant"
              open-floating true
              default-column-width { fixed 1200; }
              default-window-height { fixed 750; }
          }
        '';

        programs.kitty = {
          font = {
            name = "JetBrainsMono Nerd Font";
            size = 11;
          };

          settings = {
            # No window decorations (compositor handles this)
            hide_window_decorations = "yes";

            # Disable confirm on close
            confirm_os_window_close = 0;

            # Enable splits layout
            enabled_layouts = "splits";

            # Dim inactive splits
            inactive_text_alpha = "0.4";

            # Tab bar style
            tab_bar_style = "separator";
            tab_separator = " │ ";
            active_tab_font_style = "normal";
            inactive_tab_font_style = "normal";
          };

          keybindings = {
            # Split navigation (vim-style)
            "alt+h" = "neighboring_window left";
            "alt+j" = "neighboring_window down";
            "alt+k" = "neighboring_window up";
            "alt+l" = "neighboring_window right";

            # Split creation (e = horizontal line, o = vertical line)
            "ctrl+shift+enter" = "new_window_with_cwd";
            "ctrl+shift+e" = "launch --location=hsplit --cwd=current";
            "ctrl+shift+o" = "launch --location=vsplit --cwd=current";

            # Split close
            "ctrl+shift+w" = "close_window";

            # Split resize
            "ctrl+alt+h" = "resize_window narrower 3";
            "ctrl+alt+j" = "resize_window shorter 3";
            "ctrl+alt+k" = "resize_window taller 3";
            "ctrl+alt+l" = "resize_window wider 3";

            # Tab navigation
            "ctrl+shift+h" = "previous_tab";
            "ctrl+shift+l" = "next_tab";
            "ctrl+shift+t" = "new_tab_with_cwd";

            # Universal copy/paste (kanata sends these for Super+C / Super+V)
            "ctrl+insert" = "copy_to_clipboard";
            "shift+insert" = "paste_from_clipboard";

            "ctrl+shift+y" = "launch --type=clipboard --stdin-source=@last_cmd_output";
          };

          extraConfig = colorsConf;
        };

        home.packages = [
          kitty-popup
          kitty-popup-term
          kitty-popup-large
          kitty-popup-assistant
        ];
      };
    };
}
