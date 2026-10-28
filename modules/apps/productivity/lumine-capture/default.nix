{ inputs, ... }:

{
  # Screenshot editor on Mod+P
  flake.homeManagerModules.lumine-capture =
    { pkgs, ... }:
    {
      home.packages = [ inputs.lumine-capture.packages.${pkgs.stdenv.hostPlatform.system}.default ];

      # Unset options keep their defaults. Saves to ~/media/pictures/screenshots.
      xdg.configFile."LumineCapture/config.toml".text = ''
        [save]
        directory = "screenshots"
        month_format = ""
        filename_format = "Screenshot from %F %H-%M-%S"

        [theme]
        background = "#282C34FA"
        foreground = "#ABB2BF"
        muted = "#5C6370"
        hover = "#61AFEF"
        accent = "#61AFEF"
        on_accent = "#282C34"
        border = "#3E4452"
        border_on_light = "#21252B37"
        field = "#3E4452"
        track = "#3E4452"
        caret = "#528BFF"
        text_selection = "#61AFEF55"
        panel_radius = 0.0
        item_radius = 0.0
        separator_radius = 0.0

        [settings_panel]
        checkbox_radius = 0.0

        [color_picker]
        palette = ["#282C34", "#ABB2BF", "#E06C75", "#E5C07B", "#98C379", "#61AFEF"]
        outline_palette = ["#282C34", "#ABB2BF", "#E06C75", "#E5C07B", "#61AFEF", "#98C379"]
        sv_radius = 0.0
        hue_radius = 0.0
        field_radius = 0.0

        [magnifier]
        swatch_radius = 0.0

        [selection]
        border_radius = 0.0

        [annotations.handles]
        radius = 0.0

        # Left hand for the split keyboard, vim keys for the selection
        [keys]
        pin = "Ctrl+F"
        redo = "Ctrl+Shift+Z"
        toggle_magnifier = "1"
        size_up = "E"
        size_down = "Q"
        tool_ocr = "Z"
        tool_pen = "F"
        tool_highlighter = "W"
        tool_numerated_arrow = "B"
        move_left = "H"
        move_down = "J"
        move_up = "K"
        move_right = "L"
        move_left_fast = "Shift+H"
        move_down_fast = "Shift+J"
        move_up_fast = "Shift+K"
        move_right_fast = "Shift+L"
        resize_left = "Alt+H"
        resize_down = "Alt+J"
        resize_up = "Alt+K"
        resize_right = "Alt+L"
        resize_left_fast = "Alt+Shift+H"
        resize_down_fast = "Alt+Shift+J"
        resize_up_fast = "Alt+Shift+K"
        resize_right_fast = "Alt+Shift+L"
      '';

      custom.niri = {
        binds."Mod+P" = [ "lumine-capture" ];
        extraConfig = ''
          window-rule {
              match app-id="^lumine-pin$"
              open-floating true
          }
        '';
      };
    };
}
