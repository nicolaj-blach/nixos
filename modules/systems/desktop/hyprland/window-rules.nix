{ ... }:

{
  flake.homeManagerModules.hyprland-window-rules =
    { config, lib, ... }:
    let
      cfg = config.wayland.windowManager.hyprland;

      popupRules =
        classes:
        builtins.concatMap (class: [
          "float, class:^(${class})$"
          "center, class:^(${class})$"
          "pin, class:^(${class})$"
          "stayfocused, class:^(${class})$"
          "animation slide, class:^(${class})$"
        ]) classes;

      overlayRules =
        classes:
        builtins.concatMap (class: [
          "float, class:^(${class})$"
          "pin, class:^(${class})$"
          "noanim, class:^(${class})$"
          "rounding 0, class:^(${class})$"
          "noborder, class:^(${class})$"
          "nofocus, class:^(${class})$, title:^()$"
          "move 0 0, class:^(${class})$"
        ]) classes;

      pipRules =
        classes:
        builtins.concatMap (class: [
          "float, class:^(${class})$"
          "pin, class:^(${class})$"
          "size 480 270, class:^(${class})$"
          "move 100%-490 100%-280, class:^(${class})$"
        ]) classes;
    in
    {
      options.custom.hyprland.windowRules = {
        popupClasses = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        overlayClasses = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        pipClasses = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };

      config = lib.mkIf (cfg.enable or false) {
        wayland.windowManager.hyprland.settings.windowrulev2 =
          (popupRules config.custom.hyprland.windowRules.popupClasses)
          ++ (overlayRules config.custom.hyprland.windowRules.overlayClasses)
          ++ (pipRules config.custom.hyprland.windowRules.pipClasses);
      };
    };
}
