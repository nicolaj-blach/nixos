{ inputs, ... }:

{
  flake.nixosModules.pi-coding-agent = { ... }: { };

  # pi from llm-agents.nix, configured through Home Manager's pi module. ~/.pi/agent
  # is read-only; markdown (AGENTS.md, agents, skills) lives in agent-markdown-files.
  flake.homeManagerModules.pi-coding-agent =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.pi-coding-agent;
      md = inputs.agent-markdown-files;
      json = pkgs.formats.json { };
      pi = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

      # pi-vim only outside Emacs: inside ghostel, evil owns Esc
      piVim = pkgs.writeShellScriptBin "pi" ''
        [ -n "''${INSIDE_EMACS:-}" ] || set -- -e npm:pi-vim@0.14.2 "$@"
        exec ${lib.getExe pi} "$@"
      '';

      # Ctrl+G: the current Emacs frame inside ghostel, a new frame elsewhere
      editor = pkgs.writeShellScript "pi-editor" ''
        [ -n "''${INSIDE_EMACS:-}" ] && exec emacsclient "$@"
        exec emacsclient -c "$@"
      '';
    in
    {
      imports = [ ./_hm-module.nix ];

      config = lib.mkIf cfg.enable {
        programs.pi-coding-agent = {
          package = piVim;
          extraPackages = [ pkgs.nodejs ];
          context = "${md}/AGENTS.md";

          settings = {
            theme = "onedark";
            externalEditor = "${editor}";
            quietStartup = true;
            collapseChangelog = true;
            enableInstallTelemetry = false;
            doubleEscapeAction = "none";
            piVim.clipboardMirror = "all";
            skills = [ "${md}/skills" ];
            # Installed by pi into ~/.pi/agent/npm on first start
            packages = [
              "npm:pi-subagents@0.75.0"
              "npm:pi-web-access@0.35.0"
              "npm:@juicesharp/rpiv-ask-user-question@2.12.0"
              "npm:@juicesharp/rpiv-todo@2.12.0"
              "npm:pi-lens@4.3.0"
              "npm:@gotgenes/pi-permission-system@39.0.3"
              "npm:plan-mode-lite@0.1.7"
              "npm:pi-powerline-footer@0.19.1"
            ];
          };

          # Shift+Tab toggles plan mode
          keybindings."app.thinking.cycle" = "ctrl+t";
        };

        home.file = {
          ".pi/agent/themes/onedark.json".source = ./_files/onedark.json;
          # User scope, so same-name agents (reviewer) replace pi-subagents' built-ins
          ".pi/agent/agents".source = "${md}/agents";
          ".pi/agent/plan-mode-lite.json".source = json.generate "plan-mode-lite.json" {
            defaultOn = false;
            toggleShortcut = "shift+tab";
          };
          # Last match wins inside each map; across layers deny beats ask beats allow
          ".pi/agent/extensions/pi-permission-system/config.json".source =
            json.generate "pi-permissions.json"
              {
                permission = {
                  "*" = "allow";
                  path = {
                    "*" = "allow";
                    "~/.ssh/*" = "deny";
                    "~/.gnupg/*" = "deny";
                    "~/.config/sops/*" = "deny";
                    "/run/secrets/*" = "deny";
                    "/run/secrets.d/*" = "deny";
                    "*.env" = "deny";
                    "*.env.*" = "deny";
                    "*.env.example" = "allow";
                  };
                  bash = {
                    "*" = "allow";
                    "rm -r *" = "ask";
                    "rm -rf *" = "ask";
                    "rm -fr *" = "ask";
                    "rm -R *" = "ask";
                    "sudo *" = "ask";
                    "git push*" = "ask";
                    "git reset --hard*" = "ask";
                    "git clean*" = "ask";
                    "git checkout -- *" = "ask";
                    "npm install -g *" = "ask";
                    "npm i -g *" = "ask";
                    "pip install *" = "ask";
                    "cargo install *" = "ask";
                    "go install *" = "ask";
                    "nix profile install *" = "ask";
                  };
                  external_directory = {
                    "*" = "ask";
                    "~/nixos/*" = "allow";
                    "~/projects/personal/agent-markdown-files/*" = "allow";
                    "/tmp/*" = "allow";
                    "/nix/store/*" = "allow";
                  };
                };
              };
        };

        programs.zsh.shellAliases.agent = "pi";
      };
    };
}
