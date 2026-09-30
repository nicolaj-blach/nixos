{ ... }:

{
  flake.homeManagerModules.system-info =
    { pkgs, ... }:
    let
      renderLogo =
        name: extraArgs:
        pkgs.runCommand name { nativeBuildInputs = [ pkgs.librsvg ]; } ''
          rsvg-convert -h 400 ${extraArgs} ${../../../assets/logo.svg} -o $out
        '';
      logo = renderLogo "fastfetch-logo.png" "";
      # ghostel drops image transparency, so it gets the logo on the OneDark background
      logoGhostel = renderLogo "fastfetch-logo-ghostel.png" "-b '#282c34'";
      section = title: {
        type = "custom";
        format = "{#90}${title}";
      };
      key =
        glyph: type: color: extra:
        {
          inherit type;
          key = glyph;
          keyColor = color;
        }
        // extra;
    in
    {
      programs.fastfetch = {
        enable = true;
        settings = {
          display.separator = " ";
          logo = {
            source = "${logo}";
            type = "kitty-direct";
            width = 20;
            height = 10;
            position = "left";
            padding = {
              top = 1;
              left = 2;
              right = 4;
            };
          };
          modules = [
            (section "┌──────────────────────Hardware──────────────────────┐")
            (key "┌ 󰻠" "cpu" "green" { showPeCoreCount = true; })
            (key "├ 󰢮" "gpu" "green" { detectionMethod = "pci"; })
            (key "├ 󰍹" "display" "green" { })
            (key "├ 󰋊" "disk" "green" { })
            (key "├ 󰁹" "battery" "green" { })
            (key "└ 󰑭" "memory" "green" { })
            (section "├──────────────────────Software──────────────────────┤")
            (key "┌ 󱄅" "os" "yellow" { })
            (key "├ 󰌽" "kernel" "yellow" { })
            (key "├ 󰏖" "packages" "yellow" { })
            (key "├ 󰆍" "shell" "yellow" { })
            (key "├ 󰏫" "editor" "yellow" { })
            (key "└ 󰒋" "bootmgr" "yellow" { })
            (section "├──────────────────────Desktop───────────────────────┤")
            (key "┌ 󰖲" "wm" "blue" { })
            (key "└ 󰆍" "terminal" "blue" { })
            (section "└────────────────────────────────────────────────────┘")
            {
              type = "colors";
              symbol = "block";
            }
          ];
        };
      };

      programs.zsh.initContent = ''
        fe() {
          if [[ -n "$INSIDE_EMACS" ]]; then
            fastfetch --logo ${logoGhostel} "$@"
          else
            fastfetch "$@"
          fi
        }
      '';

      programs.btop = {
        enable = true;
        settings = {
          color_theme = "onedark";
          theme_background = true;
          truecolor = true;
          vim_keys = true;
          rounded_corners = false;
          presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";
          shown_boxes = "net proc mem cpu";
          update_ms = 2000;
          proc_sorting = "memory";
          proc_mem_bytes = true;
          proc_cpu_graphs = true;
          cpu_invert_lower = true;
          show_cpu_watts = true;
          show_uptime = true;
          check_temp = true;
          temp_scale = "celsius";
          clock_format = "%X";
          mem_graphs = true;
          show_swap = true;
          swap_disk = true;
          show_disks = true;
          only_physical = true;
          use_fstab = true;
          show_io_stat = true;
          show_battery = true;
          show_battery_watts = true;
        };
      };

      # `tv nix`: fuzzy nixpkgs search (used by Mod+Shift+N and otter `pkg`)
      programs.television = {
        enable = true;
        channels.nix = {
          metadata = {
            name = "nix";
            requirements = [ "nix-search-tv" ];
          };
          source.command = "nix-search-tv print";
          preview.command = "nix-search-tv preview {}";
        };
      };
    };
}
