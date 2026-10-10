;; -*- no-byte-compile: t; -*-
;;; packages.el

;; Ghostel terminal emulator (from local source)
(package! ghostel :recipe (:local-repo "~/.local/share/ghostel"))

;; Ghostel extensions
(package! evil-ghostel)
;; Terminal picker with live preview (from the same local ghostel source)
(package! consult-ghostel
  :recipe (:local-repo "~/.local/share/ghostel"
           :files ("extensions/consult-ghostel/*.el")))

;; Base16 themes (exact OneDark colors matching Kitty/Quickshell)
(package! base16-theme)

;; Direnv integration (per-buffer environments for project-local LSPs)
(package! envrc)

;; Typst support (not built into Doom yet)
(package! typst-ts-mode :recipe (:host github :repo "Ziqi-Yang/typst-ts-mode"))
