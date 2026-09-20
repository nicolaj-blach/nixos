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
               (eval +overlay)
               lookup
               lsp
               magit

               :os
               (:if (featurep :system 'macos) macos)

               :lang
               emacs-lisp
               (json +lsp)
               (markdown +grip)
               (nix +lsp)
               (org +pretty +roam2)
               (sh +lsp)
               (yaml +lsp)

               :config
               (default +bindings +smartparens))
      '';

      # Doom packages.el - external packages
      doomPackagesEl = ''
        ;; -*- no-byte-compile: t; -*-
        ;;; packages.el

        ;; Ghostel terminal emulator (from local source)
        (package! ghostel :recipe (:local-repo "~/.local/share/ghostel"))

        ;; Base16 themes (exact OneDark colors matching Kitty/Quickshell)
        (package! base16-theme)
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
              doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 14)
              doom-variable-pitch-font (font-spec :family "sans-serif" :size 14))

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
          ;; Evil integration - use emacs state in ghostel
          (after! evil
            (evil-set-initial-state 'ghostel-mode 'emacs)))

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
          shellcheck # For shell script linting
          nixfmt-rfc-style # For nix formatting
          nil # Nix LSP

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
