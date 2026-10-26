;;; +notes.el -*- lexical-binding: t; -*-
;; FLAP notes after No Boilerplate's "Obsidian for Learning": fleeting,
;; literature, atomic, projects and tasks. The folder is the note type.

(setq org-directory "~/notes/"
      org-roam-directory "~/notes/"
      org-agenda-files '("~/notes/tasks/" "~/notes/projects/" "~/notes/daily/"))

(dolist (dir '("fleeting" "literature" "atomic" "projects" "tasks" "daily"))
  (make-directory (expand-file-name dir org-directory) t))

(defvar +org-capture-fn)
(defvar org-capture-initial)
(defvar +notes--parent nil "Node the next task capture goes under, instead of asking.")

;;; Notes from the org-roam database

(defun +notes--type (file)
  (file-name-nondirectory (directory-file-name (file-name-directory file))))

(defun +notes--today (&optional days)
  (format-time-string "%Y-%m-%d" (time-add nil (days-to-time (or days 0)))))

(defun +notes--nodes (&rest types)
  (seq-filter (lambda (n) (and (= 0 (org-roam-node-level n))
                               (member (+notes--type (org-roam-node-file n)) types)))
              (org-roam-node-list)))

(defun +notes--prop (node prop) (cdr (assoc prop (org-roam-node-properties node))))

(defun +notes--up-id (node)
  (when-let* ((up (+notes--prop node "UP")) ((string-match "id:\\([^]]+\\)" up)))
    (match-string 1 up)))

(defun +notes--children (nodes id)
  (seq-filter (lambda (n) (equal (+notes--up-id n) id)) nodes))

(defun +notes--walk (nodes roots &optional depth)
  "List of (DEPTH . NODE) for ROOTS and their UP descendants."
  (mapcan (lambda (n)
            (cons (cons (or depth 0) n)
                  (+notes--walk nodes (+notes--children nodes (org-roam-node-id n)) (1+ (or depth 0)))))
          (sort roots :key #'org-roam-node-title)))

(defun +notes--link (node)
  (and node (org-link-make-string (concat "id:" (org-roam-node-id node)) (org-roam-node-title node))))

(defun +notes--pick (prompt &rest types)
  "Pick a note from the TYPES folders; nil on empty input."
  (let* ((ids (mapcar #'org-roam-node-id (apply #'+notes--nodes types)))
         (n (org-roam-node-read nil (lambda (n) (member (org-roam-node-id n) ids)) nil t prompt)))
    (and (org-roam-node-id n) n)))

(defun +notes--project-of (up)
  (when up
    (if (equal (+notes--type (org-roam-node-file up)) "projects")
        (+notes--link up)
      (+notes--prop up "PROJECT"))))

;;; Capture templates. ${fn} calls fn with the node; it must return a string.

(defun +notes--drawer (&rest props)
  (concat ":PROPERTIES:\n"
          (cl-loop for (k v) on props by #'cddr when v concat (format ":%s: %s\n" k v))
          ":END:\n"))

(defun +notes-head-fleeting (_) (+notes--drawer "REVIEW" (+notes--today 1)))

(defun +notes-head-literature (_)
  (let ((url (read-string "URL (empty for none): ")))
    (+notes--drawer "ROAM_REFS" (and (not (string-empty-p url)) url))))

(defun +notes-head-atomic (_)
  (+notes--drawer "UP" (+notes--link (+notes--pick "UP (empty for none): " "atomic"))))

(defun +notes-head-task (_)
  (let ((up (or +notes--parent (+notes--pick "Project or parent task: " "projects" "tasks"))))
    (+notes--drawer "UP" (+notes--link up) "PROJECT" (+notes--project-of up))))

(defun +notes-deadline (&optional _)
  (let ((due (read-string "Due (empty for none, e.g. +2w): ")))
    (if (string-empty-p due) ""
      (format-time-string "DEADLINE: <%Y-%m-%d %a>\n" (org-read-date nil t due)))))

(setq org-roam-capture-templates
      '(("f" "fleeting" plain "#+begin_quote\n%i%?\n#+end_quote"
         :target (file+head "fleeting/${slug}.org" "${+notes-head-fleeting}#+title: ${title}\n")
         :unnarrowed t)
        ("l" "literature" plain "%?"
         :target (file+head "literature/${slug}.org"
                            "${+notes-head-literature}#+title: ${title}\n#+filetags: :unfiled:\n")
         :unnarrowed t)
        ("a" "atomic" plain "%?\n\n* See also\n\n* References\n"
         :target (file+head "atomic/${slug}.org" "${+notes-head-atomic}#+title: ${title}\n")
         :unnarrowed t)
        ("p" "project" entry "* PROJ ${title}\n${+notes-deadline}** Tasks\n#+begin: tasks\n#+end:\n** Notes\n%?"
         :target (file+head "projects/${slug}.org" "#+title: ${title}\n")
         :unnarrowed t)
        ("t" "task" entry "* TODO ${title}\n${+notes-deadline}%?"
         :target (file+head "tasks/${slug}.org" "${+notes-head-task}#+title: ${title}\n")
         :unnarrowed t))
      org-roam-dailies-capture-templates
      '(("d" "default" entry "* %<%H:%M> %?"
         :target (file+head+olp "%<%Y-%m-%d>.org"
                                "#+title: %<%Y-%m-%d>\n* Win the day\n- [ ] \n* Tasks\n* Log\n"
                                ("Log")))))

(after! org-roam
  (setq org-roam-node-display-template
        (format "%s ${doom-hierarchy:*} %s"
                (propertize "${doom-type:10}" 'face 'font-lock-keyword-face)
                (propertize "${doom-tags:20}" 'face '(:inherit org-tag :box nil)))))

(defun +notes--capture (key title)
  (require 'org-roam)
  (org-roam-capture- :keys key :node (org-roam-node-create :title title)))

(defun +notes/fleeting (&optional title initial)
  "Capture a fleeting note; the region or INITIAL goes in the quote."
  (interactive)
  (let ((title (read-string "Fleeting: " title))
        (org-capture-initial (or initial org-capture-initial)))
    (+notes--capture "f" title)))

(defun +notes/capture-frame ()
  "Fleeting capture in a floating frame that closes when done (Mod+I)."
  (let ((+org-capture-fn #'+notes/fleeting))
    (+org-capture/open-frame)))

;;; Editing the note in the current buffer

(defun +notes--title () (cadar (org-collect-keywords '("TITLE"))))

(defun +notes--retype (title props)
  "Drop REVIEW, set TITLE and PROPS, and leave point after the keywords."
  (org-entry-delete (point-min) "REVIEW")
  (cl-loop for (k v) on props by #'cddr when v do (org-entry-put (point-min) k v))
  (org-roam-set-keyword "title" title)
  (goto-char (point-min))
  (re-search-forward "^#\\+title:.*\n")
  (while (looking-at "^#\\+[[:alnum:]_]+:") (forward-line 1)))

(defun +notes--move (type title)
  "Save, then move the visited note to TYPE/<slug of TITLE>.org and visit it."
  (let ((old buffer-file-name)
        (new (expand-file-name (concat type "/" (org-roam-node-slugify title) ".org") org-roam-directory)))
    (when (file-exists-p new) (user-error "%s already exists" new))
    (save-buffer)
    (kill-buffer)
    (rename-file old new)
    (find-file new)))

(defun +notes/status ()
  "Cycle the task state: TODO, STRT (doing), DONE. Projects: PROJ, DONE."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (outline-next-heading)
    (org-todo (pcase (org-get-todo-state)
                ("TODO" "STRT") ("STRT" "DONE") ("PROJ" "DONE")
                (_ (if (equal (+notes--type buffer-file-name) "projects") "PROJ" "TODO")))))
  (save-buffer))

(defun +notes/task ()
  "In a fleeting note: turn it into a task. Elsewhere: new task under this note."
  (interactive)
  (save-buffer)
  (if (equal (+notes--type buffer-file-name) "fleeting")
      (let* ((title (read-string "Task: " (+notes--title)))
             (up (+notes--pick "Project or parent task: " "projects" "tasks"))
             (due (+notes-deadline)))
        (+notes--retype title (list "UP" (+notes--link up) "PROJECT" (+notes--project-of up)))
        (insert "* TODO " title "\n" due)
        (+notes--move "tasks" title))
    (let ((+notes--parent (org-roam-node-from-id (org-entry-get (point-min) "ID"))))
      (+notes--capture "t" (read-string "Task: ")))))

;;; Processing fleeting notes

(defun +notes/process ()
  "Visit the next fleeting note due for review."
  (interactive)
  (when (bound-and-true-p +notes-process-mode) (save-buffer))
  (let* ((tomorrow (+notes--today 1))
         (due (sort (seq-filter (lambda (n) (string< (or (+notes--prop n "REVIEW") "") tomorrow))
                                (+notes--nodes "fleeting"))
                    :key (lambda (n) (or (+notes--prop n "REVIEW") ""))))
         (here (and buffer-file-name
                    (seq-position due buffer-file-name
                                  (lambda (n f) (file-equal-p (org-roam-node-file n) f)))))
         (next (if here (nth (mod (1+ here) (length due)) due) (car due))))
    (if (not next)
        (message "No fleeting notes due")
      (find-file (org-roam-node-file next))
      (message "%d fleeting notes due" (length due)))))

(defun +notes/snooze (days)
  (org-entry-put (point-min) "REVIEW" (+notes--today days))
  (+notes/process))

(defun +notes/delete ()
  (interactive)
  (when (y-or-n-p "Delete this note? ")
    (let ((file buffer-file-name))
      (set-buffer-modified-p nil)
      (kill-buffer)
      (delete-file file t))
    (+notes/process)))

(defun +notes/atomic ()
  "Turn this fleeting note into an atomic note."
  (interactive)
  (let* ((title (read-string "Atomic title: " (+notes--title)))
         (up (+notes--pick "UP (empty for none): " "atomic")))
    (+notes--retype title (list "UP" (+notes--link up)))
    (let ((orig (string-trim (delete-and-extract-region (point) (point-max)))))
      (insert "\n\n\n* See also\n\n* References\n\n* Original capture\n" orig "\n"))
    (+notes--move "atomic" title)
    (re-search-forward "^#\\+title:.*\n\n" nil t)
    (message "Write it in your own words. SPC n p for the next note")))

;;; Literature notes from qutebrowser

(defun +notes-web-highlight (dir)
  "Add the highlight in DIR (files url, title, text) to the URL's literature note."
  (require 'org-roam)
  (cl-flet ((get (f) (with-temp-buffer
                       (insert-file-contents (expand-file-name f dir))
                       (string-trim (buffer-string)))))
    (let* ((url (get "url")) (title (get "title")) (text (get "text"))
           (node (org-roam-node-from-ref url))
           (file (if node (org-roam-node-file node)
                   (expand-file-name (concat "literature/" (org-roam-node-slugify title) ".org")
                                     org-roam-directory))))
      (when (and (not node) (file-exists-p file))
        (setq file (concat (file-name-sans-extension file) (format-time-string "_%s.org"))))
      (with-current-buffer (find-file-noselect file)
        (when (= (buffer-size) 0)
          (insert (+notes--drawer "ID" (org-id-new) "ROAM_REFS" url)
                  "#+title: " title "\n#+filetags: :unfiled:\n"))
        (unless (string-empty-p text)
          (goto-char (point-max))
          (unless (bolp) (insert "\n"))
          (insert "* TODO " (truncate-string-to-width
                             (replace-regexp-in-string "[ \t\n]+" " " text) 60 nil nil "…")
                  "\n#+begin_quote\n" text "\n#+end_quote\n"))
        (save-buffer))
      (if (string-empty-p text) "note" "highlight"))))

(add-hook! 'org-after-todo-state-change-hook
  (defun +notes-literature-filed-h ()
    "Drop the unfiled tag once every highlight is DONE."
    (when (and (member "unfiled" org-file-tags) (not (org-map-entries t "/TODO" 'file)))
      (save-excursion (goto-char (point-min)) (org-roam-tag-remove '("unfiled"))))))

;;; Project task block: #+begin: tasks

(defun +notes--state (file)
  (with-temp-buffer
    (insert-file-contents file)
    (and (re-search-forward "^\\* \\([A-Z]+\\) " nil t) (match-string 1))))

(defun org-dblock-write:tasks (_params)
  (let ((tasks (+notes--nodes "tasks")))
    (insert (mapconcat (lambda (e)
                         (format "%s- [%s] %s" (make-string (* 2 (car e)) ?\s)
                                 (pcase (+notes--state (org-roam-node-file (cdr e)))
                                   ((or "DONE" "KILL") "X") ("STRT" "-") (_ " "))
                                 (+notes--link (cdr e))))
                       (+notes--walk tasks (+notes--children tasks (org-entry-get (point-min) "ID")))
                       "\n"))))

;;; Views

(defun +notes/tree ()
  "Atomic notes as a foldable tree built from UP; RET opens a note."
  (interactive)
  (let* ((nodes (+notes--nodes "atomic"))
         (ids (mapcar #'org-roam-node-id nodes)))
    (with-current-buffer (get-buffer-create "*notes: tree*")
      (let ((inhibit-read-only t))
        (erase-buffer)
        (org-mode)
        (dolist (e (+notes--walk nodes (seq-remove (lambda (n) (member (+notes--up-id n) ids)) nodes)))
          (insert (make-string (1+ (car e)) ?*) " " (+notes--link (cdr e)) "\n"))
        (org-fold-show-all))
      (setq buffer-read-only t)
      (goto-char (point-min))
      (pop-to-buffer-same-window (current-buffer)))))

(defun +notes--due ()
  (if-let* ((d (org-entry-get nil "DEADLINE"))) (substring d 1 11) "—"))

(defun +notes--project ()
  (org-link-display-format (or (org-entry-get nil "PROJECT" t) "")))

(after! org-agenda
  (dolist (cmd '(("k" "Projects" todo "PROJ"
                  ((org-agenda-files '("~/notes/projects/"))
                   (org-agenda-sorting-strategy '(deadline-up alpha-up))
                   (org-agenda-prefix-format "  %-11(+notes--due) ")))
                 ("K" "Open tasks" todo "TODO|STRT"
                  ((org-agenda-files '("~/notes/tasks/"))
                   (org-agenda-sorting-strategy '(todo-state-down deadline-up alpha-up))
                   (org-agenda-prefix-format "  %-11(+notes--due) %-20(+notes--project) ")))
                 ("h" "Unfiled highlights" tags-todo "unfiled"
                  ((org-agenda-files '("~/notes/literature/"))))))
    (add-to-list 'org-agenda-custom-commands cmd t)))

;;; Per-type setup when a note is opened

(define-minor-mode +notes-process-mode "Fleeting note." :keymap (make-sparse-keymap))
(define-minor-mode +notes-task-mode "Project or task." :keymap (make-sparse-keymap))
(add-hook! '(+notes-process-mode-hook +notes-task-mode-hook) #'evil-normalize-keymaps)

(add-hook! 'find-file-hook
  (defun +notes-file-h ()
    (when (and (derived-mode-p 'org-mode) buffer-file-name
               (file-in-directory-p buffer-file-name org-roam-directory))
      (pcase (+notes--type buffer-file-name)
        ("fleeting" (+notes-process-mode 1))
        ("tasks" (+notes-task-mode 1))
        ("projects"
         (+notes-task-mode 1)
         (org-update-all-dblocks)
         (when (buffer-modified-p) (save-buffer)))))))

;;; Keys

(map! :leader
      (:prefix "n"
       :desc "Fleeting note"      "i" #'+notes/fleeting
       :desc "Process fleeting"   "p" #'+notes/process
       :desc "Atomic tree"        "u" #'+notes/tree
       :desc "Unfiled literature" "h" (cmd! (org-agenda nil "h"))
       :desc "Projects"           "k" (cmd! (org-agenda nil "k"))
       :desc "Open tasks"         "K" (cmd! (org-agenda nil "K"))))

(map! :map +notes-process-mode-map
      :localleader
      :desc "Make atomic"  "a" #'+notes/atomic
      :desc "Make task"    "T" #'+notes/task
      :desc "Snooze day"   "t" (cmd! (+notes/snooze 1))
      :desc "Snooze week"  "w" (cmd! (+notes/snooze 7))
      :desc "Snooze month" "m" (cmd! (+notes/snooze 30))
      :desc "Delete"       "D" #'+notes/delete
      :desc "Next note"    "n" #'+notes/process)

(map! :map +notes-task-mode-map
      :localleader
      :desc "Cycle status" "s" #'+notes/status
      :desc "New task"     "T" #'+notes/task)
