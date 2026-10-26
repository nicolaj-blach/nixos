;;; +mu4e.el -*- lexical-binding: t; -*-
;; Proton Mail via Bridge. mbsync, msmtp and mu are configured in Nix
;; (modules/apps/productivity/protonmail).

(defvar +mail-sendable-addresses '("me@nicolaj-blach.dev" "me@nicolaj.dev")
  "Addresses Bridge can send from. The Gmail addresses are external in Proton.")

;; Called by mbsync.service after each sync. Returns nil if mu4e isn't running,
;; so the service runs `mu index' itself. Skips when mu4e is already indexing
;; or ran the sync itself (`u'), since mu4e indexes afterwards anyway.
(defun +mail-index ()
  (when (and (fboundp 'mu4e-running-p) (mu4e-running-p))
    (unless (or mu4e--server-indexing
                (and (buffer-live-p mu4e--update-buffer)
                     (process-live-p (get-buffer-process mu4e--update-buffer))))
      (mu4e-update-index))
    t))

(after! mu4e
  (setq mu4e-get-mail-command "systemctl --user start mbsync.service"
        mu4e-update-interval nil
        mu4e-change-filenames-when-moving t
        ;; mbsync would expunge T-flagged mail; trash should only move it
        mu4e-trash-without-flag t
        mu4e-sent-folder "/Sent"
        mu4e-drafts-folder "/Drafts"
        mu4e-trash-folder "/Trash"
        mu4e-refile-folder "/Archive"
        ;; Bridge stores sent mail in Sent itself
        mu4e-sent-messages-behavior 'delete
        mu4e-maildir-shortcuts '((:maildir "/INBOX" :key ?i)
                                 (:maildir "/Archive" :key ?a)
                                 (:maildir "/Sent" :key ?s)
                                 (:maildir "/Drafts" :key ?d)
                                 (:maildir "/Trash" :key ?t))
        ;; Send through msmtp, which picks the account from the From header
        message-send-mail-function #'message-send-mail-with-sendmail
        sendmail-program (executable-find "msmtp")
        mail-specify-envelope-from t
        message-sendmail-envelope-from 'header
        mail-envelope-from 'header)

  ;; Reply from the address the mail was sent to, if Bridge can send from it;
  ;; otherwise use the default. The From line can still be edited by hand.
  (remove-hook 'mu4e-compose-pre-hook #'+mu4e-set-from-address-h)
  (add-hook! 'mu4e-compose-pre-hook
    (defun +mail-set-from-h ()
      (setq user-mail-address
            (or (when-let* ((parent mu4e-compose-parent-message))
                  (seq-find (lambda (addr) (member addr +mail-sendable-addresses))
                            (mapcar (lambda (c) (plist-get c :email))
                                    (append (mu4e-message-field parent :to)
                                            (mu4e-message-field parent :cc)))))
                (car +mail-sendable-addresses)))))

  ;; Proton labels are the Labels/* mailboxes. Copying a message there adds the
  ;; label (Bridge recognises the copy); deleting it there (D) removes the label.
  (defun +mail-add-label (msg)
    (let* ((root (expand-file-name "Labels" (mu4e-root-maildir)))
           (labels (and (file-directory-p root)
                        (seq-remove (lambda (f) (string-prefix-p "." f))
                                    (directory-files root))))
           (label (completing-read "Label: " labels))
           (dir (expand-file-name label root))
           (src (mu4e-message-field msg :path))
           ;; Drop mbsync's UID so the copy is uploaded as a new message
           (name (replace-regexp-in-string ",U=[0-9]+" "" (file-name-nondirectory src))))
      (dolist (sub '("cur" "new" "tmp"))
        (make-directory (expand-file-name sub dir) t))
      (copy-file src (expand-file-name (concat "cur/" name) dir) t)
      (mu4e-update-mail-and-index t)
      (message "Labelled %s" label)))

  (defun +mail-fleeting (msg)
    (+notes/fleeting (mu4e-message-field msg :subject)
                     (format "[[mu4e:msgid:%s][%s]]" (mu4e-message-field msg :message-id)
                             (mu4e-message-field msg :subject))))

  (dolist (action '(("label" . +mail-add-label) ("fleeting" . +mail-fleeting)))
    (add-to-list 'mu4e-headers-actions action t)
    (add-to-list 'mu4e-view-actions action t)))
