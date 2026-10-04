{ ... }:

{
  flake.homeManagerModules.fsel =
    {
      config,
      lib,
      pkgs,
      unstablePkgs,
      ...
    }:
    let
      cfg = config.programs.fsel;

      jq = "${pkgs.jq}/bin/jq";
      wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";

      # "emoji<TAB>name" list generated from the Unicode emoji test file
      emojiList = pkgs.runCommand "emoji-list.txt" { } ''
        grep '; fully-qualified' ${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt \
          | sed -E 's/.*# ([^ ]+) E[0-9.]+ (.*)/\1\t\2/' > $out
      '';

      # Pick an emoji: copy it to the clipboard and type it into the previous window
      fsel-emoji = pkgs.writeShellScriptBin "fsel-emoji" ''
        emoji=$(fsel --dmenu --delimiter $'\t' --accept-nth 1 < ${emojiList})
        [ -z "$emoji" ] && exit 0
        printf '%s' "$emoji" | ${wl-copy}
        niri msg action spawn -- sh -c "sleep 0.2; ${pkgs.wtype}/bin/wtype '$emoji'"
      '';

      # Browse mako notification history; selecting one copies its text
      fsel-notifications = pkgs.writeShellScriptBin "fsel-notifications" ''
        history=$(busctl --user --json=short call org.freedesktop.Notifications \
          /fr/emersion/Mako fr.emersion.Mako ListHistory 2>/dev/null)
        rows=$(printf '%s' "$history" | ${jq} -r '.data[0][]
          | [(.id.data|tostring), .["app-name"].data, .summary.data,
             (.body.data | gsub("[\t\n]"; " "))] | @tsv')
        if [ -z "$rows" ]; then
          notify-send "Notifications" "No notification history"
          exit 0
        fi
        id=$(printf '%s\n' "$rows" | fsel --dmenu --delimiter $'\t' --with-nth 2,3,4 --accept-nth 1)
        [ -z "$id" ] && exit 0
        printf '%s' "$history" | ${jq} -r --argjson id "$id" '.data[0][]
          | select(.id.data == $id) | .summary.data + "\n" + .body.data' | ${wl-copy}
      '';
      fsel-system = pkgs.writeShellScriptBin "fsel-system" ''
        confirm() {
          [ "$(printf '%s\n' "Yes, $1" "No, cancel" | fsel --dmenu --only-match)" = "Yes, $1" ]
        }
        pick_generation() {
          nixos-rebuild list-generations --json 2>/dev/null | ${jq} -r '.[]
            | "\(.generation)\t\(.generation)  \(.date[0:16])  \(.kernelVersion)\(if .current then "  (current)" else "" end)"' \
            | fsel --dmenu --only-match --delimiter $'\t' --with-nth 2 --accept-nth 1
        }
        entries=(Shutdown Lock Logout "Switch generation" Reboot "Rebuild system")
        command -v ai-refresh >/dev/null && entries+=("Refresh AI models")
        choice=$(printf '%s\n' "''${entries[@]}" | fsel --dmenu --only-match)
        case "$choice" in
          Shutdown) confirm shutdown && systemctl poweroff ;;
          Lock) niri msg action spawn -- hyprlock-wrapper ;;
          Logout) confirm logout && niri msg action quit --skip-confirmation ;;
          "Switch generation")
            gen=$(pick_generation)
            [ -z "$gen" ] && exit 0
            current=$(readlink /nix/var/nix/profiles/system | sed -E 's/system-([0-9]+)-link/\1/')
            [ "$gen" = "$current" ] && exit 0
            confirm "switch to $gen" && niri msg action spawn -- kitty-popup-term sh -c \
              "nh os rollback --to $gen; echo; read -rp 'Press Enter to close'" ;;
          Reboot) confirm reboot && systemctl reboot ;;
          "Rebuild system")
            niri msg action spawn -- kitty-popup-term sh -c \
              'sudo nixos-rebuild switch --flake ~/nixos#$(hostname); echo; read -rp "Press Enter to close"' ;;
          "Refresh AI models") niri msg action spawn -- ai-refresh ;;
        esac
      '';

      fselConfig = ''
        # fsel configuration

        highlight_color = "LightBlue"
        cursor = "█"
        terminal_launcher = "kitty -e"
        rounded_borders = false

        [keybinds]
        # Navigation with Ctrl+J/K (vim-style)
        down = ["down", { key = "j", modifiers = "ctrl" }, { key = "n", modifiers = "ctrl" }]
        up = ["up", { key = "k", modifiers = "ctrl" }, { key = "p", modifiers = "ctrl" }]

        # Actions
        select = ["enter", { key = "y", modifiers = "ctrl" }]
        exit = ["esc", { key = "q", modifiers = "ctrl" }, { key = "c", modifiers = "ctrl" }]

        # Pin/hide
        pin = [{ key = "space", modifiers = "ctrl" }]
        hide = [{ key = "delete", modifiers = "alt" }]
        unhide_last = [{ key = "u", modifiers = "alt" }]

        backspace = ["backspace"]

        # cclip mode
        image_preview = [{ key = "i", modifiers = "alt" }]
        tag = [{ key = "t", modifiers = "ctrl" }]
        cclip_delete = [{ key = "delete", modifiers = "alt" }]

        [app_launcher]
        filter_desktop = true
        match_mode = "fuzzy"
        ranking_mode = "frecency"

        [cclip]
        image_preview = true
        show_line_numbers = true
      '';
    in
    {
      options.programs.fsel = {
        enable = lib.mkEnableOption "fsel launcher configuration";
      };

      config = lib.mkIf cfg.enable {
        custom.niri.binds = {
          "Mod+Escape" = [
            "kitty-popup"
            "-e"
            "fsel-system"
          ];
          "Mod+N" = [
            "kitty-popup"
            "-e"
            "fsel-notifications"
          ];
          "Mod+Period" = [
            "kitty-popup"
            "-e"
            "fsel-emoji"
          ];
          "Mod+Shift+V" = [
            "kitty-popup"
            "-e"
            "fsel"
            "--cclip"
          ];
        };

        xdg.configFile."fsel/config.toml".text = fselConfig;
        home.packages = [
          unstablePkgs.fsel
          fsel-emoji
          fsel-notifications
          fsel-system
        ];
      };
    };
}
