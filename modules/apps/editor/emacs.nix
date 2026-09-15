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

      # Wrapper script to launch ghostel terminal via emacsclient
      # Ghostel must be installed in Emacs (e.g., via straight.el from inputs.ghostel)
      # Usage: emacs-terminal [-e command] [--title name] [--directory dir]
      emacs-terminal = pkgs.writeShellScriptBin "emacs-terminal" ''
        # Parse arguments (simplified - ignores --title since Emacs handles frames differently)
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
              shift  # Skip title value, Emacs doesn't use it the same way
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
          # Run a command in ghostel
          exec ${pkgs.emacs-pgtk}/bin/emacsclient -c -e "(progn (cd \"$PWD\") (ghostel \"$CMD\"))"
        else
          # Just open a ghostel shell
          exec ${pkgs.emacs-pgtk}/bin/emacsclient -c -e "(progn (cd \"$PWD\") (ghostel))"
        fi
      '';
    in
    {
      options.custom.emacs = {
        enable = lib.mkEnableOption "Emacs editor with Ghostel terminal";
      };

      config = lib.mkIf cfg.enable {
        # Emacs with GTK3 + pure GTK for Wayland support
        programs.emacs = {
          enable = true;
          package = pkgs.emacs-pgtk;
          extraPackages =
            epkgs: with epkgs; [
              # ghostel - terminal emulator (install manually via straight.el or from source)
              evil
              evil-collection
              magit
              which-key
              vertico
              orderless
              marginalia
              consult
              corfu
              cape
              nix-mode
              markdown-mode
            ];
        };

        # Enable emacs daemon service (defaultEditor handles EDITOR/VISUAL env vars)
        services.emacs = {
          enable = true;
          startWithUserSession = "graphical";
          defaultEditor = true;
        };

        # Shell alias for launching emacsclient
        programs.bash.shellAliases = {
          ec = "emacsclient -c";
          et = "emacsclient -t";
        };

        programs.zsh.shellAliases = {
          ec = "emacsclient -c";
          et = "emacsclient -t";
        };

        # Add emacs-terminal wrapper to PATH
        home.packages = [ emacs-terminal ];

        # Set TERMINAL to use ghostel via emacsclient
        home.sessionVariables = {
          TERMINAL = "emacs-terminal";
        };

        # Desktop entry for emacsclient
        xdg.desktopEntries.emacsclient = {
          name = "Emacs Client";
          genericName = "Text Editor";
          comment = "Edit text with Emacs client";
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

        # Emacs init.el configuration
        xdg.configFile."emacs/init.el".text = ''
          ;; -*- lexical-binding: t -*-

          ;;; Startup Performance
          ;; Reduce garbage collection during startup
          (setq gc-cons-threshold most-positive-fixnum)
          (add-hook 'emacs-startup-hook
                    (lambda () (setq gc-cons-threshold (* 16 1024 1024))))

          ;;; Bootstrap straight.el
          (defvar bootstrap-version)
          (let ((bootstrap-file
                 (expand-file-name "straight/repos/straight.el/bootstrap.el"
                                   user-emacs-directory))
                (bootstrap-version 6))
            (unless (file-exists-p bootstrap-file)
              (with-current-buffer
                  (url-retrieve-synchronously
                   "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
                   'silent 'inhibit-cookies)
                (goto-char (point-max))
                (eval-print-last-sexp)))
            (load bootstrap-file nil 'nomessage))

          ;; Use straight.el with use-package
          (straight-use-package 'use-package)
          (setq straight-use-package-by-default t)

          ;;; Sensible Defaults
          (setq inhibit-startup-screen t
                inhibit-startup-message t
                inhibit-startup-echo-area-message t
                initial-scratch-message nil
                ring-bell-function 'ignore
                use-short-answers t
                confirm-kill-emacs 'y-or-n-p
                make-backup-files nil
                auto-save-default nil
                create-lockfiles nil
                custom-file (expand-file-name "custom.el" user-emacs-directory))

          ;; UTF-8 everywhere
          (set-language-environment "UTF-8")
          (prefer-coding-system 'utf-8)

          ;; Line numbers and visual settings
          (global-display-line-numbers-mode 1)
          (column-number-mode 1)
          (setq display-line-numbers-type 'relative)

          ;; Disable line numbers in certain modes
          (dolist (mode '(term-mode-hook
                          shell-mode-hook
                          eshell-mode-hook
                          vterm-mode-hook))
            (add-hook mode (lambda () (display-line-numbers-mode 0))))

          ;; Scrolling behavior
          (setq scroll-conservatively 101
                scroll-margin 3
                scroll-preserve-screen-position t)

          ;; Indentation
          (setq-default indent-tabs-mode nil
                        tab-width 4)

          ;; Show matching parentheses
          (show-paren-mode 1)
          (electric-pair-mode 1)

          ;; Recent files
          (recentf-mode 1)
          (setq recentf-max-saved-items 100)

          ;; Save place in files
          (save-place-mode 1)

          ;; Remember minibuffer history
          (savehist-mode 1)

          ;;; Theme - Modus Themes (built-in, dark mode)
          (require 'modus-themes)
          (setq modus-themes-italic-constructs t
                modus-themes-bold-constructs t
                modus-themes-mixed-fonts nil
                modus-themes-org-blocks 'tinted-background)
          (load-theme 'modus-vivendi t)

          ;;; Evil Mode
          (use-package evil
            :init
            (setq evil-want-integration t
                  evil-want-keybinding nil
                  evil-want-C-u-scroll t
                  evil-want-C-i-jump nil
                  evil-undo-system 'undo-redo
                  evil-respect-visual-line-mode t)
            :config
            (evil-mode 1)
            ;; Use visual line motions outside of visual-line-mode
            (evil-global-set-key 'motion "j" 'evil-next-visual-line)
            (evil-global-set-key 'motion "k" 'evil-previous-visual-line))

          (use-package evil-collection
            :after evil
            :config
            (evil-collection-init))

          ;;; Ghostel - Terminal Emulator
          (use-package ghostel
            :straight (ghostel :type git :host github :repo "dakra/ghostel")
            :commands (ghostel ghostel-project)
            :bind (("C-x m" . ghostel)
                   :map project-prefix-map
                   ("m" . ghostel-project))
            :init
            ;; Set default shell
            (setq ghostel-shell (or (getenv "SHELL") "/bin/bash"))
            :config
            ;; Evil integration for ghostel
            (with-eval-after-load 'evil
              (evil-set-initial-state 'ghostel-mode 'emacs)))

          ;;; Completion Framework - Vertico + Orderless + Marginalia + Consult
          (use-package vertico
            :init
            (vertico-mode 1)
            :config
            (setq vertico-cycle t
                  vertico-count 15))

          (use-package orderless
            :init
            (setq completion-styles '(orderless basic)
                  completion-category-defaults nil
                  completion-category-overrides '((file (styles partial-completion)))))

          (use-package marginalia
            :init
            (marginalia-mode 1))

          (use-package consult
            :bind (("C-s" . consult-line)
                   ("C-x b" . consult-buffer)
                   ("C-x 4 b" . consult-buffer-other-window)
                   ("C-x p b" . consult-project-buffer)
                   ("M-g g" . consult-goto-line)
                   ("M-g M-g" . consult-goto-line)
                   ("M-s r" . consult-ripgrep)
                   ("M-s f" . consult-find)
                   ("M-y" . consult-yank-pop))
            :config
            (setq consult-narrow-key "<"))

          ;;; In-buffer Completion - Corfu + Cape
          (use-package corfu
            :init
            (global-corfu-mode 1)
            :config
            (setq corfu-auto t
                  corfu-auto-delay 0.2
                  corfu-auto-prefix 2
                  corfu-cycle t
                  corfu-quit-no-match 'separator))

          (use-package cape
            :init
            (add-to-list 'completion-at-point-functions #'cape-file)
            (add-to-list 'completion-at-point-functions #'cape-dabbrev))

          ;;; Which-key - Keybinding Discovery
          (use-package which-key
            :init
            (which-key-mode 1)
            :config
            (setq which-key-idle-delay 0.3
                  which-key-prefix-prefix "+"
                  which-key-sort-order 'which-key-key-order-alpha))

          ;;; Magit - Git Integration
          (use-package magit
            :bind (("C-x g" . magit-status)
                   ("C-c g" . magit-dispatch))
            :config
            (setq magit-display-buffer-function
                  #'magit-display-buffer-same-window-except-diff-v1))

          ;;; Language Modes
          (use-package nix-mode
            :mode "\\.nix\\'")

          (use-package markdown-mode
            :mode (("README\\.md\\'" . gfm-mode)
                   ("\\.md\\'" . markdown-mode)
                   ("\\.markdown\\'" . markdown-mode))
            :init
            (setq markdown-command "markdown"))

          ;;; Additional Useful Settings
          ;; Better dired
          (setq dired-dwim-target t
                dired-listing-switches "-alh --group-directories-first")

          ;; Highlight current line
          (global-hl-line-mode 1)

          ;; Delete trailing whitespace on save
          (add-hook 'before-save-hook 'delete-trailing-whitespace)

          ;; Native compilation settings (if available)
          (when (featurep 'native-compile)
            (setq native-comp-async-report-warnings-errors nil
                  native-comp-deferred-compilation t))

          ;;; Load custom file if it exists
          (when (file-exists-p custom-file)
            (load custom-file 'noerror 'nomessage))

          (provide 'init)
          ;;; init.el ends here
        '';
      };
    };
}
