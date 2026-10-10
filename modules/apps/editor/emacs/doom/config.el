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
(setq org-directory "~/notes/")

;;; Editor Settings
;; Indentation
(setq-default indent-tabs-mode nil
              tab-width 4)

;; Better defaults
(setq confirm-kill-emacs nil)  ; Doom already has safeguards

;;; Ghostel terminal
(load! "+ghostel" doom-user-dir)

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
