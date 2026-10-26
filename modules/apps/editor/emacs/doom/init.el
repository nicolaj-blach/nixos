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

       :email
       (mu4e +org +mbsync)

       :config
       (default +bindings +smartparens))
