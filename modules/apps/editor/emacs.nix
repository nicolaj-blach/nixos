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
      emacs-terminal = pkgs.writeShellScriptBin "emacs-terminal" ''
        # Parse arguments
        CMD=""
        DIR=""
        while [[ $# -gt 0 ]]; do
          case "$1" in
            -e)
              shift
              CMD="$*"
              break
              ;;
            --title)
              shift
              shift
              ;;
            --directory)
              shift
              DIR="$1"
              shift
              ;;
            *)
              shift
              ;;
          esac
        done

        if [[ -n "$DIR" ]]; then
          cd "$DIR" || exit 1
        fi

        if [[ -n "$CMD" ]]; then
          exec emacsclient -c -e "(progn (cd \"$PWD\") (ghostel \"$CMD\"))"
        else
          exec emacsclient -c -e "(progn (cd \"$PWD\") (ghostel))"
        fi
      '';

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

      # Doom init.el - module configuration
      doomInitEl = ''
        ;;; init.el -*- lexical-binding: t; -*-

        ;; This file controls what Doom modules are enabled and what order they load
        ;; in. Remember to run 'doom sync' after modifying it!

        (doom! :input

               :completion
               company           ; Code completion (in-buffer suggestions)
               (vertico +icons)

               :ui
               doom
               dashboard
               hl-todo
               modeline
               ophints
               (popup +defaults)
               (vc-gutter +pretty)
               vi-tilde-fringe
               workspaces

               :editor
               (evil +everywhere)
               file-templates
               fold
               (format +onsave)
               snippets

               :emacs
               dired
               electric
               undo
               vc

               :term
               eshell

               :checkers
               syntax

               :tools
               docker            ; Docker/Podman management + Dockerfile editing
               (eval +overlay)
               lookup
               lsp
               magit

               :os
               (:if (featurep :system 'macos) macos)

               :lang
               (cc +lsp +tree-sitter)              ; C/C++ with clangd
               (csharp +lsp +dotnet +tree-sitter)  ; C#
               data                                 ; CSV, TOML, XML, etc.
               emacs-lisp
               (go +lsp +tree-sitter)              ; Go with gopls
               graphql                              ; GraphQL schemas
               (haskell +lsp +tree-sitter)         ; Haskell with HLS
               (javascript +lsp +tree-sitter)      ; JS/TS/React/JSX/TSX
               (json +lsp +tree-sitter)
               (latex +lsp +fold)                  ; LaTeX with texlab
               (lua +lsp +tree-sitter)             ; Lua with lua-language-server
               (markdown +grip +lsp)               ; Markdown with marksman LSP
               (nix +lsp +tree-sitter)
               (org +pretty +roam2)                ; Org mode (jupyter via devenv)
               (python +lsp +pyright +tree-sitter) ; Python with pyright
               (rust +lsp +tree-sitter)            ; Rust with rust-analyzer
               (sh +lsp +tree-sitter)
               (web +lsp +tree-sitter)             ; HTML/CSS/Tailwind
               (yaml +lsp +tree-sitter)
               (zig +lsp +tree-sitter)             ; Zig with zls

               :config
               (default +bindings +smartparens))
      '';

      # Doom packages.el - external packages
      doomPackagesEl = ''
        ;; -*- no-byte-compile: t; -*-
        ;;; packages.el

        ;; Ghostel terminal emulator (from local source)
        (package! ghostel :recipe (:local-repo "~/.local/share/ghostel"))

        ;; Ghostel extensions
        (package! evil-ghostel)

        ;; Base16 themes (exact OneDark colors matching Kitty/Quickshell)
        (package! base16-theme)

        ;; Direnv integration (per-buffer environments for project-local LSPs)
        (package! envrc)

        ;; Typst support (not built into Doom yet)
        (package! typst-ts-mode :recipe (:host github :repo "Ziqi-Yang/typst-ts-mode"))
      '';

      # Doom config.el - user configuration
      doomConfigEl = ''
        ;;; config.el -*- lexical-binding: t; -*-

        ;;; User Info
        (setq user-full-name ""
              user-mail-address "")

        ;;; Theme & UI
        ;; Use base16-onedark to match Kitty/Quickshell exactly
        (setq doom-theme 'base16-onedark
              doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 16)
              doom-variable-pitch-font (font-spec :family "sans-serif" :size 16))

        ;; Disable solaire-mode for consistent background color
        (after! solaire-mode
          (solaire-global-mode -1))

        ;; Remove fringes (the light gray lines on left/right)
        (set-fringe-mode 0)

        ;; Line numbers
        (setq display-line-numbers-type 'relative)

        ;; Scrolling behavior
        (setq scroll-conservatively 101
              scroll-margin 3
              scroll-preserve-screen-position t)

        ;;; Org Mode
        (setq org-directory "~/org/")

        ;;; Editor Settings
        ;; Indentation
        (setq-default indent-tabs-mode nil
                      tab-width 4)

        ;; Better defaults
        (setq confirm-kill-emacs nil)  ; Doom already has safeguards

        ;;; Ghostel Terminal Configuration
        (use-package! ghostel
          :commands (ghostel ghostel-project)
          :init
          (setq ghostel-shell (or (getenv "SHELL") "/bin/bash"))
          :config
          ;; Keybindings
          (map! :leader
                :desc "Open terminal" "o t" #'ghostel
                :desc "Project terminal" "p t" #'ghostel-project)
          ;; Add magit to allowed eval commands
          (add-to-list 'ghostel-eval-cmds '("magit-status-setup-buffer" magit-status-setup-buffer)))

        ;; Evil integration for Ghostel
        (use-package! evil-ghostel
          :after (ghostel evil)
          :hook (ghostel-mode . evil-ghostel-mode))

        ;; Org link type for Ghostel (built into ghostel package)
        (use-package! ghostel-org
          :after org)

        ;;; Additional Keybindings
        ;; Quick access to common commands
        (map! :leader
              :desc "Find file in project" "SPC" #'projectile-find-file)

        ;;; Performance
        ;; Increase garbage collection threshold
        (setq gc-cons-threshold (* 100 1024 1024))  ; 100MB

        ;; LSP performance settings
        (after! lsp-mode
          (setq lsp-idle-delay 0.5
                lsp-log-io nil))

        ;;; Direnv Integration (envrc)
        ;; Enables per-buffer direnv environments for project-local LSPs
        ;; When you open a file in a direnv-enabled project, envrc will
        ;; automatically load that project's environment (including LSP servers)
        (use-package! envrc
          :hook (after-init . envrc-global-mode)
          :config
          ;; Show envrc status in minibuffer when environment changes
          (setq envrc-show-summary-in-minibuffer t)
          ;; Keybindings for manual control
          (map! :leader
                :prefix ("e" . "envrc")
                :desc "Allow .envrc" "a" #'envrc-allow
                :desc "Deny .envrc" "d" #'envrc-deny
                :desc "Reload env" "r" #'envrc-reload
                :desc "Show env" "s" #'envrc-show))

        ;;; C# LSP Configuration
        ;; csharp-ls will be auto-detected from $PATH when provided by devenv
        ;; No need to set lsp-csharp-server-path - it uses PATH automatically
        (after! lsp-csharp
          ;; Prefer csharp-ls from PATH over downloading omnisharp
          (setq lsp-csharp-server-path nil))

        ;;; JavaScript/TypeScript Configuration
        (after! lsp-javascript
          ;; Use project-local tsserver when available (via devenv)
          (setq lsp-clients-typescript-prefer-use-project-ts-server t))

        ;;; Rust Configuration
        (after! rustic
          ;; Use rust-analyzer from PATH (via rustup or devenv)
          (setq rustic-lsp-server 'rust-analyzer))

        ;;; Python Configuration
        (after! lsp-pyright
          ;; Pyright settings
          (setq lsp-pyright-typechecking-mode "basic"))

        ;;; Web Mode (HTML/CSS/JSX/TSX)
        (after! web-mode
          ;; Better defaults for JSX/TSX
          (setq web-mode-markup-indent-offset 2
                web-mode-css-indent-offset 2
                web-mode-code-indent-offset 2
                web-mode-enable-auto-quoting nil))

        ;;; Tailwind CSS
        ;; Enable Tailwind LSP for relevant file types
        (after! lsp-tailwindcss
          (setq lsp-tailwindcss-add-on-mode t))

        ;;; Format on save exceptions
        ;; Disable format-on-save for certain modes if needed
        ;; (setq +format-on-save-disabled-modes '(sql-mode))

        ;;; Go Configuration
        (after! go-mode
          ;; Use goimports for auto-imports on format
          (setq gofmt-command "goimports"))

        ;;; Zig Configuration
        (after! zig-mode
          ;; zls is auto-detected from PATH
          (setq lsp-zig-zls-executable (executable-find "zls")))

        ;;; Lua Configuration
        (after! lua-mode
          ;; lua-language-server is auto-detected from PATH
          )

        ;;; Typst Configuration
        (use-package! typst-ts-mode
          :mode "\\.typ\\'"
          :config
          ;; Enable LSP for Typst (tinymist)
          (add-hook 'typst-ts-mode-hook #'lsp!))

        ;;; LaTeX Configuration
        ;; texlab LSP is auto-detected from PATH
        ;; Full texlive should be installed via devenv per-project
        (after! tex
          ;; Use pdf-tools for viewing if available, otherwise zathura
          (setq +latex-viewers '(pdf-tools zathura evince)))

        ;;; Docker/Podman Configuration
        ;; docker.el works with both Docker and Podman
        (after! docker
          ;; Both docker and podman available - docker is default
          ;; To use podman, set these:
          ;; (setq docker-command "podman")
          ;; (setq docker-compose-command "podman-compose")
          )

        ;;; GraphQL Configuration
        ;; graphql-language-service-cli is auto-detected from PATH
      '';
    in
    {
      options.custom.emacs = {
        enable = lib.mkEnableOption "Doom Emacs with Ghostel terminal";
      };

      config = lib.mkIf cfg.enable {
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
        xdg.configFile."doom/init.el".text = doomInitEl;
        xdg.configFile."doom/packages.el".text = doomPackagesEl;
        xdg.configFile."doom/config.el".text = doomConfigEl;

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
