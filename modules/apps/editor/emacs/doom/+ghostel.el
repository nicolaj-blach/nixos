;;; +ghostel.el -*- lexical-binding: t; -*-

(use-package! ghostel
  :commands (ghostel ghostel-project)
  :init
  (setq ghostel-shell (or (getenv "SHELL") "/bin/bash"))
  ;; Name buffers after the terminal title (running command, cwd or pi's state)
  (setq ghostel-buffer-name-function #'identity)
  :config
  ;; Clear inherited DIRENV_* vars so direnv in the shell actually
  ;; re-runs instead of silently no-oping (taken from Doom's :term ghostel)
  (add-hook 'ghostel-pre-spawn-hook
            (defun +ghostel-strip-direnv-initvars-h (&rest _)
              (when (getenv "DIRENV_FILE")
                (setq-local process-environment
                            (seq-remove (lambda (v) (string-prefix-p "DIRENV_" v))
                                        process-environment)))))
  ;; Add magit to allowed eval commands
  (add-to-list 'ghostel-eval-cmds '("magit-status-setup-buffer" magit-status-setup-buffer))
  ;; Let C-<insert> (Super+C via kanata) reach Emacs as copy instead of the shell.
  ;; setopt so ghostel rebuilds its keymap.
  (setopt ghostel-keymap-exceptions
          (append ghostel-keymap-exceptions '("C-<insert>" "C-S-y")))
  (map! :map ghostel-mode-map
        :n "gY" #'+ghostel/copy-last-output
        :i "C-S-y" #'+ghostel/copy-last-output)
  ;; C-c C-k: enter char mode (all keys to terminal; exit with M-RET)
  (define-key ghostel-mode-map (kbd "C-c C-k") #'ghostel-char-mode)
  ;; SPC m k (localleader): only exists in ghostel buffers, no conflicts
  (map! :map ghostel-mode-map
        :localleader
        :desc "Char mode" "k" #'ghostel-char-mode))

;; Finishing an emacsclient edit (pi's Ctrl+G) must not kill the frame's
;; workspace (and the ghostel buffer in it); frame deletion still does.
(after! persp-mode
  (remove-hook 'server-done-hook #'+workspaces-delete-associated-workspace-h))

;; :q / :wq / ZZ in emacsclient buffers finish the edit instead of closing the frame
(defadvice! +server-edit-instead-of-quit-a (fn &rest args)
  :around #'evil-quit
  (if (bound-and-true-p server-buffer-clients)
      (server-edit)
    (apply fn args)))

(defun +ghostel/copy-last-output ()
  "Copy the output of the last finished command in this ghostel buffer."
  (interactive)
  (cond
   ((and ghostel--term (ghostel--alt-screen-p ghostel--term))
    (message "Full-screen app running, no command output to copy"))
   (ghostel--command-running
    (message "Command still running"))
   (t
    (save-excursion
      (let* ((last (let ((p (point-max)))
                     (while (and (> p (point-min))
                                 (not (get-text-property (1- p) 'ghostel-prompt)))
                       (setq p (previous-single-property-change p 'ghostel-prompt nil (point-min))))
                     (and (> p (point-min)) (1- p))))
             (end (when last
                    (goto-char last)
                    (beginning-of-line)
                    (while (and (> (point) (point-min))
                                (save-excursion
                                  (forward-line -1)
                                  (get-text-property (point) 'ghostel-prompt)))
                      (forward-line -1))
                    (point)))
             (start (when end
                      (let ((p end))
                        (while (and (> p (point-min))
                                    (not (or (get-text-property (1- p) 'ghostel-input)
                                             (get-text-property (1- p) 'ghostel-prompt))))
                          (setq p (previous-property-change p nil (point-min))))
                        (when (> p (point-min))
                          (goto-char (1- p))
                          (forward-line 1)
                          (point)))))
             (text (and start (< start end)
                        (string-trim-right
                         (ghostel--clean-copy-text
                          (buffer-substring-no-properties start end))))))
        (if (and text (not (string-empty-p text)))
            (progn
              (kill-new text)
              (message "Copied %d lines of output" (1+ (cl-count ?\n text))))
          (message "No previous output")))))))

(defun +ghostel/new ()
  "Always open a new ghostel terminal (same as SPC u SPC o t)."
  (interactive)
  (ghostel '(4)))

(defun +ghostel/popup-toggle (&optional arg)
  "Show/hide a persistent ghostel popup at the project root.
Each project gets its own popup; hiding keeps the shell running.
With prefix ARG, kill and recreate it."
  (interactive "P")
  (let* ((default-directory (or (doom-project-root) default-directory))
         ;; The *doom:ghostel-popup* prefix matches Doom's built-in popup
         ;; rule: bottom, 35% height, stays open, not auto-killed.
         (name (format "*doom:ghostel-popup:%s*"
                       (or (doom-project-name)
                           (file-name-nondirectory
                            (directory-file-name default-directory)))))
         (buf (get-buffer name)))
    (when (and arg (buffer-live-p buf))
      (let (confirm-kill-processes kill-buffer-query-functions)
        (kill-buffer buf))
      (setq buf nil))
    (if-let* ((win (and buf (get-buffer-window buf))))
        (delete-window win)
      ;; dlet: ghostel may not be loaded yet, so force dynamic binding
      (dlet ((ghostel-buffer-name name)
             (ghostel-buffer-name-function nil))
        (with-current-buffer (ghostel)
          ;; Don't let ghostel rename it, or the popup rule stops matching
          (setq-local ghostel-buffer-name-function nil)
          (current-buffer))))))

(map! :leader
      :desc "Open terminal"         "o t" #'ghostel
      :desc "New terminal"          "o T" #'+ghostel/new
      :desc "Toggle terminal popup" "o p" #'+ghostel/popup-toggle
      :desc "Project terminal"      "p t" #'ghostel-project
      :desc "Switch terminal"       "b t" #'consult-ghostel)

(use-package! consult-ghostel
  :commands (consult-ghostel consult-ghostel-project))

;; Treat ghostel buffers as "real" so they show up in SPC b b / SPC ,
;; and buffer cycling ([b / ]b) instead of being hidden like *special* buffers
(add-to-list 'doom-real-buffer-modes 'ghostel-mode)

;; Evil integration for Ghostel
(use-package! evil-ghostel
  :after (ghostel evil)
  :hook (ghostel-mode . evil-ghostel-mode)
  :init
  ;; ESC always goes to Evil (insert -> normal) in every new ghostel
  ;; buffer, even in vim/less/TUIs. Toggle per buffer with C-c C-r.
  (setq evil-ghostel-escape 'evil)
  :config
  ;; Double ESC: the first goes to normal state, a quick second one sends
  ;; ESC to the terminal (e.g. to cancel in pi) and returns to insert state.
  (defvar +ghostel-double-escape-timeout 0.3)
  (defvar-local +ghostel--last-escape nil)
  (defun +ghostel/escape-insert ()
    (interactive)
    (setq +ghostel--last-escape (float-time))
    (call-interactively #'evil-ghostel--escape))
  (defun +ghostel/escape-normal ()
    (interactive)
    (if (and +ghostel--last-escape
             (< (- (float-time) +ghostel--last-escape)
                +ghostel-double-escape-timeout))
        (progn
          (setq +ghostel--last-escape nil)
          (evil-insert-state)
          (ghostel--on-user-input)
          (ghostel--send-encoded "escape" ""))
      (setq +ghostel--last-escape nil)
      (let ((cmd (lookup-key evil-normal-state-map [escape])))
        (call-interactively (if (commandp cmd) cmd #'doom/escape)))))
  (map! :map evil-ghostel-mode-map
        :i "<escape>" #'+ghostel/escape-insert
        :n "<escape>" #'+ghostel/escape-normal))

;; Relative line numbers in ghostel only while navigating (normal/visual),
;; hidden while typing (insert/emacs state). Applies to popup and full window.
(defun +ghostel-line-numbers-on-h ()
  (setq-local display-line-numbers 'relative))
(defun +ghostel-line-numbers-off-h ()
  (setq-local display-line-numbers nil))
(add-hook 'ghostel-mode-hook
          (defun +ghostel-setup-line-numbers-h ()
            (add-hook 'evil-normal-state-entry-hook #'+ghostel-line-numbers-on-h nil t)
            (add-hook 'evil-insert-state-entry-hook #'+ghostel-line-numbers-off-h nil t)
            (add-hook 'evil-emacs-state-entry-hook #'+ghostel-line-numbers-off-h nil t)))

;; Org link type for Ghostel (built into ghostel package)
(use-package! ghostel-org
  :after org)
