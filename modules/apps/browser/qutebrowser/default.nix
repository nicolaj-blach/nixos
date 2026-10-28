{ ... }:

{
  flake.homeManagerModules.qutebrowser =
    {
      config,
      lib,
      pkgs,
      osConfig,
      ...
    }:
    let
      bg = "#282c34";
      bgAlt = "#21252b";
      bgSel = "#3e4451";
      fg = "#abb2bf";
      gray = "#5c6370";
      blue = "#61afef";
      green = "#98c379";
      red = "#e06c75";
      yellow = "#e5c07b";
      purple = "#c678dd";

      # Fill logins from Proton Pass. Usage: qute-proton-pass fill|password|totp
      # pass-cli comes from PATH: the wrapper in the proton-pass module
      startPage = pkgs.runCommand "qutebrowser-start" { } ''
        mkdir $out
        sed -n '/<svg/,$p' ${../../../../assets/logo.svg} | sed -E '/^ *(width|height)=/d' > logo.svg
        sed -e 's|@HOST@|${osConfig.networking.hostName}|' -e 's|@VERSION@|${lib.trivial.release}|' \
          -e '/@LOGO@/{r logo.svg' -e 'd}' ${./start.html} > $out/index.html
      '';

      # Context menu icons in the theme's foreground colour
      menuIcons = pkgs.runCommand "qutebrowser-menu-icons" { } ''
        mkdir $out
        for i in go-previous go-next view-refresh process-stop; do
          sed 's/#2e3436/${fg}/' ${pkgs.adwaita-icon-theme}/share/icons/Adwaita/symbolic/actions/$i-symbolic.svg > $out/$i.svg
        done
      '';

      markScrollable = pkgs.writeText "mark-scrollable.js" ''
        document.querySelectorAll("*").forEach((e) => {
          const o = getComputedStyle(e).overflowY;
          if ((o === "auto" || o === "scroll") && e.scrollHeight > e.clientHeight + 20)
            e.setAttribute("data-qb-scroll", "");
        });
      '';

      # Toggle the tab sidebar/status bar. Usage: qute-bars tabs|bar|both
      # "both" hides both unless both are already hidden. State is reset in config.py.
      qute-bars = pkgs.writeShellApplication {
        name = "qute-bars";
        text = ''
          dir="$XDG_RUNTIME_DIR/qute-bars"
          mkdir -p "$dir"
          set_bar() {
            if [ "$2" = hide ]; then touch "$dir/$1"; else rm -f "$dir/$1"; fi
            case $1-$2 in
              tabs-hide) echo "set tabs.show never" ;;
              tabs-show) echo "set tabs.show always" ;;
              bar-hide) echo "set statusbar.show in-mode" ;;
              bar-show) echo "set statusbar.show always" ;;
            esac >> "$QUTE_FIFO"
          }
          toggle() { if [ -e "$dir/$1" ]; then set_bar "$1" show; else set_bar "$1" hide; fi; }
          case $1 in
            both)
              if [ -e "$dir/tabs" ] && [ -e "$dir/bar" ]; then a=show; else a=hide; fi
              set_bar tabs "$a"
              set_bar bar "$a"
              ;;
            *) toggle "$1" ;;
          esac
        '';
      };

      # Add the selection (or just the page) to its literature note in ~/notes
      qute-note = pkgs.writeShellApplication {
        name = "qute-note";
        text = ''
          dir=$(mktemp -d)
          trap 'rm -rf "$dir"' EXIT
          printf %s "$QUTE_URL" > "$dir/url"
          printf %s "$QUTE_TITLE" > "$dir/title"
          printf %s "''${QUTE_SELECTED_TEXT:-}" > "$dir/text"
          if what=$(emacsclient -e "(+notes-web-highlight \"$dir\")"); then
            echo "message-info 'Saved ''${what//\"/}'" >> "$QUTE_FIFO"
          else
            echo "message-error 'qute-note: emacsclient failed'" >> "$QUTE_FIFO"
          fi
        '';
      };

      qute-proton-pass = pkgs.writeShellApplication {
        name = "qute-proton-pass";
        runtimeInputs = [
          pkgs.jq
          pkgs.wl-clipboard
        ];
        text = ''
          mode=''${1:-fill}
          msg() { echo "message-$1 '$2'" >> "$QUTE_FIFO"; }

          vaults=$(pass-cli vault list --output json 2>&1) || {
            if grep -qi locked <<< "$vaults"; then
              msg warning "Proton Pass is locked, unlock it and retry"
              niri msg action spawn -- kitty-popup-term -e pass-cli session unlock
            else
              msg error "Proton Pass: run pass-cli login"
            fi
            exit 0
          }
          out=$(for s in $(jq -r '[.. | objects | .share_id? // empty] | unique[]' <<< "$vaults"); do
            pass-cli item list --share-id "$s" --output json
          done)

          # github.com -> github
          host=$(sed -E 's#^[a-z]+://([^/:]+).*#\1#' <<< "$QUTE_URL")
          name=''${host%.*}
          name=''${name##*.}

          # "title<TAB>vault · last changed<TAB>ref": this site first, then the rest, newest first
          rows=$(jq -rs --argjson v "$vaults" --arg name "$name" '
            ([$v | .. | objects | select(has("share_id")) | {(.share_id): .name}] | add) as $names
            | [.[] | .. | objects
               | select(.item_type? == "login" and ((.state // "") | ascii_downcase) != "trashed")]
            | sort_by([(.title | ascii_downcase | contains($name | ascii_downcase) | not), .modify_time])
            | group_by(.title | ascii_downcase | contains($name | ascii_downcase) | not)
            | map(reverse) | add // [] | .[]
            | "\(.title)\t\($names[.share_id] // "?") · \(.modify_time[:10])\t\(.share_id)/\(.id)"' <<< "$out")
          matches=$(awk -F'\t' -v n="$name" 'index(tolower($1), tolower(n))' <<< "$rows")

          if [ "$(grep -c . <<< "$matches")" = 1 ]; then
            ref=$(cut -f3 <<< "$matches")
          else
            tmp=$(mktemp -d)
            trap 'rm -rf "$tmp"' EXIT
            cut -f1,2 <<< "$rows" > "$tmp/in"
            # shellcheck disable=SC2016
            kitty-popup -e sh -c 'fsel --dmenu --only-match --delimiter "$(printf "\t")" --match-nth 1 < "$1" > "$2"' _ "$tmp/in" "$tmp/out"
            n=$(awk -F'\t' 'NR == FNR { t = $1; d = $2; next }
              $1 == t && (d == "" || $2 == d) { print FNR; exit }' "$tmp/out" "$tmp/in")
            ref=$([ -n "$n" ] && sed -n "''${n}p" <<< "$rows" | cut -f3 || true)
          fi
          [ -z "$ref" ] && exit 0

          case $mode in
            totp)
              pass-cli item totp "pass://$ref" --output json | jq -r 'to_entries[0].value' | wl-copy
              msg info "TOTP copied"
              ;;
            password)
              echo "insert-text $(pass-cli item view "pass://$ref/password")" >> "$QUTE_FIFO"
              ;;
            *)
              user=$(pass-cli item view "pass://$ref/username" 2>/dev/null || true)
              [ -z "$user" ] && user=$(pass-cli item view "pass://$ref/email")
              pass=$(pass-cli item view "pass://$ref/password")
              {
                echo "insert-text $user"
                echo "fake-key <Tab>"
                echo "insert-text $pass"
              } >> "$QUTE_FIFO"
              ;;
          esac
        '';
      };
    in
    lib.mkIf config.programs.qutebrowser.enable {
      programs.qutebrowser = {
        # Keep "Always/Never" answers to permission prompts (stored in autoconfig.yml)
        loadAutoconfig = true;

        searchEngines = {
          DEFAULT = "https://duckduckgo.com/?q={}";
          g = "https://www.google.com/search?q={}";
          gh = "https://github.com/search?q={}";
          pm = "https://mail.proton.me/u/0/all-mail#keyword={}";
          nix = "https://search.nixos.org/packages?channel=unstable&query={}";
          hm = "https://home-manager-options.extranix.com/?query={}";
          yt = "https://www.youtube.com/results?search_query={}";
          w = "https://en.wikipedia.org/w/index.php?search={}";
        };

        keyBindings.normal = {
          ",p" = "spawn --userscript ${lib.getExe qute-proton-pass} fill";
          ",P" = "spawn --userscript ${lib.getExe qute-proton-pass} password";
          "xx" = "spawn --userscript ${lib.getExe qute-bars} both";
          "xb" = "spawn --userscript ${lib.getExe qute-bars} bar";
          # Hint a scrollable area and click it, so j/k scroll it
          ";s" = "jseval -q -f ${markScrollable} ;; hint scrollable";
          "xt" = "spawn --userscript ${lib.getExe qute-bars} tabs";
          ",o" = "spawn --userscript ${lib.getExe qute-proton-pass} totp";
          ",n" = "spawn --userscript ${lib.getExe qute-note}";
        };

        settings = {
          url.start_pages = [ "file://${startPage}/index.html" ];
          url.default_page = "file://${startPage}/index.html";
          url.open_base_url = true;
          auto_save.session = true;
          downloads.location.prompt = true;
          content.blocking.method = "both";
          content.pdfjs = true;
          colors.webpage.preferred_color_scheme = "dark";
          colors.webpage.bg = bg;
          # Dark devtools and other Chromium UI
          qt.args = [ "force-dark-mode" ];

          fileselect = {
            handler = "external";
            single_file.command = [ "kitty-popup-large" "-e" "yazi" "--chooser-file={}" ];
            multiple_files.command = [ "kitty-popup-large" "-e" "yazi" "--chooser-file={}" ];
            folder.command = [ "kitty-popup-large" "-e" "yazi" "--chooser-file={}" ];
          };

          tabs = {
            position = "right";
            width = "15%";
            title.format = "{audio}{index}: {current_title}";
            indicator.width = 0;
            favicons.scale = 1.0;
          };

          fonts = {
            default_family = "JetBrainsMono Nerd Font";
            default_size = "11pt";
            contextmenu = "default_size default_family";
            tooltip = "default_size default_family";
          };

          colors = {
            completion = {
              fg = fg;
              odd.bg = bg;
              even.bg = bg;
              category = { fg = blue; bg = bgAlt; border.top = bgAlt; border.bottom = bgAlt; };
              item.selected = { fg = fg; bg = bgSel; border.top = bgSel; border.bottom = bgSel; match.fg = yellow; };
              match.fg = blue;
              scrollbar = { fg = gray; bg = bg; };
            };
            statusbar = {
              normal = { fg = fg; bg = bg; };
              insert = { fg = bg; bg = green; };
              passthrough = { fg = bg; bg = blue; };
              command = { fg = fg; bg = bg; };
              caret = { fg = bg; bg = purple; };
              progress.bg = blue;
              url = {
                fg = fg;
                success.http.fg = fg;
                success.https.fg = green;
                error.fg = red;
                warn.fg = yellow;
                hover.fg = blue;
              };
            };
            tabs = {
              bar.bg = bgAlt;
              odd = { fg = gray; bg = bgAlt; };
              even = { fg = gray; bg = bgAlt; };
              selected.odd = { fg = bg; bg = blue; };
              selected.even = { fg = bg; bg = blue; };
              indicator = { start = blue; stop = green; error = red; };
            };
            hints = { fg = bg; bg = yellow; match.fg = red; };
            messages = {
              info = { fg = fg; bg = bg; border = bg; };
              warning = { fg = bg; bg = yellow; border = yellow; };
              error = { fg = bg; bg = red; border = red; };
            };
            prompts = { fg = fg; bg = bgAlt; border = "1px solid ${bgSel}"; selected.bg = bgSel; };
            downloads = {
              bar.bg = bg;
              start = { fg = bg; bg = blue; };
              stop = { fg = bg; bg = green; };
              error = { fg = bg; bg = red; };
            };
            keyhint = { fg = fg; bg = bgAlt; suffix.fg = yellow; };
            contextmenu = {
              menu = { fg = fg; bg = bgAlt; };
              selected = { fg = fg; bg = bgSel; };
              disabled = { fg = gray; bg = bgAlt; };
            };
            tooltip = { fg = fg; bg = bgAlt; };
          };
          hints.radius = 0;
          hints.border = "0px";
          keyhint.radius = 0;
          prompt.radius = 0;
        };
      };

      programs.qutebrowser.extraConfig = ''
        c.tabs.padding = {"top": 4, "bottom": 4, "left": 6, "right": 6}
        config.set("content.register_protocol_handler", True, "https://mail.proton.me")
        c.hints.selectors["scrollable"] = ["[data-qb-scroll]"]

        # Outlines like the GTK menus. These patch qutebrowser internals and may break on upgrades.
        from qutebrowser.mainwindow import mainwindow
        if not getattr(mainwindow, "_themed", False):
            mainwindow._themed = True
            from qutebrowser.mainwindow import mainwindow, prompt, messageview
            from qutebrowser.misc import keyhintwidget
            from qutebrowser.completion import completionwidget
            mainwindow.MainWindow.STYLESHEET += """
              QMenu { border: 1px solid ${bgSel}; padding: 4px 0; }
              QMenu::item { padding: 4px 12px; }
              QMenu::icon { padding-left: 8px; }
              QMenu::separator { height: 1px; background: ${bgSel}; margin: 4px 0; }
              QToolTip { border: 1px solid ${bgSel}; padding: 4px; }
            """
            prompt.PromptContainer.STYLESHEET += "QWidget#PromptContainer { border: 1px solid ${bgSel}; }"
            keyhintwidget.KeyHintView.STYLESHEET += "QLabel { border: 1px solid ${bgSel}; }"
            completionwidget.CompletionView.STYLESHEET += "QTreeView { border-top: 1px solid ${bgSel}; }"

            _message_init = messageview.Message.__init__
            def _outlined_message(self, *args, **kwargs):
                _message_init(self, *args, **kwargs)
                self.setStyleSheet(self.styleSheet() + "border: 1px solid ${bgSel}; padding: 2px 4px;")
            messageview.Message.__init__ = _outlined_message

            from qutebrowser.qt.gui import QIcon
            from qutebrowser.qt.webenginecore import QWebEnginePage
            from qutebrowser.browser.webengine import webview
            _menu_icons = {
                QWebEnginePage.WebAction.Back: "go-previous",
                QWebEnginePage.WebAction.Forward: "go-next",
                QWebEnginePage.WebAction.Reload: "view-refresh",
                QWebEnginePage.WebAction.Stop: "process-stop",
            }
            _context_menu = webview.WebEngineView.contextMenuEvent
            def _themed_context_menu(self, ev):
                for action, name in _menu_icons.items():
                    self.page().action(action).setIcon(QIcon("${menuIcons}/" + name + ".svg"))
                _context_menu(self, ev)
            webview.WebEngineView.contextMenuEvent = _themed_context_menu

        import os, shutil
        shutil.rmtree(os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "qute-bars"), ignore_errors=True)
      '';

      programs.zsh.shellAliases.qb = "qutebrowser";

      home.sessionVariables.BROWSER = "qutebrowser";

      custom.niri.binds."Mod+B" = [ "qutebrowser" ];

      xdg.mimeApps.defaultApplications = lib.genAttrs [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/about"
        "x-scheme-handler/unknown"
      ] (_: "org.qutebrowser.qutebrowser.desktop");
    };
}
