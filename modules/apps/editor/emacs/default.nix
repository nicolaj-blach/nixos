{ inputs, ... }:
{
  flake.homeManagerModules.emacs =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.custom.emacs;

      # Ghostel source from flake input
      ghostelSource = inputs.ghostel;

      # Wrapper script to launch ghostel terminal via emacsclient
      emacs-terminal = pkgs.writeShellScriptBin "emacs-terminal" (builtins.readFile ./emacs-terminal.sh);

      # Wrapper script to run doom CLI
      doom-cli = pkgs.writeShellScriptBin "doom" ''
        exec "$HOME/.config/emacs/bin/doom" "$@"
      '';

      # Script to install Doom Emacs (clones from git if not present)
      doom-install = pkgs.writeShellScriptBin "doom-install" ''
        set -e
        DOOM_DIR="$HOME/.config/emacs"

        if [ ! -d "$DOOM_DIR" ]; then
          echo "Installing Doom Emacs..."
          ${pkgs.git}/bin/git clone --depth 1 https://github.com/doomemacs/doomemacs "$DOOM_DIR"
          echo "Doom Emacs installed. Run 'doom install' or 'doom sync' to complete setup."
        else
          echo "Doom Emacs is already installed at $DOOM_DIR"
        fi
      '';
    in
    {
      options.custom.emacs = {
        enable = lib.mkEnableOption "Doom Emacs with Ghostel terminal";
      };

      config = lib.mkIf cfg.enable {
        custom.niri.binds."Mod+Return" = [ "emacs-terminal" ];

        # Emacs package with native compilation
        programs.emacs = {
          enable = true;
          package = pkgs.emacs-pgtk;
        };

        # System dependencies for Doom Emacs
        home.packages = with pkgs; [
          # Core dependencies
          git
          ripgrep
          fd
          coreutils

          # Optional but recommended
          sqlite # For org-roam
          graphviz # For org-roam graph
          pandoc # For markdown export

          # LSP Servers (global - always available)
          # Nix
          nil # Nix LSP
          nixfmt-rfc-style # Nix formatting

          # Shell
          shellcheck # Shell script linting
          nodePackages.bash-language-server

          # Web (HTML/CSS/JS/TS)
          nodePackages.typescript-language-server # JS/TS LSP
          nodePackages.vscode-langservers-extracted # HTML/CSS/JSON LSP
          tailwindcss-language-server # Tailwind CSS
          emmet-ls # Emmet for HTML/JSX

          # C/C++
          clang-tools # clangd LSP + clang-format

          # Python
          pyright # Python LSP (fast, type-focused)
          ruff # Python linter/formatter

          # Rust (rust-analyzer typically via rustup/devenv, but can have fallback)
          # rust-analyzer # Uncomment for global install

          # Haskell (HLS is large, better via devenv per-project)
          # haskell-language-server # Uncomment for global install

          # YAML/TOML
          yaml-language-server
          taplo # TOML LSP

          # Go
          gopls # Go LSP
          gotools # goimports, etc.

          # Zig
          zls # Zig LSP

          # Lua
          lua-language-server # Lua LSP

          # LaTeX (LSP only - full texlive via devenv per-project)
          texlab # LaTeX LSP

          # Typst
          typst # Typst compiler
          tinymist # Typst LSP

          # GraphQL
          graphql-language-service-cli # GraphQL LSP

          # Markdown
          marksman # Markdown LSP (wiki links, references)

          # Docker/Containers
          dockerfile-language-server-nodejs # Dockerfile LSP
          hadolint # Dockerfile linter
          docker-compose-language-service # docker-compose LSP

          # Helper scripts
          emacs-terminal
          doom-install
          doom-cli
        ];

        # Activation script to install Doom Emacs (clones from git if not present)
        home.activation.installDoomEmacs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${doom-install}/bin/doom-install
        '';

        # Create Doom configuration directory (these are managed by Nix)
        xdg.configFile."doom" = {
          source = ./doom;
          recursive = true;
        };

        # Symlink ghostel source for Doom to find
        xdg.dataFile."ghostel".source = ghostelSource;

        # Add doom binary to PATH
        home.sessionPath = [ "$HOME/.config/emacs/bin" ];

        # Emacs daemon service
        services.emacs = {
          enable = true;
          startWithUserSession = "graphical";
          defaultEditor = true;
        };

        # Shell aliases
        programs.bash.shellAliases = {
          ec = "emacsclient -c";
          et = "emacsclient -t";
          doom = "~/.config/emacs/bin/doom";
        };

        programs.zsh.shellAliases = {
          ec = "emacsclient -c";
          et = "emacsclient -t";
          doom = "~/.config/emacs/bin/doom";
        };

        # Session variables
        home.sessionVariables = {
          TERMINAL = "emacs-terminal";
          DOOMDIR = "$HOME/.config/doom";
        };

        # Desktop entry for Emacs client
        xdg.desktopEntries.emacsclient = {
          name = "Emacs Client";
          genericName = "Text Editor";
          comment = "Edit text with Doom Emacs";
          exec = "emacsclient -c %F";
          icon = "emacs";
          terminal = false;
          type = "Application";
          categories = [
            "Development"
            "TextEditor"
            "Utility"
          ];
          mimeType = [
            "text/plain"
            "text/x-chdr"
            "text/x-csrc"
          ];
        };
      };
    };
}
