;;; +llm.el -*- lexical-binding: t; -*-
;; Quick questions/edits with gptel through the LiteLLM gateway,
;; longer collaboration with pi through pilish.

(defvar +llm-quick-model 'openrouter/anthropic/claude-haiku-5.5)

(defun +llm--gateway-models ()
  (let ((file "/var/lib/ai-gateway/pi-models.json"))
    (when (file-readable-p file)
      (let ((json (json-parse-string
                   (with-temp-buffer (insert-file-contents file) (buffer-string))
                   :object-type 'alist :array-type 'list)))
        (mapcar (lambda (m) (intern (alist-get 'id m)))
                (alist-get 'models (alist-get 'litellm (alist-get 'providers json))))))))

(after! gptel
  (setq gptel-backend
        (gptel-make-openai "LiteLLM"
          :host "127.0.0.1:4000"
          :protocol "http"
          :endpoint "/v1/chat/completions"
          :stream t
          :key (lambda ()
                 (string-trim
                  (with-temp-buffer
                    (insert-file-contents "/run/secrets/ai-gateway-token")
                    (buffer-string))))
          :models (or (+llm--gateway-models) (list +llm-quick-model)))
        gptel-model +llm-quick-model
        gptel-default-mode 'markdown-mode)
  (map! :map gptel-mode-map
        :n "RET" #'gptel-send
        :n [return] #'gptel-send))

;;; Context of the current buffer

(defun +llm--context ()
  "File, language and selection (or lines around point) as a markdown string."
  (let* ((file (or (buffer-file-name) (buffer-name)))
         (lang (string-remove-suffix "-mode" (symbol-name major-mode)))
         (region (use-region-p))
         (beg (if region (region-beginning)
                (save-excursion (forward-line -40) (point))))
         (end (if region (region-end)
                (save-excursion (forward-line 40) (point)))))
    (format "File: %s (lines %d-%d)\n%s:\n```%s\n%s\n```\n"
            (abbreviate-file-name file)
            (line-number-at-pos beg) (line-number-at-pos end)
            (if region "Selected code" "Code around the cursor")
            lang (buffer-substring-no-properties beg end))))

;;; Quick question: a gptel chat popup you can keep talking in

(defun +llm/ask (question &optional fresh)
  "Ask QUESTION about the selection, or the code around point.
Follow-ups go in the *llm-ask* chat; with prefix arg FRESH, start over."
  (interactive "sAsk: \nP")
  (require 'gptel)
  (let ((context (+llm--context)))
    (when (and fresh (get-buffer "*llm-ask*"))
      (kill-buffer "*llm-ask*"))
    (with-current-buffer (gptel "*llm-ask*")
      (setq-local gptel-system-prompt
                  "You are a concise coding assistant inside Emacs. Answer briefly, use markdown.")
      (goto-char (point-max))
      (insert context "\n" question)
      (gptel-send)
      (pop-to-buffer (current-buffer)))))

;;; Collaboration: pi session for the project

(use-package! pilish
  :commands (pilish pilish-toggle pilish-session-browser))

(defun +llm/pi-send-context ()
  "Open pi for this project with the file and selection in the prompt."
  (interactive)
  (let ((context (+llm--context)))
    (deactivate-mark)
    (pilish)
    (goto-char (point-max))
    (insert context "\n")
    (when (bound-and-true-p evil-local-mode) (evil-insert-state))))

(map! :leader
      (:prefix ("l" . "llm")
       :desc "Ask about selection/point" "a" #'+llm/ask
       :desc "Rewrite selection"         "r" #'gptel-rewrite
       :desc "Send to gptel"             "s" #'gptel-send
       :desc "gptel menu (model, ...)"   "m" #'gptel-menu
       :desc "gptel chat"                "c" #'gptel
       :desc "Add region/buffer to ctx"  "x" #'gptel-add
       :desc "Add file to ctx"           "f" #'gptel-add-file
       :desc "Explain at point"          "e" #'gptel-quick
       :desc "Pi session"                "p" #'pilish
       :desc "Pi with this file/region"  "P" #'+llm/pi-send-context
       :desc "Toggle pi windows"         "t" #'pilish-toggle
       :desc "Pi sessions"               "S" #'pilish-session-browser))
