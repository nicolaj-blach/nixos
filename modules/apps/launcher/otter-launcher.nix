{ inputs, ... }:

{
  flake.nixosModules.otter-launcher = { ... }: { };

  flake.homeManagerModules.otter-launcher =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.otter-launcher;
      system = pkgs.stdenv.hostPlatform.system;
      otterConfig = ''
        [general]
        default_module = "gg"
        empty_module = "app"
        exec_cmd = "sh -c"
        vi_mode = true
        esc_to_abort = true
        cheatsheet_entry = "?"
        loop_mode = false
        delay_startup = 30

        [interface]
        header_cmd = "printf '\\n'; chafa -s x10 --center on $HOME/nixos/assets/logo.svg 2>/dev/null"
        header_cmd_trimmed_lines = 1
        header = "\n\n  \u001B[90m>\u001B[0m "
        place_holder = ""
        suggestion_mode = "list"
        suggestion_lines = 7
        separator = ""
        footer = ""
        list_prefix = "  "
        selection_prefix = "\u001B[36m> \u001B[0m"
        prefix_padding = 4
        default_module_message = "  \u001B[90msearch the web\u001B[0m"
        empty_module_message = ""
        prefix_color = "\u001B[36m"
        description_color = "\u001B[37m"
        place_holder_color = "\u001B[90m"
        hint_color = "\u001B[90m"
        cursor_shape = 5
        move_interface_down = 0

        [[modules]]
        description = "launch apps"
        prefix = "app"
        cmd = "fsel --detach"

        [[modules]]
        description = "clipboard history"
        prefix = "cb"
        cmd = "fsel --cclip"

        [[modules]]
        description = "notifications"
        prefix = "n"
        cmd = "fsel-notifications"

        [[modules]]
        description = "emoji"
        prefix = "e"
        cmd = "fsel-emoji"

        [[modules]]
        description = "google search"
        prefix = "gg"
        cmd = "niri msg action spawn -- zen-beta 'https://www.google.com/search?q={}'"
        with_argument = true
        url_encode = true

        [[modules]]
        description = "run command"
        prefix = "sh"
        cmd = "kitty-popup-term -e sh -c '{}; echo; read -p \"Press enter to close\"'"
        with_argument = true
        unbind_proc = true

        [[modules]]
        description = "calculator"
        prefix = "c"
        cmd = "kitty-popup-term -e sh -c 'qalc {}; read -p \"Press enter to close\"'"
        with_argument = true
        unbind_proc = true

        [[modules]]
        description = "browser"
        prefix = "b"
        cmd = "niri msg action spawn -- zen-beta"

        [[modules]]
        description = "nix packages"
        prefix = "nix"
        cmd = "niri msg action spawn -- zen-beta 'https://search.nixos.org/packages?query={}'"
        with_argument = true
        url_encode = true

        [[modules]]
        description = "github"
        prefix = "gh"
        cmd = "niri msg action spawn -- zen-beta 'https://github.com/search?q={}'"
        with_argument = true
        url_encode = true

        [[modules]]
        description = "youtube"
        prefix = "yt"
        cmd = "niri msg action spawn -- zen-beta 'https://www.youtube.com/results?search_query={}'"
        with_argument = true
        url_encode = true
      '';
    in
    {
      options.programs.otter-launcher = {
        enable = lib.mkEnableOption "Otter Launcher";
        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.otter-launcher.packages.${system}.default;
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];
        xdg.configFile."otter-launcher/config.toml".text = otterConfig;
      };
    };
}
