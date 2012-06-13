;;;_. Initialization  -*- allout-layout: (1 :) -*-

(defvar using-textexpander nil)

;;;_ , Create use-package macro, to simplify customizations

(defmacro use-package (name &rest args)
  (let ((commands (plist-get args :commands))
        (init-body (plist-get args :init))
        (config-body (plist-get args :config))
        (diminish-var (plist-get args :diminish))
        (name-string (if (stringp name) name
                       (symbol-name name))))
    (if diminish-var
        (setq config-body
              `(progn
                 ,config-body
                 (ignore-errors (diminish (quote ,diminish-var))))))
    (if (or commands (plist-get args :defer))
        (let (form)
          (unless (listp commands)
            (setq commands (list commands)))
          (dolist (command commands)
            (add-to-list
             'form `(autoload (function ,command)
                      ,name-string nil t)))
          `(progn
             ,@form
             ,init-body
             (eval-after-load ,name-string
               (quote ,config-body))))
      `(when ,(if (stringp name)
                  `(load ,name t)
                `(require ',name nil t))
         ,init-body
         ,config-body))))

(put 'use-package 'lisp-indent-function 1)

(font-lock-add-keywords 'emacs-lisp-mode
                        '(("(use-package\\>" . font-lock-keyword-face)))

;;;_ , Create my own global minor-mode, to hold key remappings

(require 'easy-mmode)

(defvar override-global-map (make-keymap)
  "override-global-mode keymap")

(define-minor-mode override-global-mode
  "A minor mode so my key settings override all other modes."
  t "" override-global-map)

(add-hook 'after-init-hook
          (lambda ()
            (override-global-mode 1)))

;;;_ , Increase *Messages* max length

(setq message-log-max 16384)

;;;_ , Read system environment

(let ((plist (expand-file-name "~/.MacOSX/environment.plist")))
  (when (file-readable-p plist)
    (let ((dict (cdr (assq #'dict (cdar (xml-parse-file plist))))))
      (while dict
        (if (and (listp (car dict))
                 (eq 'key (caar dict)))
            (setenv (car (cddr (car dict)))
                    (car (cddr (car (cddr dict))))))
        (setq dict (cdr dict))))

    ;; Configure exec-path based on the new PATH
    (setq exec-path nil)
    (mapc #'(lambda (path)
              (add-to-list 'exec-path path))
          (nreverse (split-string (getenv "PATH") ":")))))

;;;_ , Load customizations

(setq gnus-home-directory "~/Messages/Gnus/") ; a necessary override

(load "~/.emacs.d/settings")

;;;_ , Enable disabled commands

(put 'downcase-region  'disabled nil)   ; Let upcasing work
(put 'erase-buffer     'disabled nil)
(put 'eval-expression  'disabled nil)   ; Let ESC-ESC work
(put 'narrow-to-page   'disabled nil)   ; Let narrowing work
(put 'narrow-to-region 'disabled nil)   ; Let narrowing work
(put 'set-goal-column  'disabled nil)
(put 'upcase-region    'disabled nil)   ; Let downcasing work

;;;_ , Perform direct loads

(eval-when-compile
  (require 'cl))

(mapc #'require
      '(browse-kill-ring+
        bookmark
        diminish
        ido
        info-look
        page-ext
        per-window-point
        pp-c-l
        recentf
        tex-site
        workgroups
        yasnippet))

;;;_. Packages

;;;_ , Drew Adams

;;;_  . bookmark+

(eval-after-load "bookmark"
  '(require 'bookmark+))

;;;_  . diff-mode-

(require 'diff-mode-)

;;;_  . hl-line+

(eval-after-load "hl-line"
  '(require 'hl-line+))

;;;_  . info+

(eval-after-load "info"
  '(progn
     (require 'info+)))

;;;_ , abbrev

(if (file-exists-p abbrev-file-name)
    (quietly-read-abbrev-file))

(ignore-errors (diminish 'abbrev-mode))

;;;_  . expand

(add-hook 'expand-load-hook
          (lambda ()
            (add-hook 'expand-expand-hook 'indent-according-to-mode)
            (add-hook 'expand-jump-hook 'indent-according-to-mode)))

;;;_ , ace-jump-mode

(use-package ace-jump-mode
  :commands ace-jump-mode
  :init
  (progn
    (define-key global-map [(control ?.)] 'ace-jump-mode)
    (define-key override-global-map [(control ?.)] 'ace-jump-mode)
    (eval-after-load "flyspell"
      '(define-key flyspell-mode-map [(control ?.)] 'ace-jump-mode))))

;;;_ , allout

(defvar allout-unprefixed-keybindings nil)

(defun my-allout-mode-hook ()
  (dolist (mapping '((?b . allout-hide-bodies)
                     (?c . allout-hide-current-entry)
                     (?l . allout-hide-current-leaves)
                     (?i . allout-show-current-branches)
                     (?e . allout-show-entry)
                     (?o . allout-show-to-offshoot)))
    (define-key allout-mode-map
      (vconcat allout-command-prefix
               (vector (car mapping))) (cdr mapping))))

(add-hook 'allout-mode-hook 'my-allout-mode-hook)

;;;_ , anything

(defvar anything-sources
  '(
    ;; Buffer:
    anything-c-source-buffers
    anything-c-source-buffer-not-found
    anything-c-source-buffers+
    ;; File:
    anything-c-source-file-name-history
    anything-c-source-files-in-current-dir
    anything-c-source-files-in-current-dir+
    anything-c-source-file-cache
    anything-c-source-locate
    anything-c-source-recentf
    anything-c-source-ffap-guesser
    anything-c-source-ffap-line
    ;; Command:
    anything-c-source-complex-command-history
    anything-c-source-extended-command-history
    anything-c-source-emacs-commands
    ;; Bookmark:
    anything-c-source-bookmarks
    anything-c-source-bookmark-set
    anything-c-source-bookmarks-ssh
    anything-c-source-bookmarks-su
    anything-c-source-bookmarks-local
    ;; Library:
    anything-c-source-elisp-library-scan
    ;; Misc:
    anything-c-source-google-suggest
    anything-c-source-mac-spotlight
    ;; System:
    anything-c-source-emacs-process))

(fset 'describe-bindings 'descbinds-anything)

(eval-after-load "anything"
  '(progn
     (require 'anything-match-plugin)

     (define-key anything-map "." 'anything-select-with-prefix-shortcut)
     (if using-textexpander
         (define-key anything-map [(alt ?v)] 'anything-previous-page))))

(defun my-anything-apropos ()
  (interactive)
  (require 'anything-config)
  (anything
   :prompt "Info about: "
   :candidate-number-limit 5
   :sources '(anything-c-source-emacs-commands
              anything-c-source-emacs-functions
              anything-c-source-emacs-variables
              anything-c-source-info-emacs
              anything-c-source-info-elisp
              anything-c-source-info-gnus
              anything-c-source-info-org
              anything-c-source-info-cl
              anything-c-source-emacs-source-defun)))

;;;_ , auctex

(eval-when-compile
  (defvar texinfo-section-list)
  (defvar latex-help-cmd-alist)
  (defvar latex-help-file))

(defun my-texinfo-mode-hook ()
  (dolist (mapping '((?b . "emph")
                     (?c . "code")
                     (?s . "samp")
                     (?d . "dfn")
                     (?o . "option")
                     (?x . "pxref")))
    (local-set-key (vector (list 'alt (car mapping)))
                   `(lambda () (interactive)
                      (TeX-insert-macro ,(cdr mapping))))))

(add-hook 'texinfo-mode-hook 'my-texinfo-mode-hook)

(defun texinfo-outline-level ()
  ;; Calculate level of current texinfo outline heading.
  (require 'texinfo)
  (save-excursion
    (if (bobp)
        0
      (forward-char 1)
      (let* ((word (buffer-substring-no-properties
                    (point) (progn (forward-word 1) (point))))
             (entry (assoc word texinfo-section-list)))
        (if entry
            (nth 1 entry)
          5)))))

(defun latex-help-get-cmd-alist () ;corrected version:
  "Scoop up the commands in the index of the latex info manual.
   The values are saved in `latex-help-cmd-alist' for speed."
  ;; mm, does it contain any cached entries
  (if (not (assoc "\\begin" latex-help-cmd-alist))
      (save-window-excursion
        (setq latex-help-cmd-alist nil)
        (Info-goto-node (concat latex-help-file "Command Index"))
        (goto-char (point-max))
        (while (re-search-backward "^\\* \\(.+\\): *\\(.+\\)\\." nil t)
          (let ((key (buffer-substring (match-beginning 1) (match-end 1)))
                (value (buffer-substring (match-beginning 2) (match-end 2))))
            (add-to-list 'latex-help-cmd-alist (cons key value))))))
  latex-help-cmd-alist)

(info-lookup-add-help :mode 'latex-mode
                      :regexp ".*"
                      :parse-rule "\\\\?[a-zA-Z]+\\|\\\\[^a-zA-Z]"
                      :doc-spec '(("(latex2e)Concept Index" )
                                  ("(latex2e)Command Index")))

;;;_ , auto-complete

(require 'auto-complete-config)
;; (require 'auto-complete-clang)

(ac-set-trigger-key "TAB")

(setq ac-use-menu-map t)
;; Default settings
(define-key ac-menu-map "\C-n" 'ac-next)
(define-key ac-menu-map "\C-p" 'ac-previous)

;;;_ , backup-each-save

(require 'backup-each-save)

(add-hook 'after-save-hook 'backup-each-save)

(defun backup-each-save-filter (filename)
  (message "Checking '%s'" filename)
  (not (string-match "\\(^/tmp\\|\\.emacs\\.d/data/\\|\\.newsrc\\(\\.eld\\)?\\)" filename)))

(setq backup-each-save-filter-function 'backup-each-save-filter)

(defun my-dont-backup-files-p (filename)
  (unless (string-match filename "/\\(archive/sent/\\|recentf$\\)")
    (normal-backup-enable-predicate filename)))

(setq backup-enable-predicate 'my-dont-backup-files-p)

;;;_ , bm

(use-package bm
  :commands (bm-toggle bm-next bm-previous bm-show bm-show-all)
  :init
  (progn
    (define-key global-map [(alt ?b)] 'bm-last-in-previous-buffer)
    (define-key global-map [(alt ?f)] 'bm-first-in-next-buffer)
    (define-key global-map [(alt ?g)] 'bm-previous)
    (define-key global-map [(alt ?l)] 'bm-show-all)
    (define-key global-map [(alt ?m)] 'bm-toggle)
    (define-key global-map [(alt ?n)] 'bm-next)
    (define-key global-map [(alt ?p)] 'bm-previous)))

;;;_ , breadcrumb

(if nil
    (use-package breadcrumb
      :commands bc-set
      :init
      (progn
        (define-key global-map [(alt ?b)] 'bc-local-previous)
        (define-key global-map [(alt ?f)] 'bc-local-next)
        (define-key global-map [(alt ?g)] 'bc-goto-current)
        (define-key global-map [(alt ?l)] 'bc-list)
        (define-key global-map [(alt ?m)] 'bc-set)
        (define-key global-map [(alt ?n)] 'bc-next)
        (define-key global-map [(alt ?p)] 'bc-previous))))

;;;_ , css-mode

(add-to-list 'auto-mode-alist '("\\.css$" . css-mode))

;;;_ , diminish

(ignore-errors (diminish 'auto-fill-function))

(defadvice dired-omit-startup (after diminish-dired-omit activate)
  "Make sure to remove \"Omit\" from the modeline."
  (diminish 'dired-omit-mode))

(eval-after-load "dot-mode"
  '(ignore-errors (diminish 'dot-mode)))

(eval-after-load "whitespace"
  '(ignore-errors
     (diminish 'global-whitespace-mode)
     (diminish 'whitespace-mode)
     (diminish 'whitespace-newline-mode)))

;;;_ , dired

(eval-after-load "dired-aux"
  '(progn
     (defun start-process-and-kill-buffer (&rest args)
       (set-process-sentinel
        (apply #'start-process args)
        (lambda (proc change)
          (if (and (eq 'exit (process-status proc))
                   (= 0 (process-exit-status proc)))
              (kill-buffer (process-buffer proc))))))

     (defun rsync-file-asynchronously (from to)
       (let ((args (list "-avHAXEy" "--fileflags" "--delete-during"
                         "--force-delete")))
         (nconc args (list from to))
         (apply #'start-process-and-kill-buffer "rsync"
                (generate-new-buffer "*rsync*")
                (executable-find "rsync") args)))

     (defun copy-file-asynchronously (from to ok-flag)
       (let ((args (list "-pvR")))
         (if ok-flag
             (nconc args (list "-i")))
         (nconc args (list from to))
         (apply #'start-process-and-kill-buffer "cp"
                (generate-new-buffer "*cp*")
                (executable-find "cp") args)))

     (defun dired-copy-file (from to ok-flag)
       (dired-handle-overwrite to)
       (if (or (string-match ":" from) (string-match ":" to))
           (dired-copy-file-recursive from to ok-flag dired-copy-preserve-time t
                                      dired-recursive-copies)
         (if (file-exists-p to)
             (rsync-file-asynchronously from to)
           (copy-file-asynchronously from to ok-flag))))

     (defun move-file-asynchronously (file newname ok-flag)
       (let ((args (list "-v")))
         (nconc args (list file newname))
         (apply #'start-process-and-kill-buffer "mv"
                (generate-new-buffer "*mv*")
                (executable-find "mv") args)))

     (defun dired-rename-file (file newname ok-if-already-exists)
       (dired-handle-overwrite newname)
       (if (or (string-match ":" from) (string-match ":" to))
           (rename-file file newname ok-if-already-exists)
         (if (file-exists-p to)
             (progn
               (rsync-file-asynchronously from to)
               (delete-file-asynchronously from (file-directory-p from)))
           (move-file-asynchronously from to ok-if-already-exists)))
       (and (get-file-buffer file)
            (with-current-buffer (get-file-buffer file)
              (set-visited-file-name newname nil t)))
       (dired-remove-file file)
       (dired-rename-subdir file newname))

     (defun delete-file-asynchronously (file &optional recursive)
       (let ((args (list "-f")))
         (if recursive
             (nconc args (list "-r")))
         (nconc args (list file))
         (apply #'start-process-and-kill-buffer "rm"
                (generate-new-buffer "*rm*")
                (executable-find "rm") args)))

     (defun dired-delete-file (file &optional recursive trash)
       (if (not (eq t (car (file-attributes file))))
           (if (string-match ":" file)
               (delete-file file trash)
             (delete-file-asynchronously file))
         (if (and recursive
                  (directory-files file t dired-re-no-dot) ; Not empty.
                  (or (eq recursive 'always)
                      (yes-or-no-p (format "Recursively %s %s? "
                                           (if (and trash
                                                    delete-by-moving-to-trash)
                                               "trash"
                                             "delete")
                                           (dired-make-relative file)))))
             (if (eq recursive 'top) (setq recursive 'always)) ; Don't ask again.
           (setq recursive nil))
         (if (string-match ":" file)
             (delete-directory file recursive trash)
           (delete-file-asynchronously file t))))))

;;;_ , dired-x

(defvar dired-omit-regexp-orig (symbol-function 'dired-omit-regexp))

;; Omit files that Git would ignore
(defun dired-omit-regexp ()
  (let ((file (expand-file-name ".git"))
        parent-dir)
    (while (and (not (file-exists-p file))
                (progn
                  (setq parent-dir
                        (file-name-directory
                         (directory-file-name
                          (file-name-directory file))))
                  ;; Give up if we are already at the root dir.
                  (not (string= (file-name-directory file)
                                parent-dir))))
      ;; Move up to the parent dir and try again.
      (setq file (expand-file-name ".git" parent-dir)))
    ;; If we found a change log in a parent, use that.
    (if (file-exists-p file)
        (let ((regexp (funcall dired-omit-regexp-orig))
              (omitted-files (shell-command-to-string "git clean -d -x -n")))
          (if (= 0 (length omitted-files))
              regexp
            (concat
             regexp
             (if (> (length regexp) 0)
                 "\\|" "")
             "\\("
             (mapconcat
              #'(lambda (str)
                  (concat "^"
                          (regexp-quote
                           (substring str 13
                                      (if (= ?/ (aref str (1- (length str))))
                                          (1- (length str))
                                        nil)))
                          "$"))
              (split-string omitted-files "\n" t)
              "\\|")
             "\\)")))
      (funcall dired-omit-regexp-orig))))

(eval-after-load "dired"
  '(progn
     (require 'runner nil t)

     (setq dired-use-ls-dired t)

     (define-key dired-mode-map [?l] 'dired-up-directory)
     ;; (define-key dired-mode-map [tab] 'other-window)
     (define-key dired-mode-map [(meta shift ?g)] 'switch-to-gnus)
     (define-key dired-mode-map [(meta ?s) ?f] 'find-grep)

     (defadvice dired-next-line (around dired-next-line+ activate)
       "Replace current buffer if file is a directory."
       ad-do-it
       (while (and  (not  (eobp)) (not ad-return-value))
         (forward-line)
         (setq ad-return-value(dired-move-to-filename)))
       (when (eobp)
         (forward-line -1)
         (setq ad-return-value(dired-move-to-filename))))

     (defadvice dired-previous-line (around dired-previous-line+ activate)
       "Replace current buffer if file is a directory."
       ad-do-it
       (while (and  (not  (bobp)) (not ad-return-value))
         (forward-line -1)
         (setq ad-return-value(dired-move-to-filename)))
       (when (bobp)
         (call-interactively 'dired-next-line)))))

;;;_ , ediff

(defun ediff-keep-both ()
  (interactive)
  (with-current-buffer ediff-buffer-C
    (beginning-of-line)
    (assert (or (looking-at "<<<<<<")
                (re-search-backward "^<<<<<<" nil t)
                (re-search-forward "^<<<<<<" nil t)))
    (beginning-of-line)
    (let ((beg (point)))
      (forward-line)
      (delete-region beg (point))
      (re-search-forward "^>>>>>>>")
      (beginning-of-line)
      (setq beg (point))
      (forward-line)
      (delete-region beg (point))
      (re-search-forward "^#######")
      (beginning-of-line)
      (setq beg (point))
      (re-search-forward "^=======")
      (beginning-of-line)
      (forward-line)
      (delete-region beg (point)))))


(eval-after-load "ediff-init"
  '(add-hook 'ediff-keymap-setup-hook
             (lambda ()
               (define-key ediff-mode-map [?c] 'ediff-keep-both))))

;;;_ , edit-server

(use-package edit-server
  :config
  (if window-system
      (add-hook 'after-init-hook 'edit-server-start t)))

;;;_ , erc

(require 'erc-alert)
(require 'erc-highlight-nicknames)

(eval-when-compile
  (require 'auth-source))

(defun irc ()
  (interactive)
  (require 'auth-source)
  (erc :server "irc.freenode.net"
       :port 6667
       :nick "johnw"
       :password (funcall
                  (plist-get
                   (car (auth-source-search :host "irc.freenode.net"
                                            :user "johnw"
                                            :type 'netrc
                                            :port 6667))
                   :secret)))
  (erc :server "irc.oftc.net"
       :port 6667
       :nick "johnw"))

(defun im ()
  (interactive)
  (require 'auth-source)
  (erc :server "localhost"
       :port 6667
       :nick "johnw"
       :password (funcall
                  (plist-get
                   (car (auth-source-search :host "bitlbee"
                                            :user "johnw"
                                            :type 'netrc
                                            :port 6667))
                   :secret))))

(defun erc-cmd-WTF (term &rest ignore)
  "Look up definition for TERM."
  (let ((def (wtf-is term)))
    (if def
        (let ((msg (concat "{Term} " (upcase term) " is " def)))
          (with-temp-buffer
            (insert msg)
            (kill-ring-save (point-min) (point-max)))
          (message msg))
      (message (concat "No definition found for " (upcase term))))))

(defun erc-cmd-FOOL (term &rest ignore)
  (add-to-list 'erc-fools term))

(defun erc-cmd-UNFOOL (term &rest ignore)
  (setq erc-fools (delete term erc-fools)))

;;;_ , eshell

(defun eshell-spawn-external-command (beg end)
   "Parse and expand any history references in current input."
   (save-excursion
     (goto-char end)
     (when (looking-back "&!" beg)
       (delete-region (match-beginning 0) (match-end 0))
       (goto-char beg)
       (insert "spawn "))))

(add-hook 'eshell-expand-input-functions 'eshell-spawn-external-command)

(defun ss (server)
  (interactive "sServer: ")
  (call-process "spawn" nil nil nil "ss" server))

(eval-after-load "em-unix"
  '(unintern 'eshell/rm))

;;;_ , fold-dwim

(use-package fold-dwim
  :commands (fold-dwim-toggle fold-dwim-hide-all fold-dwim-show-all)
  :init
  (progn
    (define-key global-map [f13] 'fold-dwim-toggle)
    (define-key global-map [f14] 'fold-dwim-hide-all)
    (define-key global-map [f15] 'fold-dwim-show-all)))

;;;_ , git

(setenv "GIT_PAGER" "")

(add-hook 'magit-log-edit-mode-hook
          #'(lambda ()
              (set-fill-column 72)
              (flyspell-mode)
              (orgstruct++-mode)))

(eval-after-load "magit"
  '(progn
     (require 'magit-topgit)
     (require 'rebase-mode)

     (defun start-git-monitor ()
       (interactive)
       (start-process "git-monitor" (current-buffer) "~/bin/git-monitor"))

     ;;(add-hook 'magit-status-mode-hook 'start-git-monitor)
     ))

(defun git-commit-changes ()
  (start-process "*git commit*" nil "git" "commit" "-a" "-m" "changes"))

(defvar anything-c-source-git-files
  '((name . "Files under Git version control")
    (init . anything-c-source-git-files-init)
    (candidates-in-buffer)
    (type . file))
  "Search for files in the current Git project.")

(defun anything-c-source-git-files-init ()
  "Build `anything-candidate-buffer' of Git files."
  (with-current-buffer (anything-candidate-buffer 'local)
    (mapcar
     (lambda (item)
       (insert (expand-file-name item) ?\n))
     (split-string (shell-command-to-string "git ls-files") "\n"))))

(defun anything-find-git-file ()
  (interactive)
  (anything :sources 'anything-c-source-git-files
            :input ""
            :prompt "Find file: "
            :buffer "*Anything git file*"))

;;;_ , gtags

(eval-after-load "gtags"
  '(progn
     (require 'anything-gtags)
     (define-key gtags-mode-map "\e," 'anything-gtags-resume)
     (define-key gtags-mode-map [mouse-2] 'gtags-find-tag-from-here)))

;;;_ , ido

(eval-when-compile
  (defvar ido-require-match)
  (defvar ido-cur-item)
  (defvar ido-show-confirm-message)
  (defvar ido-selected)
  (defvar ido-final-text))

(defun ido-smart-select-text ()
  "Select the current completed item.  Do NOT descend into directories."
  (interactive)
  (when (and (or (not ido-require-match)
                 (if (memq ido-require-match
                           '(confirm confirm-after-completion))
                     (if (or (eq ido-cur-item 'dir)
                             (eq last-command this-command))
                         t
                       (setq ido-show-confirm-message t)
                       nil))
                 (ido-existing-item-p))
             (not ido-incomplete-regexp))
    (when ido-current-directory
      (setq ido-exit 'takeprompt)
      (unless (and ido-text (= 0 (length ido-text)))
        (let ((match (ido-name (car ido-matches))))
          (throw 'ido
                 (setq ido-selected
                       (if match
                           (replace-regexp-in-string "/\\'" "" match)
                         ido-text)
                       ido-text ido-selected
                       ido-final-text ido-text)))))
    (exit-minibuffer)))

(add-hook 'ido-minibuffer-setup-hook
          (lambda ()
            (define-key ido-file-completion-map "\C-m"
              'ido-smart-select-text)))

;;;_ , isearch

(use-package "isearch"
  :defer t
  :config
  (progn
    (define-key isearch-mode-map [(control ?c)] 'isearch-toggle-case-fold)
    (define-key isearch-mode-map [(control ?t)] 'isearch-toggle-regexp)
    (define-key isearch-mode-map [(control ?^)] 'isearch-edit-string)
    (define-key isearch-mode-map [(control ?i)] 'isearch-complete)))

;;;_ , lusty-explorer

(use-package lusty-explorer
  :commands lusty-file-explorer
  :init
  (define-key ctl-x-map [(control ?f)] 'lusty-file-explorer)
  :config
  (add-hook 'lusty-setup-hook
            (lambda ()
              (define-key lusty-mode-map [space] 'lusty-select-match)
              (define-key lusty-mode-map [? ] 'lusty-select-match)
              (define-key lusty-mode-map [(control ?d)] 'exit-minibuffer))))

;;;_ , log4j-mode

(use-package log4j-mode
  :commands log4j-mode
  :init
  (add-to-list 'auto-mode-alist '("\\.log$" . log4j-mode)))

;;;_ , merlin

(require 'rx)

(defun merlin-record-times ()
  (interactive)
  (let* ((text (buffer-substring-no-properties (line-beginning-position)
                                               (line-end-position)))
         (regex
          (rx (and string-start (0+ space)
                   (group (and (= 2 num) ?/ (= 2 num) ?/ (= 2 num)
                               space (= 2 num) ?: (= 2 num) space
                               (in "AP") ?M)) (1+ space)
                   (group (and (= 2 num) ?/ (= 2 num) ?/ (= 2 num)
                               space (= 2 num) ?: (= 2 num) space
                               (in "AP") ?M)) (1+ space)
                   (? (and (group ?*) (1+ space)))
                   (group (1+ (or digit (in ".hms"))))
                   (1+ space) (group (1+ nonl)) string-end))))
    (if (string-match regex text)
        (let ((start (match-string 1 text))
              (end (match-string 2 text))
              (cleared (match-string 3 text))
              (duration (match-string 4 text)) commodity
              (account (match-string 5 text)))
          (when (string-match "\\([0-9.]+\\)\\([mhs]\\)" duration)
            (setq commodity (match-string 2 duration)
                  duration (match-string 1 duration))
            (cond ((string= commodity "h")
                   (setq commodity "hours"))
                  ((string= commodity "m")
                   (setq commodity "minutes"))
                  ((string= commodity "s")
                   (setq commodity "seconds"))))
          (if (string-match "\\([0-9.][0-9.a-z]+\\)" account)
              (setq account (match-string 1 account)))
          (do-applescript
           (format
            "
tell application \"Merlin\"
  activate

  set act to 0

  set listActivity to every activity of first document
  repeat with oneActivity in listActivity
    if subtitle of oneActivity is \"%s\" then
      set act to oneActivity
      exit repeat
    end if
  end repeat

  if act is 0 then
    set myselection to selected object of main window of first document as list

    if (count of myselection) is 0 then
      display dialog \"Please select activity to set time for\" buttons {\"OK\"}
    else
      set act to beginning of myselection
    end if
  end if

  if act is 0 or (class of act is project) or (is milestone of act is true) then
    display dialog \"Cannot locate activity for %s\" buttons {\"OK\"}
  else
    tell act
      if ((class is not project) and (is milestone is not true)) then
        set actual start date to (date \"%s\")
        set given actual work to {amount:%s, unit:%s, floating:false, ¬
            relative error:0}
        if %s then
          set actual end date to (date \"%s\")
          delete last actuals reporting date

          set given remaining work to {amount:0, unit:hours, floating:false, ¬
              relative error:0}
        else
          delete actual end date
          set last actuals reporting date to (date \"%s\")

          -- set theReturnedItems to (display dialog \"Enter remaining hours for \" ¬
          --     with title \"Given Remaining Work\" with icon stop ¬
          --     default answer \"\" buttons {\"OK\", \"Cancel\"} default button 1)
          -- set theAnswer to the text returned of theReturnedItems
          -- set theButtonName to the button returned of theReturnedItems
          --
          -- set given remaining work to {amount:(theAnswer as number), unit:hours, ¬
          --        floating:false, relative error:0}
        end if
      end if
    end tell
  end if
end tell" account account start duration commodity (if cleared "true" "false")
          end end))))))

;;;_ , mule

(prefer-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))

(defun normalize-file ()
  (interactive)
  (save-excursion
   (goto-char (point-min))
   (whitespace-cleanup)
   (delete-trailing-whitespace)
   (goto-char (point-max))
   (delete-blank-lines)
   (set-buffer-file-coding-system 'unix)
   (goto-char (point-min))
   (while (re-search-forward "\r$" nil t)
     (replace-match ""))
   (set-buffer-file-coding-system 'utf-8)
   (let ((require-final-newline t))
     (save-buffer))))

;;;_ , nroff-mode

(defun update-nroff-timestamp ()
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward "^\\.Dd ")
      (let ((stamp (format-time-string "%B %e, %Y")))
        (unless (looking-at stamp)
          (delete-region (point) (line-end-position))
          (insert stamp)
          (let (after-save-hook)
            (save-buffer)))))))

(add-hook 'nroff-mode-hook
          (function
           (lambda ()
             (add-hook 'after-save-hook 'update-nroff-timestamp nil t))))

;;;_ , per-window-point

(pwp-mode)

;;;_ , pp-c-l

(pretty-control-l-mode 1)

;;;_ , ps-print

(defun ps-spool-to-pdf (beg end &rest ignore)
  (interactive "r")
  (let ((temp-file (concat (make-temp-name "ps2pdf") ".pdf")))
    (call-process-region beg end (executable-find "ps2pdf")
                         nil nil nil "-" temp-file)
    (call-process (executable-find "open") nil nil nil temp-file)))

(setq ps-print-region-function 'ps-spool-to-pdf)

;;;_ , puppet-mode

(add-to-list 'auto-mode-alist '("\\.pp$" . puppet-mode))

;;;_ , session

(use-package session
  :config
  (progn
    (defun save-information ()
      (dolist (func kill-emacs-hook)
        (unless (memq func '(exit-gnus-on-exit server-force-stop))
          (funcall func)))
      (unless (eq 'listen (process-status server-process))
        (server-start)))

    (run-with-idle-timer 300 t 'save-information)

    (if window-system
        (add-hook 'after-init-hook 'session-initialize t))))

;;;_ , stopwatch

(use-package stopwatch
  :commands stopwatch
  :init
  (define-key global-map [f8] 'stopwatch))

;;;_ , sunrise-commander

(eval-after-load "sunrise-commander"
  '(progn
     (require 'sunrise-x-modeline)
     (require 'sunrise-x-tree)
     (require 'sunrise-x-tabs)
     (require 'sunrise-x-loop)

     (define-key sr-mode-map "/" 'sr-sticky-isearch-forward)
     (define-key sr-mode-map "\C-e" 'end-of-line)
     (define-key sr-mode-map "l" 'sr-dired-prev-subdir)

     (define-key sr-tabs-mode-map [(control ?p)] 'previous-line)
     (define-key sr-tabs-mode-map [(control ?n)] 'next-line)

     (define-key sr-tabs-mode-map [(meta ?\[)] 'sr-tabs-prev)
     (define-key sr-tabs-mode-map [(meta ?\])] 'sr-tabs-next)

     (defun sr-browse-file (&optional file)
       "Display the selected file with the default appication."
       (interactive)
       (setq file (or file (dired-get-filename)))
       (save-selected-window
         (sr-select-viewer-window)
         (let ((buff (current-buffer))
               (fname (if (file-directory-p file)
                          file
                        (file-name-nondirectory file)))
               (app (cond
                     ((eq system-type 'darwin)       "open %s")
                     ((eq system-type 'windows-nt)   "open %s")
                     (t                              "xdg-open %s"))))
           (start-process-shell-command "open" nil (format app file))
           (unless (eq buff (current-buffer))
             (sr-scrollable-viewer (current-buffer)))
           (message "Opening \"%s\" ..." fname))))))

;;;_ , vkill

(use-package vkill
  :commands vkill
  :config
  (setq vkill-show-all-processes t))

;;;_ , w3m

(eval-when-compile
  (defvar w3m-command))

(setq w3m-command "/opt/local/bin/w3m")

;;;_ , whitespace

(remove-hook 'find-file-hooks 'whitespace-buffer)
(remove-hook 'kill-buffer-hook 'whitespace-buffer)

(defun maybe-turn-on-whitespace ()
  "Depending on the file, maybe clean up whitespace."
  (let ((file (expand-file-name ".clean"))
        parent-dir)
    (while (and (not (file-exists-p file))
                (progn
                  (setq parent-dir
                        (file-name-directory
                         (directory-file-name
                          (file-name-directory file))))
                  ;; Give up if we are already at the root dir.
                  (not (string= (file-name-directory file)
                                parent-dir))))
      ;; Move up to the parent dir and try again.
      (setq file (expand-file-name ".clean" parent-dir)))
    ;; If we found a change log in a parent, use that.
    (when (and (file-exists-p file)
               (not (file-exists-p ".noclean"))
               (not (and buffer-file-name
                         (string-match "\\.texi$" buffer-file-name))))
      (add-hook 'write-contents-hooks
                #'(lambda ()
                    (ignore (whitespace-cleanup))) nil t)
      (whitespace-cleanup))))

(add-hook 'find-file-hooks 'maybe-turn-on-whitespace t)

;;;_ , winner

(use-package winner
  :diminish winner-mode
  :init
  (progn
    (define-key global-map [(meta shift ?n)] 'winner-redo)
    (define-key global-map [(meta shift ?p)] 'winner-undo)))

;;;_ , workgroups

(use-package workgroups
  :diminish workgroups-mode
  :config
  (progn
    (workgroups-mode 1)

    (define-key wg-map [(control ?\\)] 'wg-switch-to-previous-workgroup)
    (define-key wg-map [?\\] 'toggle-input-method)

    (if (file-readable-p "~/.emacs.d/data/workgroups")
        (wg-load "~/.emacs.d/data/workgroups"))))

;;;_ , wrap-region

(use-package wrap-region
  :commands wrap-region-mode
  :diminish wrap-region-mode
  :config
  (wrap-region-add-wrappers
   '(("$" "$")
     ("/" "/" nil ruby-mode)
     ("/* " " */" "#" (java-mode javascript-mode css-mode
                                 c-mode c++-mode))
     ("`" "`" nil (markdown-mode ruby-mode shell-script-mode)))))

;;;_ , write-room

(defun write-room ()
  "Make a frame without any bling."
  (interactive)
  ;; to restore:
  ;; (setq mode-line-format (default-value 'mode-line-format))
  (let ((frame (make-frame
                '((minibuffer . nil)
                  (vertical-scroll-bars . nil)
                  (left-fringe . 0); no fringe
                  (right-fringe . 0)
                  (background-mode . dark)
                  (background-color . "cornsilk")
                  (foreground-color . "black")
                  (cursor-color . "green")
                  (border-width . 0)
                  (border-color . "black"); should be unnecessary
                  (internal-border-width . 64); whitespace!
                  (cursor-type . box)
                  (menu-bar-lines . 0)
                  (tool-bar-lines . 0)
                  (fullscreen . fullboth)  ; this should work
                  (unsplittable . t)))))
    (select-frame frame)
    (find-file "~/Documents/Notes.txt")
    (setq mode-line-format nil
          fill-column 65)
    (set-window-margins (selected-window) 50 50)))

;;;_ , yasnippet

(yas/initialize)
(yas/load-directory (expand-file-name "snippets/" user-emacs-directory))

(ignore-errors (diminish 'yas/minor-mode))

(define-key yas/keymap [tab] 'yas/next-field-or-maybe-expand)

(defun yas/new-snippet (&optional choose-instead-of-guess)
  (interactive "P")
  (let ((guessed-directories (yas/guess-snippet-directories)))
    (switch-to-buffer "*new snippet*")
    (erase-buffer)
    (kill-all-local-variables)
    (snippet-mode)
    (set (make-local-variable 'yas/guessed-modes)
         (mapcar #'(lambda (d)
                     (intern (yas/table-name (car d))))
                 guessed-directories))
    (unless (and choose-instead-of-guess
                 (not (y-or-n-p "Insert a snippet with useful headers? ")))
      (yas/expand-snippet "\
# -*- mode: snippet -*-
# name: $1
# --
$0"))))

(define-key mode-specific-map [?y ?n] 'yas/new-snippet)
(define-key mode-specific-map [?y tab] 'yas/expand)
(define-key mode-specific-map [?y ?f] 'yas/find-snippets)
(define-key mode-specific-map [?y ?r] 'yas/reload-all)
(define-key mode-specific-map [?y ?v] 'yas/visit-snippet-file)

;;;_ , Programming modes

;;;_  . cc-mode

(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.m\\'" . c-mode))
(add-to-list 'auto-mode-alist '("\\.mm\\'" . c++-mode))

(add-to-list 'auto-mode-alist '("CMakeLists\\.txt\\'" . cmake-mode))
(add-to-list 'auto-mode-alist '("\\.cmake\\'" . cmake-mode))

(defun my-c-indent-or-complete ()
  (interactive)
  (let ((class (syntax-class (syntax-after (1- (point))))))
    (if (or (bolp) (and (/= 2 class)
                        (/= 3 class)))
        (call-interactively 'indent-according-to-mode)
      (if t
          (call-interactively 'auto-complete)
        (call-interactively 'company-complete-common)))))

(eval-when-compile
  (defvar c-mode-base-map))

(defun my-c-mode-common-hook ()
  (abbrev-mode 1)
  (gtags-mode 1)
  (hs-minor-mode 1)
  (hide-ifdef-mode 1)

  (diminish 'gtags-mode)
  (diminish 'auto-complete-mode)
  (diminish 'hs-minor-mode)
  (diminish 'hide-ifdef-mode)

  (if t
      (progn
        (auto-complete-mode 1)
        (setq ac-sources (append '(ac-source-gtags
                                   ;; ac-source-clang
                                   ac-source-yasnippet)
                                 ac-sources))
        (define-key c-mode-base-map [(alt tab)] 'ac-complete))
    (company-mode 1)
    (define-key c-mode-base-map [(alt tab)] 'company-complete-common))
  (which-function-mode 1)

  ;;(doxymacs-mode 1)
  ;;(doxymacs-font-lock)

  (define-key c-mode-base-map [return] 'newline-and-indent)

  (set (make-local-variable 'yas/fallback-behavior)
       '(apply my-c-indent-or-complete . nil))
  (define-key c-mode-base-map [tab] 'yas/expand-from-trigger-key)

  (define-key c-mode-base-map [(meta ?j)] 'delete-indentation-forward)
  (define-key c-mode-base-map [(control ?c) (control ?i)]
    'c-includes-current-file)

  (set (make-local-variable 'parens-require-spaces) nil)
  (setq indicate-empty-lines t)
  (setq fill-column 72)

  (define-key c-mode-base-map [(meta ?q)] 'c-fill-paragraph)

  (let ((bufname (buffer-file-name)))
    (when bufname
      (cond
       ((string-match "/ledger/" bufname)
        (c-set-style "ledger"))
       ((string-match "/ANSI/" bufname)
        (c-set-style "edg")
        (substitute-key-definition 'fill-paragraph 'ti-refill-comment
                                   c-mode-base-map global-map)
        (define-key c-mode-base-map [(meta ?q)] 'ti-refill-comment))
       (t
        (c-set-style "clang")))))

  (font-lock-add-keywords 'c++-mode '(("\\<\\(assert\\|DEBUG\\)("
                                       1 font-lock-warning-face t))))

(defun ti-refill-comment ()
  (interactive)
  (let ((here (point)))
    (goto-char (line-beginning-position))
    (let ((begin (point)) end
          (marker ?-) (marker-re "\\(-----\\|\\*\\*\\*\\*\\*\\)")
          (leader-width 0))
      (unless (looking-at "[ \t]*/\\*[-* ]")
        (search-backward "/*")
        (goto-char (line-beginning-position)))
      (unless (looking-at "[ \t]*/\\*[-* ]")
        (error "Not in a comment"))
      (while (and (looking-at "\\([ \t]*\\)/\\* ")
                  (setq leader-width (length (match-string 1)))
                  (not (looking-at (concat "[ \t]*/\\*" marker-re))))
        (forward-line -1)
        (setq begin (point)))
      (when (looking-at (concat "[^\n]+?" marker-re "\\*/[ \t]*$"))
        (setq marker (if (string= (match-string 1) "-----") ?- ?*))
        (forward-line))
      (while (and (looking-at "[^\n]+?\\*/[ \t]*$")
                  (not (looking-at (concat "[^\n]+?" marker-re
                                           "\\*/[ \t]*$"))))
        (forward-line))
      (when (looking-at (concat "[^\n]+?" marker-re "\\*/[ \t]*$"))
        (forward-line))
      (setq end (point))
      (let ((comment (buffer-substring-no-properties begin end)))
        (with-temp-buffer
          (insert comment)
          (goto-char (point-min))
          (flush-lines (concat "^[ \t]*/\\*" marker-re "[-*]+\\*/[ \t]*$"))
          (goto-char (point-min))
          (while (re-search-forward "^[ \t]*/\\* ?" nil t)
            (goto-char (match-beginning 0))
            (delete-region (match-beginning 0) (match-end 0)))
          (goto-char (point-min))
          (while (re-search-forward "[ \t]*\\*/[ \t]*$" nil t)
            (goto-char (match-beginning 0))
            (delete-region (match-beginning 0) (match-end 0)))
          (goto-char (point-min)) (delete-trailing-whitespace)
          (goto-char (point-min)) (flush-lines "^$")
          (set-fill-column (- 80   ; width of the text
                              6    ; width of "/*  */"
                              leader-width))
          (goto-char (point-min)) (fill-paragraph nil)
          (goto-char (point-min))
          (while (not (eobp))
            (insert (make-string leader-width ? ) "/* ")
            (goto-char (line-end-position))
            (insert (make-string (- 80 3 (current-column)) ? ) " */")
            (forward-line))
          (goto-char (point-min))
          (insert (make-string leader-width ? )
                  "/*" (make-string (- 80 4 leader-width) marker) "*/\n")
          (goto-char (point-max))
          (insert (make-string leader-width ? )
                  "/*" (make-string (- 80 4 leader-width) marker) "*/\n")
          (setq comment (buffer-string)))
        (goto-char begin)
        (delete-region begin end)
        (insert comment)))
    (goto-char here)))

(defun keep-mine ()
  (interactive)
  (beginning-of-line)
  (assert (or (looking-at "<<<<<<")
              (re-search-backward "^<<<<<<" nil t)
              (re-search-forward "^<<<<<<" nil t)))
  (goto-char (match-beginning 0))
  (let ((beg (point))
        (hashes (re-search-forward "^#######" (+ (point) 10000) t)))
    (forward-line)
    (delete-region beg (point))
    (re-search-forward (if hashes "^>>>>>>>" "^======="))
    (setq beg (match-beginning 0))
    (re-search-forward (if hashes "^=======" "^>>>>>>>"))
    (forward-line)
    (delete-region beg (point))))

(defun keep-theirs ()
  (interactive)
  (beginning-of-line)
  (assert (or (looking-at "<<<<<<")
              (re-search-backward "^<<<<<<" nil t)
              (re-search-forward "^<<<<<<" nil t)))
  (goto-char (match-beginning 0))
  (let ((beg (point))
        (hashes (re-search-forward "^#######" (+ (point) 10000) t)))
    (re-search-forward (if hashes "^>>>>>>>" "^======="))
    (forward-line)
    (delete-region beg (point))
    (re-search-forward (if hashes "^#######" "^>>>>>>>"))
    (beginning-of-line)
    (setq beg (point))
    (when hashes
      (re-search-forward "^=======")
      (beginning-of-line))
    (forward-line)
    (delete-region beg (point))))

(defun keep-both ()
  (interactive)
  (beginning-of-line)
  (assert (or (looking-at "<<<<<<")
              (re-search-backward "^<<<<<<" nil t)
              (re-search-forward "^<<<<<<" nil t)))
  (beginning-of-line)
  (let ((beg (point)))
    (forward-line)
    (delete-region beg (point))
    (re-search-forward "^>>>>>>>")
    (beginning-of-line)
    (setq beg (point))
    (forward-line)
    (delete-region beg (point))
    (re-search-forward "^#######")
    (beginning-of-line)
    (setq beg (point))
    (re-search-forward "^=======")
    (beginning-of-line)
    (forward-line)
    (delete-region beg (point))))

(eval-after-load "cc-mode"
  '(progn
     (setq c-syntactic-indentation nil)

     (define-key c-mode-base-map "#" 'self-insert-command)
     (define-key c-mode-base-map "{" 'self-insert-command)
     (define-key c-mode-base-map "}" 'self-insert-command)
     (define-key c-mode-base-map "/" 'self-insert-command)
     (define-key c-mode-base-map "*" 'self-insert-command)
     (define-key c-mode-base-map ";" 'self-insert-command)
     (define-key c-mode-base-map "," 'self-insert-command)
     (define-key c-mode-base-map ":" 'self-insert-command)
     (define-key c-mode-base-map "(" 'self-insert-command)
     (define-key c-mode-base-map ")" 'self-insert-command)
     (define-key c++-mode-map "<"    'self-insert-command)
     (define-key c++-mode-map ">"    'self-insert-command)

     (define-key c-mode-base-map [(meta ?p)] 'keep-mine)
     (define-key c-mode-base-map [(meta ?n)] 'keep-theirs)
     (define-key c-mode-base-map [(alt ?b)] 'keep-both)

     (add-hook 'c-mode-common-hook 'my-c-mode-common-hook)))

(eval-after-load "cc-styles"
  '(progn
     (add-to-list
      'c-style-alist
      '("edg"
        (indent-tabs-mode . nil)
        (c-basic-offset . 3)
        (c-comment-only-line-offset . (0 . 0))
        (c-hanging-braces-alist
         . ((substatement-open before after)
            (arglist-cont-nonempty)))
        (c-offsets-alist
         . ((statement-block-intro . +)
            (knr-argdecl-intro . 5)
            (substatement-open . 0)
            (substatement-label . 0)
            (label . 0)
            (case-label . +)
            (statement-case-open . 0)
            (statement-cont . +)
            (arglist-intro . c-lineup-arglist-intro-after-paren)
            (arglist-close . c-lineup-arglist)
            (inline-open . 0)
            (brace-list-open . 0)
            (topmost-intro-cont
             . (first c-lineup-topmost-intro-cont
                      c-lineup-gnu-DEFUN-intro-cont))))
        (c-special-indent-hook . c-gnu-impose-minimum)
        (c-block-comment-prefix . "")))

     (add-to-list
      'c-style-alist
      '("ledger"
        (indent-tabs-mode . nil)
        (c-basic-offset . 2)
        (c-comment-only-line-offset . (0 . 0))
        (c-hanging-braces-alist
         . ((substatement-open before after)
            (arglist-cont-nonempty)))
        (c-offsets-alist
         . ((statement-block-intro . +)
            (knr-argdecl-intro . 5)
            (substatement-open . 0)
            (substatement-label . 0)
            (label . 0)
            (case-label . 0)
            (statement-case-open . 0)
            (statement-cont . +)
            (arglist-intro . +)
            (arglist-close . +)
            (inline-open . 0)
            (brace-list-open . 0)
            (topmost-intro-cont
             . (first c-lineup-topmost-intro-cont
                      c-lineup-gnu-DEFUN-intro-cont))))
        (c-special-indent-hook . c-gnu-impose-minimum)
        (c-block-comment-prefix . "")))

     (add-to-list
      'c-style-alist
      '("clang"
        (indent-tabs-mode . nil)
        (c-basic-offset . 2)
        (c-comment-only-line-offset . (0 . 0))
        (c-hanging-braces-alist
         . ((substatement-open before after)
            (arglist-cont-nonempty)))
        (c-offsets-alist
         . ((statement-block-intro . +)
            (knr-argdecl-intro . 5)
            (substatement-open . 0)
            (substatement-label . 0)
            (label . 0)
            (case-label . 0)
            (statement-case-open . 0)
            (statement-cont . +)
            (arglist-intro . +)
            (arglist-close . +)
            (inline-open . 0)
            (brace-list-open . 0)
            (topmost-intro-cont
             . (first c-lineup-topmost-intro-cont
                      c-lineup-gnu-DEFUN-intro-cont))))
        (c-special-indent-hook . c-gnu-impose-minimum)
        (c-block-comment-prefix . "")))))

;;;_   , ulp

(defun ulp ()
  (interactive)
  (find-file "~/src/ansi/ulp.c")
  (find-file-noselect "~/Contracts/TI/test/ulp_suite/invoke.sh")
  (find-file-noselect "~/Contracts/TI/test/ulp_suite")
  ;;(visit-tags-table "~/src/ansi/TAGS")
  (magit-status "~/src/ansi")
  (gdb "gdb --annotate=3 ~/Contracts/TI/bin/msp/acpia430"))

;;;_  . gdb

(eval-after-load "gdb-ui"
  '(defun gdb-display-buffer (buf dedicated &optional frame)
     (let ((answer (get-buffer-window buf (or frame 0))))
       (if answer
           (display-buffer buf t (or frame 0)) ;Deiconify the frame if necessary.
         (let ((window (get-lru-window)))
           (if (memq (buffer-local-value 'gud-minor-mode (window-buffer window))
                     '(gdba gdbmi))
               (let* ((largest (get-largest-window))
                      (cur-size (window-height largest)))
                 (setq answer (split-window largest))
                 (set-window-buffer answer buf)
                 (set-window-dedicated-p answer dedicated)
                 answer)
             (set-window-buffer window buf)
             window))))))

;;;_  . haskell-mode

(add-to-list 'auto-mode-alist '("\\.l?hs$" . haskell-mode))

(eval-when-compile
  (defvar haskell-check-command)
  (defvar haskell-saved-check-command)
  (defvar haskell-mode-map))

(autoload 'ghc-init "ghc" nil t)

(defun my-haskell-mode-hook ()
  (setq haskell-saved-check-command haskell-check-command)

  (ghc-init)

  (define-key haskell-mode-map [(control ?c) ?w]
    'flymake-display-err-menu-for-current-line)
  (define-key haskell-mode-map [(control ?c) ?*]
    'flymake-start-syntax-check)
  (define-key haskell-mode-map [(meta ?n)] 'flymake-goto-next-error)
  (define-key haskell-mode-map [(meta ?p)] 'flymake-goto-prev-error))

(eval-after-load "haskell-site-file"
  '(progn
     (require 'inf-haskell)
     (require 'hs-lint)))

;;;_  . lisp

(defface esk-paren-face
  '((((class color) (background dark))
     (:foreground "grey50"))
    (((class color) (background light))
     (:foreground "grey55")))
  "Face used to dim parentheses."
  :group 'starter-kit-faces)

(mapc (lambda (major-mode)
        (font-lock-add-keywords
         major-mode
         `(("(\\(lambda\\)\\>"
            (0 (ignore
                (compose-region (match-beginning 1)
                                (match-end 1) ?λ))))
           ("(\\|)" . 'esk-paren-face))))
      '(emacs-lisp-mode
        inferior-emacs-lisp-mode
        lisp-mode
        inferior-lisp-mode
        slime-repl-mode))

(defun my-byte-recompile-file ()
  (save-excursion
    (byte-recompile-file buffer-file-name)))

;;;_   , ansicl

(info-lookmore-elisp-cl)
(info-lookmore-elisp-userlast)
(info-lookmore-elisp-gnus)
(info-lookmore-apropos-elisp)

(mapc (lambda (mode)
        (info-lookup-add-help
         :mode mode
         :regexp "[^][()'\" \t\n]+"
         :ignore-case t
         :doc-spec '(("(ansicl)Symbol Index" nil nil nil))))
      '(lisp-mode slime-mode slime-repl-mode inferior-slime-mode))

(defadvice Info-exit (after remove-info-window activate)
  "When info mode is quit, remove the window."
  (if (> (length (window-list)) 1)
      (delete-window)))

;;;_   , eldoc

(eval-after-load "eldoc"
  '(diminish 'eldoc-mode))

;;;_   , elint

(defun elint-current-buffer ()
  (interactive)
  (elint-initialize)
  (elint-current-buffer))

(eval-after-load "elint"
  '(progn
     (add-to-list 'elint-standard-variables 'current-prefix-arg)
     (add-to-list 'elint-standard-variables 'command-line-args-left)
     (add-to-list 'elint-standard-variables 'buffer-file-coding-system)
     (add-to-list 'elint-standard-variables 'emacs-major-version)
     (add-to-list 'elint-standard-variables 'window-system)))

;;;_   , lisp-mode-hook

(defun my-elisp-indent-or-complete (&optional arg)
  (interactive "p")
  (call-interactively 'lisp-indent-line)
  (unless (or (looking-back "^\\s-*")
              (bolp)
              (not (looking-back "[-A-Za-z0-9_*+/=<>!?]+")))
    (call-interactively 'lisp-complete-symbol)))

(defun my-lisp-indent-or-complete (&optional arg)
  (interactive "p")
  (if (or (looking-back "^\\s-*") (bolp))
      (call-interactively 'lisp-indent-line)
    (call-interactively 'slime-indent-and-complete-symbol)))

(defvar slime-mode nil)

(defun my-lisp-mode-hook (&optional emacs-lisp-p)
  (auto-fill-mode 1)
  (paredit-mode 1)
  (redshank-mode 1)

  (let (mode-map)
    (if emacs-lisp-p
        (progn
          (require 'edebug)

          (setq mode-map emacs-lisp-mode-map)

          (define-key mode-map [(meta return)] 'outline-insert-heading)
          (define-key mode-map [tab] 'my-elisp-indent-or-complete)
          (define-key mode-map [tab] 'yas/expand))

      (turn-on-cldoc-mode)

      (setq mode-map lisp-mode-map)

      (define-key mode-map [tab] 'my-lisp-indent-or-complete)
      (define-key mode-map [(meta ?q)] 'slime-reindent-defun)
      (define-key mode-map [(meta ?l)] 'slime-selector))))

(mapc (lambda (hook)
        (add-hook hook 'my-lisp-mode-hook))
      '(lisp-mode-hook inferior-lisp-mode-hook slime-repl-mode-hook))

(add-hook 'emacs-lisp-mode-hook (function (lambda () (my-lisp-mode-hook t))))

;;;_   , paredit

(eval-after-load "paredit"
  '(diminish 'paredit-mode))

;;;_   , redhank

(eval-after-load "redshank"
  '(diminish 'redshank-mode))

;;;_  . lua-mode

(add-to-list 'auto-mode-alist '("\\.lua$" . lua-mode))
(add-to-list 'interpreter-mode-alist '("lua" . lua-mode))

;;;_  . python-mode

(add-to-list 'auto-mode-alist '("\\.py$" . python-mode))
(add-to-list 'interpreter-mode-alist '("python" . python-mode))

(info-lookup-add-help
 :mode 'python-mode
 :regexp "[a-zA-Z_0-9.]+"
 :doc-spec
 '(("(python)Python Module Index" )
   ("(python)Index"
    (lambda
      (item)
      (cond
       ((string-match
         "\\([A-Za-z0-9_]+\\)() (in module \\([A-Za-z0-9_.]+\\))" item)
        (format "%s.%s" (match-string 2 item) (match-string 1 item))))))))

(defun my-python-mode-hook ()
  (setq indicate-empty-lines t)
  (set (make-local-variable 'parens-require-spaces) nil)
  (setq indent-tabs-mode nil)

  (define-key python-mode-map [(control return)] 'other-window)
  (define-key python-mode-map [(control ?c) (control ?z)] 'python-shell)
  (define-key python-mode-map [(control ?c) ?c] 'compile))

(add-hook 'python-mode-hook 'my-python-mode-hook)

;;;_  . ruby-mode

(require 'inf-ruby)
(require 'yari)
(require 'ruby-tools nil t)

(defun my-ruby-smart-return ()
  (interactive)
  (when (memq (char-after) '(?\| ?\" ?\'))
    (forward-char))
  (call-interactively 'newline-and-indent))

(defun my-ruby-mode-hook ()
  (inf-ruby-keys)

  (define-key ruby-mode-map [return] 'my-ruby-smart-return)
  (define-key ruby-mode-map [(control ?h) (control ?i)] 'yari-anything)

  (set (make-local-variable 'yas/fallback-behavior)
       '(apply ruby-indent-command . nil))
  (define-key ruby-mode-map [tab] 'yas/expand-from-trigger-key))

(add-hook 'ruby-mode-hook 'my-ruby-mode-hook)

;;;_  . nxml-mode

(defalias 'xml-mode 'nxml-mode)

(eval-when-compile
  (defvar nxml-mode-map))

(defun my-nxml-mode-hook ()
  (define-key nxml-mode-map [return] 'newline-and-indent)
  (define-key nxml-mode-map [(control return)] 'other-window))

(add-hook 'nxml-mode-hook 'my-nxml-mode-hook)

;;;_  . shell-script

(info-lookup-add-help :mode 'shell-script-mode
                      :regexp ".*"
                      :doc-spec
                      '(("(bash)Index")))

;;;_  . zencoding

(eval-when-compile
  (defvar html-mode-map))

(defvar zencoding-mode-keymap (make-sparse-keymap))

(define-key zencoding-mode-keymap (kbd "C-c C-c") 'zencoding-expand-line)

(add-hook 'nxml-mode-hook 'zencoding-mode)
(add-hook 'html-mode-hook 'zencoding-mode)

(add-hook 'html-mode-hook
          (lambda ()
            (define-key html-mode-map [return] 'newline-and-indent)))

(defun tidy-xml-buffer ()
  (interactive)
  (save-excursion
    (call-process-region (point-min) (point-max) "tidy" t t nil
                         "-xml" "-i" "-wrap" "0" "-omit" "-q")))

(eval-after-load "nxml-mode"
  '(define-key nxml-mode-map [(control shift ?h)] 'tidy-xml-buffer))

;;;_ , Org-mode

(require 'org)
(require 'org-agenda)

;;(require 'org-crypt)
(require 'org-devonthink)
(require 'org-magit)
(require 'org-x)
(require 'ox-org)
(require 'ox-redmine)
(require 'ob-R)
(require 'ob-python)
(require 'ob-ruby)
(require 'ob-emacs-lisp)
;;(require 'ob-haskell)
(require 'ob-sh)

;;(load "org-log" t)

(defun org-find-top-category (&optional pos)
  (let ((cat
         (save-excursion
           (with-current-buffer (if pos (marker-buffer pos) (current-buffer))
             (if pos (goto-char pos))
             ;; Skip up to the topmost parent
             (while (ignore-errors (outline-up-heading 1) t))
             (ignore-errors
               (nth 4 (org-heading-components)))))))
    (if (and cat (string= cat "BoostPro"))
        cat
      (save-excursion
        (with-current-buffer (if pos (marker-buffer pos) (current-buffer))
          (org-entry-get pos "OVERLAY" t))))))

(defun jump-to-org-agenda ()
  (interactive)
  (let ((buf (get-buffer "*Org Agenda*"))
        wind)
    (if buf
        (if (setq wind (get-buffer-window buf))
            (when (called-interactively-p 'any)
              (select-window wind)
              (org-fit-window-to-buffer))
          (if (called-interactively-p 'any)
              (progn
                (select-window (display-buffer buf t t))
                (org-fit-window-to-buffer))
            (with-selected-window (display-buffer buf)
              (org-fit-window-to-buffer))))
      (call-interactively 'org-agenda-list))))

(run-with-idle-timer 300 t 'jump-to-org-agenda)

(defun org-export-tasks ()
  (interactive)
  (let ((index 1))
    (org-map-entries
     #'(lambda ()
         (outline-mark-subtree)
         (org-export-as-html 3)
         (write-file (format "%d.html" index))
         (kill-buffer (current-buffer))
         (setq index (1+ index)))
     "LEVEL=2")))

(defun org-agenda-add-overlays (&optional line)
  "Add overlays found in OVERLAY properties to agenda items.
Note that habitual items are excluded, as they already
extensively use text properties to draw the habits graph.

For example, for work tasks I like to use a subtle, yellow
background color; for tasks involving other people, green; and
for tasks concerning only myself, blue.  This way I know at a
glance how different responsibilities are divided for any given
day.

To achieve this, I have the following in my todo file:

  * Work
    :PROPERTIES:
    :CATEGORY: Work
    :OVERLAY:  (face (:background \"#fdfdeb\"))
    :END:
  ** TODO Task
  * Family
    :PROPERTIES:
    :CATEGORY: Personal
    :OVERLAY:  (face (:background \"#e8f9e8\"))
    :END:
  ** TODO Task
  * Personal
    :PROPERTIES:
    :CATEGORY: Personal
    :OVERLAY:  (face (:background \"#e8eff9\"))
    :END:
  ** TODO Task

The colors (which only work well for white backgrounds) are:

  Yellow: #fdfdeb
  Green:  #e8f9e8
  Blue:   #e8eff9

To use this function, add it to `org-agenda-finalize-hook':

  (add-hook 'org-finalize-agenda-hook 'org-agenda-add-overlays)"
  (let ((inhibit-read-only t) l c
        (buffer-invisibility-spec '(org-link)))
    (save-excursion
      (goto-char (if line (point-at-bol) (point-min)))
      (while (not (eobp))
        (let ((org-marker (get-text-property (point) 'org-marker)))
          (when (and org-marker
                     (null (overlays-at (point)))
                     (not (get-text-property (point) 'org-habit-p))
                     (string-match "\\(sched\\|dead\\|todo\\)"
                                   (get-text-property (point) 'type)))
            (let ((overlays (org-entry-get org-marker "OVERLAY" t)))
              (when overlays
                (goto-char (line-end-position))
                (let ((rest (- (window-width) (current-column))))
                  (if (> rest 0)
                      (insert (make-string rest ? ))))
                (let ((ol (make-overlay (line-beginning-position)
                                        (line-end-position)))
                      (proplist (read overlays)))
                  (while proplist
                    (overlay-put ol (car proplist) (cadr proplist))
                    (setq proplist (cddr proplist))))))))
        (forward-line)))))

(add-hook 'org-finalize-agenda-hook 'org-agenda-add-overlays)

(defun org-my-message-open (message-id)
  (gnus-goto-article
   (gnus-string-remove-all-properties (substring message-id 2))))

;;(defun org-my-message-open (message-id)
;;  (condition-case err
;;      (if (get-buffer "*Group*")
;;          (gnus-goto-article
;;           (gnus-string-remove-all-properties (substring message-id 2)))
;;        (org-mac-message-open message-id))
;;    (error
;;     (org-mac-message-open message-id))))

(add-to-list 'org-link-protocols (list "message" 'org-my-message-open nil))

(defun save-org-mode-files ()
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (eq major-mode 'org-mode)
        (if (and (buffer-modified-p) (buffer-file-name))
            (save-buffer))))))

(run-with-idle-timer 25 t 'save-org-mode-files)

(defun my-org-push-mobile ()
  (interactive)
  (with-current-buffer (find-file-noselect "~/Documents/Tasks/todo.txt")
    (org-mobile-push)))

(defun org-my-auto-exclude-function (tag)
  (and (cond
        ((string= tag "call")
         (let ((hour (nth 2 (decode-time))))
           (or (< hour 8) (> hour 21))))
        ((string= tag "errand")
         (let ((hour (nth 2 (decode-time))))
           (or (< hour 12) (> hour 17))))
        ((or (string= tag "home") (string= tag "nasim"))
         (with-temp-buffer
           (call-process "/sbin/ifconfig" nil t nil "en0" "inet")
           (call-process "/sbin/ifconfig" nil t nil "en1" "inet")
           (call-process "/sbin/ifconfig" nil t nil "bond0" "inet")
           (goto-char (point-min))
           (not (re-search-forward "inet 192\\.168\\.9\\." nil t))))
        ((string= tag "net")
         (/= 0 (call-process "/sbin/ping" nil nil nil
                             "-c1" "-q" "-t1" "mail.gnu.org")))
        ((string= tag "fun")
         org-clock-current-task))
       (concat "-" tag)))

(defun my-mobileorg-convert ()
  (interactive)
  (while (re-search-forward "^\\* " nil t)
    (goto-char (match-beginning 0))
    (insert ?*)
    (forward-char 2)
    (insert "TODO ")
    (goto-char (line-beginning-position))
    (forward-line)
    (re-search-forward "^\\[")
    (goto-char (match-beginning 0))
    (let ((uuid
           (save-excursion
             (re-search-forward "^\\*\\* Note ID: \\(.+\\)")
             (prog1
                 (match-string 1)
               (delete-region (match-beginning 0)
                              (match-end 0))))))
      (insert (format "SCHEDULED: %s\n:PROPERTIES:\n"
                      (format-time-string (org-time-stamp-format))))
      (insert (format ":ID:       %s\n:CREATED:  " uuid)))
    (forward-line)
    (insert ":END:")))

(eval-when-compile
  (require 'org-mobile))

(defun my-org-convert-incoming-items ()
  (interactive)
  (with-current-buffer
      (find-file-noselect (expand-file-name org-mobile-capture-file
                                            org-mobile-directory))
    (goto-char (point-min))
    (unless (eobp)
      (my-mobileorg-convert)
      (goto-char (point-max))
      (if (bolp)
          (delete-char -1))
      (let ((tasks (buffer-string)))
        (set-buffer-modified-p nil)
        (kill-buffer (current-buffer))
        (with-current-buffer (find-file-noselect "~/Documents/Tasks/todo.txt")
          (save-excursion
            (goto-char (point-min))
            (re-search-forward "^\\* Inbox$")
            (re-search-forward "^:END:")
            (forward-line)
            (goto-char (line-beginning-position))
            (if (and tasks (> (length tasks) 0))
                (insert tasks ?\n))))))))

;;;_Don't sync agendas.org to MobileOrg.  I do this because I only use
;;;_MobileOrg for recording new tasks on the phone, and never for viewing
;;;_tasks.  This allows MobileOrg to start up and sync extremely quickly.

;;(add-hook 'org-mobile-post-push-hook
;;          (function
;;           (lambda ()
;;             (shell-command "/bin/rm -f ~/Dropbox/MobileOrg/agendas.org")
;;             (shell-command
;;              (concat "perl -i -ne 'print unless /agendas\\.org/;'"
;;                      "~/Dropbox/MobileOrg/checksums.dat"))
;;             (shell-command
;;              (concat "perl -i -ne 'print unless /agendas\\.org/;'"
;;                      "~/Dropbox/MobileOrg/index.org")))))

(defun my-org-mobile-pre-pull-function ()
  (do-applescript "tell application \"Dropbox\" to run")
  (message "Waiting 30 seconds for Dropbox to download tasks...")
  (sleep-for 30)
  (message "Waiting 30 seconds for Dropbox to download tasks...done")
  (do-applescript "tell application \"Dropbox\" to quit")
  (my-org-convert-incoming-items))

(defun my-org-mobile-post-push-function ()
  (do-applescript "tell application \"Dropbox\" to run")
  (message "Waiting 30 seconds for Dropbox to upload tasks...")
  (sleep-for 30)
  (message "Waiting 30 seconds for Dropbox to upload tasks...done")
  (do-applescript "tell application \"Dropbox\" to quit"))

(add-hook 'org-mobile-pre-pull-hook 'my-org-mobile-pre-pull-function)
(add-hook 'org-mobile-post-push-hook 'my-org-mobile-post-push-function)

(defun org-my-state-after-clock-out (state)
  (if (string= state "STARTED")
      "TODO"
    state))

(defvar org-my-archive-expiry-days 1
  "The number of days after which a completed task should be auto-archived.
This can be 0 for immediate, or a floating point value.")

(defconst org-my-ts-regexp
  "[[<]\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} [^]>\r\n]*?\\)[]>]"
  "Regular expression for fast inactive time stamp matching.")

(defun org-my-closing-time ()
  (let* ((state-regexp
          (concat "- State \"\\(?:" (regexp-opt org-done-keywords)
                  "\\)\"\\s-*\\[\\([^]\n]+\\)\\]"))
         (regexp (concat "\\(" state-regexp "\\|" org-my-ts-regexp "\\)"))
         (end (save-excursion
                (outline-next-heading)
                (point)))
         begin
         end-time)
    (goto-char (line-beginning-position))
    (while (re-search-forward regexp end t)
      (let ((moment (org-parse-time-string (match-string 1))))
        (if (or (not end-time)
                (time-less-p (apply #'encode-time end-time)
                             (apply #'encode-time moment)))
            (setq end-time moment))))
    (goto-char end)
    end-time))

(defun org-my-archive-done-tasks ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((done-regexp
           (concat "^\\*\\* \\(" (regexp-opt org-done-keywords) "\\) ")))
      (while (re-search-forward done-regexp nil t)
        (if (>= (time-to-number-of-days
                 (time-subtract (current-time)
                                (apply #'encode-time (org-my-closing-time))))
                org-my-archive-expiry-days)
            (org-archive-subtree))))
    (save-buffer)))

(defalias 'archive-done-tasks 'org-my-archive-done-tasks)

(defun org-get-inactive-time ()
  (float-time (org-time-string-to-time
               (or (org-entry-get (point) "TIMESTAMP")
                   (org-entry-get (point) "TIMESTAMP_IA")
                   (debug)))))

(defun org-get-completed-time ()
  (let ((begin (point)))
    (save-excursion
      (outline-next-heading)
      (and (re-search-backward "\\(- State \"\\(DONE\\|DEFERRED\\|CANCELED\\)\"\\s-+\\[\\(.+?\\)\\]\\|CLOSED: \\[\\(.+?\\)\\]\\)" begin t)
           (float-time (org-time-string-to-time (or (match-string 3)
                                                    (match-string 4))))))))

(defun org-my-sort-done-tasks ()
  (interactive)
  (goto-char (point-min))
  (org-sort-entries t ?F #'org-get-inactive-time #'<)
  (goto-char (point-min))
  (while (re-search-forward "


+" nil t)
    (delete-region (match-beginning 0) (match-end 0))
    (insert "
"))
  (let (after-save-hook)
    (save-buffer))
  (org-overview))

(defalias 'sort-done-tasks 'org-my-sort-done-tasks)

(defun org-archive-done-tasks ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "\* \\(DONE\\|CANCELED\\) " nil t)
      (if (save-restriction
            (save-excursion
              (org-x-narrow-to-entry)
              (search-forward ":LOGBOOK:" nil t)))
          (forward-line)
        (org-archive-subtree)
        (goto-char (line-beginning-position))))))

(defun org-sort-all ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^\* " nil t)
      (goto-char (match-beginning 0))
      (condition-case err
          (progn
            (org-sort-entries t ?a)
            (org-sort-entries t ?p)
            (org-sort-entries t ?o)
            (forward-line))
        (error nil)))
    (goto-char (point-min))
    (while (re-search-forward "\* PROJECT " nil t)
      (goto-char (line-beginning-position))
      (ignore-errors
        (org-sort-entries t ?a)
        (org-sort-entries t ?p)
        (org-sort-entries t ?o))
      (forward-line))))

(defun org-cleanup ()
  (interactive)
  (org-archive-done-tasks)
  (org-sort-all)
  ;;(org-x-normalize-all-entries)
  )

(defun org-maybe-remember (&optional done)
  (interactive "P")
  (if (string= (buffer-name) "*Remember*")
      (call-interactively 'org-ctrl-c-ctrl-c)
    (if (null done)
        (call-interactively 'org-remember)
      (let ((org-capture-templates
             '((110 "* STARTED %?
- State \"STARTED\"    %U
SCHEDULED: %t
:PROPERTIES:
:ID:       %(shell-command-to-string \"uuidgen\"):CREATED:  %U
:END:" "~/Documents/Tasks/todo.txt" "Inbox"))))
        (org-remember))))
  (set-fill-column 72))

(defun org-inline-note ()
  (interactive)
  (switch-to-buffer-other-window "todo.txt")
  (goto-char (point-min))
  (re-search-forward "^\\* Inbox$")
  (re-search-forward "^:END:")
  (forward-line)
  (goto-char (line-beginning-position))
  (insert "** NOTE ")
  (save-excursion
    (insert (format "
:PROPERTIES:
:ID:       %s   :VISIBILITY: folded
:CREATED:  %s
:END:" (shell-command-to-string "uuidgen")
   (format-time-string (org-time-stamp-format t t))))
    (insert ?\n))
  (save-excursion
    (forward-line)
    (org-cycle)))

;;(defun org-get-apple-message-link ()
;;  (let ((subject (do-applescript "tell application \"Mail\"
;;        set theMessages to selection
;;        subject of beginning of theMessages
;;end tell"))
;;        (message-id (do-applescript "tell application \"Mail\"
;;        set theMessages to selection
;;        message id of beginning of theMessages
;;end tell")))
;;    (org-make-link-string (concat "message://" message-id) subject)))
;;
;;(defun org-get-message-sender ()
;;  (do-applescript "tell application \"Mail\"
;;        set theMessages to selection
;;        sender of beginning of theMessages
;;end tell"))
;;
;;(defun org-insert-apple-message-link ()
;;  (interactive)
;;  (insert (org-get-apple-message-link)))

(defun org-get-message-link (&optional title)
  (assert (get-buffer "*Group*"))
  (let (message-id subject)
    (with-current-buffer gnus-original-article-buffer
      (setq message-id (substring (message-field-value "message-id") 1 -1)
            subject (or title (message-field-value "subject"))))
    (org-make-link-string (concat "message://" message-id) subject)))

(defun org-insert-message-link (&optional arg)
  (interactive "P")
  (insert (org-get-message-link (if arg "writes"))))

(defun org-set-message-link ()
  "Set a property for the current headline."
  (interactive)
  (org-set-property "Message" (org-get-message-link)))

(defun org-get-message-sender ()
  (assert (get-buffer "*Group*"))
  (let (message-id subject)
    (with-current-buffer gnus-original-article-buffer
      (message-field-value "from"))))

(defun org-set-message-sender ()
  "Set a property for the current headline."
  (interactive)
  (org-set-property "Submitter" (org-get-message-sender)))

(defun org-get-safari-link ()
  (let ((subject (substring (do-applescript "tell application \"Safari\"
        name of document of front window
end tell") 1 -1))
        (url (substring (do-applescript "tell application \"Safari\"
        URL of document of front window
end tell") 1 -1)))
    (org-make-link-string url subject)))

(defun org-get-chrome-link ()
  (let ((subject (do-applescript "tell application \"Google Chrome\"
        title of active tab of front window
end tell"))
        (url (do-applescript "tell application \"Google Chrome\"
        URL of active tab of front window
end tell")))
    (org-make-link-string (substring url 1 -1) (substring subject 1 -1))))

(defun org-insert-url-link ()
  (interactive)
  (insert (org-get-chrome-link)))

(defun org-set-url-link ()
  "Set a property for the current headline."
  (interactive)
  (org-set-property "URL" (org-get-chrome-link)))

;;(defun org-get-file-link ()
;;  (let ((subject (do-applescript "tell application \"Finder\"
;;      set theItems to the selection
;;      name of beginning of theItems
;;end tell"))
;;        (path (do-applescript "tell application \"Finder\"
;;      set theItems to the selection
;;      POSIX path of (beginning of theItems as text)
;;end tell")))
;;    (org-make-link-string (concat "file:" path) subject)))
;;
;;(defun org-insert-file-link ()
;;  (interactive)
;;  (insert (org-get-file-link)))
;;
;;(defun org-set-file-link ()
;;  "Set a property for the current headline."
;;  (interactive)
;;  (org-set-property "File" (org-get-file-link)))

(defun org-set-dtp-link ()
  "Set a property for the current headline."
  (interactive)
  (org-set-property "Document" (org-get-dtp-link)))

(defun org-dtp-message-open ()
  "Visit the message with the given MESSAGE-ID.
This will use the command `open' with the message URL."
  (interactive)
  (re-search-backward "\\[\\[message://\\(.+?\\)\\]\\[")
  (do-applescript
   (format "tell application \"DEVONthink Pro\"
        set searchResults to search \"%%3C%s%%3E\" within URLs
        open window for record (get beginning of searchResults)
end tell" (match-string 1))))

(fset 'orgify-line
   [?\C-k ?\C-o ?t ?o ?d ?o tab ?\C-y backspace ?\C-a ?l ?\C-u ?\C-n ?\C-n ?\C-n])

(add-hook 'org-log-buffer-setup-hook
          (lambda ()
            (setq fill-column (- fill-column 5))))

(defun org-message-reply ()
  (interactive)
  (let* ((org-marker (get-text-property (point) 'org-marker))
         (submitter (org-entry-get (or org-marker (point)) "Submitter"))
         (subject (if org-marker
                      (with-current-buffer (marker-buffer org-marker)
                        (goto-char org-marker)
                        (nth 4 (org-heading-components)))
                    (nth 4 (org-heading-components)))))
    (setq subject (replace-regexp-in-string "\\`(.*?) " "" subject))
    (compose-mail-other-window submitter (concat "Re: " subject))))

;;;_  . make-bug-link

(defun make-ledger-bugzilla-bug (product component version priority severity)
  (interactive
   (let ((omk (get-text-property (point) 'org-marker)))
     (with-current-buffer (marker-buffer omk)
       (save-excursion
         (goto-char omk)
         (let ((components
                (list "data" "doc" "expr" "lisp" "math" "python" "report"
                      "test" "util" "website" "build" "misc"))
               (priorities (list "P1" "P2" "P3" "P4" "P5"))
               (severities (list "blocker" "critical" "major"
                                 "normal" "minor" "trivial" "enhancement"))
               (product "Ledger")
               (version "3.0.0-20120217"))
           (list product
                 (ido-completing-read "Component: " components
                                      nil t nil nil (car (last components)))
                 version
                 (let ((orgpri (nth 3 (org-heading-components))))
                   (cond
                    ((and orgpri (= ?A orgpri))
                     "P1")
                    ((and orgpri (= ?C orgpri))
                     "P3")
                    (t
                     (ido-completing-read "Priority: " priorities
                                          nil t nil nil "P2"))))
                 (ido-completing-read "Severity: " severities nil t nil nil
                                      "normal") ))))))
  (let ((omk (get-text-property (point) 'org-marker)))
    (with-current-buffer (marker-buffer omk)
      (save-excursion
        (goto-char omk)
        (let ((heading (nth 4 (org-heading-components)))
              (contents (buffer-substring-no-properties
                         (org-entry-beginning-position)
                         (org-entry-end-position)))
              bug)
          (with-temp-buffer
            (insert contents)
            (goto-char (point-min))
            (delete-region (point) (1+ (line-end-position)))
            (search-forward ":PROP")
            (delete-region (match-beginning 0) (point-max))
            (goto-char (point-min))
            (while (re-search-forward "^   " nil t)
              (delete-region (match-beginning 0) (match-end 0)))
            (goto-char (point-min))
            (while (re-search-forward "^SCHE" nil t)
              (delete-region (match-beginning 0) (1+ (line-end-position))))
            (goto-char (point-min))
            (when (eobp)
              (insert "No description.")
              (goto-char (point-min)))
            (insert (format "Product: %s
Component: %s
Version: %s
Priority: %s
Severity: %s
Hardware: Other
OS: Other
Summary: %s" product component version priority severity heading) ?\n ?\n)
            (let ((buf (current-buffer)))
              (with-temp-buffer
                (let ((tmpbuf (current-buffer)))
                  (if nil
                      (insert "Bug 999 posted.")
                    (with-current-buffer buf
                      (shell-command-on-region
                       (point-min) (point-max)
                       "~/bin/bugzilla-submit http://bugs.ledger-cli.org/"
                       tmpbuf)))
                  (goto-char (point-min))
                  (or (re-search-forward "Bug \\([0-9]+\\) posted." nil t)
                      (debug))
                  (setq bug (match-string 1))))))
          (save-excursion
            (org-back-to-heading t)
            (re-search-forward "\\(TODO\\|DEFERRED\\|STARTED\\|WAITING\\|DELEGATED\\) \\(\\[#[ABC]\\] \\)?")
            (insert (format "[[bug:%s][#%s]] " bug bug)))))))
  (org-agenda-redo))

(defun make-bug-link ()
  (interactive)
  (let* ((omk (get-text-property (point) 'org-marker))
         (path (with-current-buffer (marker-buffer omk)
                 (save-excursion
                   (goto-char omk)
                   (org-get-outline-path)))))
    (cond
     ((string-match "/ledger/" (buffer-file-name (marker-buffer omk)))
      (call-interactively #'make-ledger-bugzilla-bug))
     ((string= "BoostPro" (car path))
      (call-interactively #'org-x-redmine-post-issue))
     (t
      (error "Cannot make bug, unknown category")))))

;;;_  . keybindings

(defvar org-mode-completion-keys
  '((?d . "DONE")
    (?g . "DELEGATED")
    (?n . "NOTE")
    (?r . "DEFERRED")
    (?s . "STARTED")
    (?t . "TODO")
    (?w . "WAITING")
    (?x . "CANCELED")
    (?y . "SOMEDAY")
    ))

(defvar org-todo-state-map nil)
(define-prefix-command 'org-todo-state-map)

(dolist (ckey org-mode-completion-keys)
  (let* ((key (car ckey))
         (label (cdr ckey))
         (org-sym (intern (concat "my-org-todo-" (downcase label))))
         (org-sym-no-logging
          (intern (concat "my-org-todo-" (downcase label) "-no-logging")))
         (org-agenda-sym
          (intern (concat "my-org-agenda-todo-" (downcase label))))
         (org-agenda-sym-no-logging
          (intern (concat "my-org-agenda-todo-"
                          (downcase label) "-no-logging"))))
    (eval
     `(progn
        (defun ,org-sym ()
          (interactive)
          (org-todo ,label))
        (define-key mode-specific-map [?x ,key] ',org-sym)

        (defun ,org-sym-no-logging ()
          (interactive)
          (let ((org-inhibit-logging t))
            (org-todo ,label)))
        (define-key mode-specific-map [?x ,(upcase key)]
          ',org-sym-no-logging)

        (defun ,org-agenda-sym ()
          (interactive)
          (org-agenda-todo ,label))
        (define-key org-todo-state-map [,key] ',org-agenda-sym)

        (defun ,org-agenda-sym-no-logging ()
          (interactive)
          (let ((org-inhibit-logging t))
            (org-agenda-todo ,label)))
        (define-key org-todo-state-map [,(upcase key)]
          ',org-agenda-sym-no-logging)))))

(define-key mode-specific-map [?x ?l] 'org-insert-dtp-link)
(define-key mode-specific-map [?x ?L] 'org-set-dtp-link)

(define-key mode-specific-map [?x ?m] 'org-insert-message-link)
(define-key mode-specific-map [?x ?M] 'org-set-message-link)
;;(define-key mode-specific-map [?x ?a] 'org-insert-apple-message-link)
(define-key mode-specific-map [?x ?Y] 'org-set-message-sender)

(define-key mode-specific-map [?x ?u] 'org-insert-url-link)
(define-key mode-specific-map [?x ?U] 'org-set-url-link)

(define-key mode-specific-map [?x ?f] 'org-insert-file-link)
(define-key mode-specific-map [?x ?F] 'org-set-file-link)

(autoload 'ledger-test-create "ldg-test" nil t)
(autoload 'ledger-test-run "ldg-test" nil t)

(add-to-list 'auto-mode-alist '("\\.test$" . ledger-mode))

(eval-after-load "org"
  '(progn
     (org-defkey org-mode-map [(control meta return)]
                 'org-insert-heading-after-current)
     (org-defkey org-mode-map [(control return)] 'other-window)
     (org-defkey org-mode-map [return] 'org-return-indent)
     (org-defkey org-mode-map
                 [(control ?c) (control ?x) ?@] 'visible-mode)

     (define-prefix-command 'my-org-expand-map)
     (define-key org-mode-map [(control ?c) (control ?e)] 'my-org-expand-map)

     (define-key my-org-expand-map [(control ?t)] 'ledger-test-create)))

(defun yas/org-very-safe-expand ()
  (let ((yas/fallback-behavior 'return-nil)) (yas/expand)))

(eval-when-compile
  (defvar yas/keymap))

(add-hook 'org-mode-hook
          (lambda ()
            (set (make-local-variable 'yas/trigger-key) [tab])
            (add-to-list 'org-tab-first-hook 'yas/org-very-safe-expand)
            (define-key yas/keymap [tab] 'yas/next-field-or-maybe-expand)))

(remove-hook 'kill-emacs-hook 'org-babel-remove-temporary-directory)

;;;_  . org-agenda-mode

(let ((map org-agenda-mode-map))
  (define-key map "\C-n" 'next-line)
  (define-key map "\C-p" 'previous-line)

  (define-key map "g" 'org-agenda-redo)
  (define-key map "f" 'org-agenda-date-later)
  (define-key map "b" 'org-agenda-date-earlier)
  (define-key map "r" 'org-agenda-refile)
  (define-key map " " 'org-agenda-tree-to-indirect-buffer)
  (define-key map "F" 'org-agenda-follow-mode)
  (define-key map "q" 'delete-window)
  (define-key map [(meta ?p)] 'org-agenda-earlier)
  (define-key map [(meta ?n)] 'org-agenda-later)
  (define-key map "x" 'org-todo-state-map)

  (define-key map ">" 'org-agenda-filter-by-top-category)

  (define-key org-todo-state-map "z" 'make-bug-link))

(defun org-fit-agenda-window ()
  "Fit the window to the buffer size."
  (and (memq org-agenda-window-setup '(reorganize-frame))
       (fboundp 'fit-window-to-buffer)
       (fit-window-to-buffer)))

(defadvice org-agenda-redo (after fit-windows-for-agenda-redo activate)
  "Fit the Org Agenda to its buffer."
  (org-fit-agenda-window))

(defadvice org-agenda (after fit-windows-for-agenda activate)
  "Fit the Org Agenda to its buffer."
  (org-fit-agenda-window))

;;;_ , Gnus

(require 'gnus)
(require 'nnir)
(require 'nnmairix)
(require 'message)
(require 'starttls)
(require 'my-gnus-score)
(require 'gnus-harvest)
(require 'fetchmail-ctl)

(eval-when-compile
  (require 'gnus-group)
  (require 'gnus-sum))

(defface gnus-summary-expirable-face
  '((((class color) (background dark))
     (:foreground "grey50" :italic t :strike-through t))
    (((class color) (background light))
     (:foreground "grey55" :italic t :strike-through t)))
  "Face used to highlight articles marked as expirable."
  :group 'gnus-summary-visual)

(gnus-compile)
(gnus-delay-initialize)

(gnus-harvest-install 'message-x)

(add-hook 'message-setup-hook 'gnus-alias-determine-identity)
(add-hook 'message-x-after-completion-functions
          'gnus-alias-message-x-completion)

(add-hook 'mail-citation-hook 'sc-cite-original)

(add-hook 'gnus-group-mode-hook 'gnus-topic-mode)
(add-hook 'gnus-group-mode-hook 'hl-line-mode)
(add-hook 'gnus-summary-mode-hook 'hl-line-mode)

(add-hook 'dired-mode-hook 'gnus-dired-mode)

(defalias 'gnus-user-format-function-size 'rs-gnus-summary-line-message-size)

(setq gnus-balloon-face-0 'rs-gnus-balloon-0)
(setq gnus-balloon-face-1 'rs-gnus-balloon-1)

(defun quickping (host)
  (= 0 (call-process "/sbin/ping" nil nil nil "-c1" "-W50" "-q" host)))

(defun maybe-start-fetchmail-and-news ()
  (interactive)
  (when (quickping "imap.gmail.com")
    (do-applescript "tell application \"Notify\" to run")
    (start-fetchmail)
    (fetchnews-fetch)))

(add-hook 'gnus-startup-hook 'maybe-start-fetchmail-and-news)

(defun my-message-header-setup-hook ()
  (let ((group (or gnus-newsgroup-name "")))
    (message-remove-header "From")
    (message-remove-header "Gcc")
    (message-add-header
     (format "Gcc: %s" (if (string-match "\\`list\\." group)
                           "mail.sent"
                         "INBOX")))))

(add-hook 'message-header-setup-hook 'my-message-header-setup-hook)

(defun queue-message-if-not-connected ()
  (set (make-local-variable 'gnus-agent-queue-mail)
       (if (quickping "smtp.gmail.com") t 'always)))

(add-hook 'message-send-hook 'queue-message-if-not-connected)

(defun kick-postfix-if-needed ()
  (if (and (quickping "imap.gmail.com")
           (= 0 (call-process "/usr/bin/sudo" nil nil nil
                              "/opt/local/libexec/postfix/master" "-t")))
      (start-process "postfix" nil "/usr/bin/sudo"
                     "/opt/local/libexec/postfix/master" "-e" "60")))

(add-hook 'message-sent-hook 'kick-postfix-if-needed)

(eval-after-load "message"
  '(define-key message-mode-map "\C-c\C-f\C-p" 'gnus-alias-select-identity))

(defun activate-gnus ()
  (unless (get-buffer "*Group*") (gnus)))

(defvar gnus-query-history nil)

(defun gnus-query (query &optional arg)
  (interactive
   (list (read-string "Mail Query: "
                      (format-time-string "SINCE %d-%b-%Y "
                                          (time-subtract (current-time)
                                                         (days-to-time 90)))
                      'gnus-query-history)
         current-prefix-arg))
  (activate-gnus)
  (let ((nnir-imap-default-search-key "imap")
        (nnir-ignored-newsgroups
         (if arg
             nnir-ignored-newsgroups
           "\\(list\\.\\|mail\\.\\(spam\\)\\)")))
    (gnus-group-make-nnir-group
     nil `((query    . ,query)
           (criteria . "")
           (server   . "nnimap:Local")))))

(define-key global-map [(alt meta ?f)] 'gnus-query)

(defun gnus-group-get-all-new-news ()
  (interactive)
  (gnus-group-get-new-news 5)
  (gnus-group-list-groups 4)
  (my-gnus-score-groups)
  (gnus-group-list-groups 4))

(eval-after-load "gnus-group"
  '(define-key gnus-group-mode-map [?v ?g] 'gnus-group-get-all-new-news))

(defun gnus-demon-scan-news-2 ()
  (when gnus-plugged
    (let ((win (current-window-configuration))
          (gnus-read-active-file nil)
          (gnus-check-new-newsgroups nil)
          (gnus-verbose 2)
          (gnus-verbose-backends 5)
          (level 21))
      (unwind-protect
          (save-window-excursion
            (when (gnus-alive-p)
              (with-current-buffer gnus-group-buffer
                (gnus-group-get-new-news level))))
        (set-window-configuration win)))))

(gnus-demon-add-handler 'gnus-demon-scan-news-2 5 2)

(defun gnus-goto-article (message-id)
  (activate-gnus)
  (gnus-summary-read-group "INBOX" 15 t)
  (gnus-summary-refer-article message-id))

(defun gmail-report-spam ()
  "Report the current or marked mails as spam.
This moves them into the Spam folder."
  (interactive)
  (gnus-summary-move-article nil "mail.spam"))

;;;_  . Cleanup Gnus buffers on exit

(defun exit-gnus-on-exit ()
  (if (and (fboundp 'gnus-group-exit)
           (gnus-alive-p))
      (with-current-buffer (get-buffer "*Group*")
        (let (gnus-interactive-exit)
          (gnus-group-exit)))))

(add-hook 'kill-emacs-hook 'exit-gnus-on-exit)

(defun save-gnus-newsrc ()
  (if (and (fboundp 'gnus-group-exit)
           (gnus-alive-p))
      (with-current-buffer (get-buffer "*Group*")
        (gnus-save-newsrc-file))))

(gnus-demon-add-handler 'save-gnus-newsrc nil 1)

;;;_  . Summary line format functions

(when window-system
  (setq
   gnus-sum-thread-tree-false-root      "┌┬▷ "
   gnus-sum-thread-tree-single-indent   ""
   gnus-sum-thread-tree-root            "┌┬▶ "
   gnus-sum-thread-tree-vertical        "│"
   gnus-sum-thread-tree-leaf-with-other "├┬▶ "
   gnus-sum-thread-tree-single-leaf     "╰┬▶ "
   gnus-sum-thread-tree-indent          " "))

(defsubst dot-gnus-tos (time)
  "Convert TIME to a floating point number."
  (+ (* (car time) 65536.0)
     (cadr time)
     (/ (or (car (cdr (cdr time))) 0) 1000000.0)))

(defun gnus-user-format-function-S (header)
  "Return how much time it's been since something was sent."
  (condition-case err
      (let ((date (mail-header-date header)))
        (if (> (length date) 0)
            (let*
                ((then (dot-gnus-tos
                        (apply 'encode-time (parse-time-string date))))
                 (now (dot-gnus-tos (current-time)))
                 (diff (- now then))
                 (str
                  (cond
                   ((>= diff (* 86400.0 7.0 52.0))
                    (if (>= diff (* 86400.0 7.0 52.0 10.0))
                        (format "%3dY" (floor (/ diff (* 86400.0 7.0 52.0))))
                      (format "%3.1fY" (/ diff (* 86400.0 7.0 52.0)))))
                   ((>= diff (* 86400.0 30.0))
                    (if (>= diff (* 86400.0 30.0 10.0))
                        (format "%3dM" (floor (/ diff (* 86400.0 30.0))))
                      (format "%3.1fM" (/ diff (* 86400.0 30.0)))))
                   ((>= diff (* 86400.0 7.0))
                    (if (>= diff (* 86400.0 7.0 10.0))
                        (format "%3dw" (floor (/ diff (* 86400.0 7.0))))
                      (format "%3.1fw" (/ diff (* 86400.0 7.0)))))
                   ((>= diff 86400.0)
                    (if (>= diff (* 86400.0 10.0))
                        (format "%3dd" (floor (/ diff 86400.0)))
                      (format "%3.1fd" (/ diff 86400.0))))
                   ((>= diff 3600.0)
                    (if (>= diff (* 3600.0 10.0))
                        (format "%3dh" (floor (/ diff 3600.0)))
                      (format "%3.1fh" (/ diff 3600.0))))
                   ((>= diff 60.0)
                    (if (>= diff (* 60.0 10.0))
                        (format "%3dm" (floor (/ diff 60.0)))
                      (format "%3.1fm" (/ diff 60.0))))
                   (t
                    (format "%3ds" (floor diff)))))
                 (stripped
                  (replace-regexp-in-string "\\.0" "" str)))
              (concat (cond
                       ((= 2 (length stripped)) "  ")
                       ((= 3 (length stripped)) " ")
                       (t ""))
                      stripped))))
    (error "    ")))

(eval-when-compile
  (defvar gnus-ignored-from-addresses))

(defvar gnus-count-recipients-threshold 5
  "*Number of recipients to consider as large.")

(defun gnus-user-format-function-r (header)
  "Given a Gnus message header, returns priority mark.
If I am the only recipient, return \"!\".
If I am one of a few recipients, but I'm listed in To:, return \"*\".
If I am one of a few recipients, return \"/\".
If I am one of many recipients, return \".\".
Else, return \" \"."
  (let* ((to (or (cdr (assoc 'To (mail-header-extra header))) ""))
         (cc (or (cdr (assoc 'Cc (mail-header-extra header))) "")))
    (cond
     ((string-match gnus-ignored-from-addresses to)
      (let ((len (length (split-string to "\\s-*,\\s-*"))))
        (cond
         ((and (= len 1) (string= cc "")) "▻")
         ((= len 1) "►")
         ((< len gnus-count-recipients-threshold) "»")
         (t "☀"))))
     ((string-match gnus-ignored-from-addresses
                    (concat to ", " cc))
      (if (< (length (split-string (concat to ", " cc) "\\s-*,\\s-*"))
             gnus-count-recipients-threshold)
          "·"
        ":"))
     (t " "))))

;;;_  . Browsing article URLs

(eval-when-compile
  (defvar gnus-button-url-regexp))

(defun gnus-article-get-urls-region (min max)
  "Return a list of urls found in the region between MIN and MAX"
  (let (url-list)
    (save-excursion
      (save-restriction
        (narrow-to-region min max)
        (goto-char (point-min))
        (while (re-search-forward gnus-button-url-regexp nil t)
          (let ((match-string (match-string-no-properties 0)))
            (if (and (not (equal (substring match-string 0 4) "file"))
                     (not (member match-string url-list)))
                (setq url-list (cons match-string url-list)))))))
    url-list))

(defun gnus-article-get-current-urls ()
  "Return a list of the urls found in the current `gnus-article-buffer'"
  (let (url-list)
    (with-current-buffer gnus-article-buffer
      (setq url-list (gnus-article-get-urls-region (point-min) (point-max))))
    url-list))

(defun gnus-article-browse-urls ()
  "Visit a URL from the `gnus-article-buffer' by prompting via a
    poping up a buffer showing the list of URLs found with the
    `gnus-button-url-regexp'."
  (interactive)
  (gnus-configure-windows 'article)
  (gnus-summary-select-article nil nil 'pseudo)
  (let ((temp-buffer (generate-new-buffer " *Article URLS*"))
        (urls (gnus-article-get-current-urls))
        (this-window (selected-window))
        (browse-window (get-buffer-window gnus-article-buffer))
        (count 0))
    (save-excursion
      (save-window-excursion
        (with-current-buffer temp-buffer
         (mapc (lambda (string)
                 (insert (format "\t%d: %s\n" count string))
                 (setq count (1+ count))) urls)
         (not-modified)
         (pop-to-buffer temp-buffer)
         (setq count
               (string-to-number
                (char-to-string (if (fboundp
                                     'read-char-exclusive)
                                    (read-char-exclusive)
                                  (read-char)))))
         (kill-buffer temp-buffer)))
      (if browse-window
          (progn (select-window browse-window)
                 (browse-url (nth count urls)))))
    (select-window this-window)))

;;;_  . Gnus keybindings

(eval-after-load "gnus-sum"
  '(progn
     (define-key gnus-summary-mode-map [(meta ?q)]
       'gnus-article-fill-long-lines)
     (define-key gnus-summary-mode-map [?$] 'gmail-report-spam)
     (define-key gnus-summary-mode-map [?B delete]
       'gnus-summary-delete-article)

     (defun my-gnus-trash-article (arg)
       (interactive "P")
       (if (string-match "\\(drafts\\|queue\\)" gnus-newsgroup-name)
           (gnus-summary-delete-article arg)
         (gnus-summary-move-article arg "mail.trash")))

     (define-key gnus-summary-mode-map [?B backspace] 'my-gnus-trash-article)
     (define-key gnus-summary-mode-map [(control ?c) (control ?o)]
       'gnus-article-browse-urls)))

(eval-after-load "gnus-art"
  '(progn
     (define-key gnus-article-mode-map [(meta ?q)]
       'gnus-article-fill-long-lines)
     (define-key gnus-summary-mode-map [?$] 'gmail-report-spam)
     (define-key gnus-summary-mode-map [?B delete]
       'gnus-summary-delete-article)

     (defun my-gnus-trash-article (arg)
       (interactive "P")
       (if (string-match "\\(drafts\\|queue\\)" gnus-newsgroup-name)
           (gnus-summary-delete-article arg)
         (gnus-summary-move-article arg "mail.trash")))

     (define-key gnus-summary-mode-map [?B backspace] 'my-gnus-trash-article)
     (define-key gnus-summary-mode-map [(control ?c) (control ?o)]
       'gnus-article-browse-urls)))

;;;_. Keybindings

;;;_ , global-map

(when using-textexpander
  ;;(define-key override-global-map [(alt ?v)] 'scroll-down)
  (define-key global-map [(alt ?v)] 'scroll-down)
  (define-key override-global-map [(meta ?v)] 'yank)
  (define-key global-map [(meta ?v)] 'yank))

(defun wikipedia-query (term)
  (interactive (list (read-string "Wikipedia search: " (word-at-point))))
  (w3m-search "en.wikipedia" term))

(defun wolfram-alpha-query (term)
  (interactive (list (read-string "Ask Wolfram Alpha: " (word-at-point))))
  (w3m-browse-url (format "http://m.wolframalpha.com/input/?i=%s"
                          (w3m-search-escape-query-string term))))

(define-key global-map [(alt meta ?g)] 'w3m-search)
(define-key global-map [(alt meta ?h)] 'wolfram-alpha-query)
(define-key global-map [(alt meta ?w)] 'wikipedia-query)

(define-key global-map [(control ?h) (control ?i)] 'info-lookup-symbol)

(eval-after-load "w3m"
  '(let (proxy-host proxy-port)
     (with-temp-buffer
       (shell-command "scutil --proxy" (current-buffer))
       (when (re-search-forward "HTTPPort : \\([0-9]+\\)" nil t)
         (setq proxy-port (match-string 1)))
       (when (re-search-forward "HTTPProxy : \\(\\S-+\\)" nil t)
         (setq proxy-host (match-string 1))))
     (when (and proxy-host proxy-port)
       (setq w3m-command-arguments
             (nconc w3m-command-arguments
                    (list "-o" (format "http_proxy=http://%s:%s/"
                                       proxy-host proxy-port)))))

     (add-hook 'w3m-mode-hook 'w3m-type-ahead-mode)

     (define-key w3m-minor-mode-map "\C-m"
       'w3m-view-url-with-external-browser)))

;;;_  . f?

(define-key global-map [f9] 'gud-cont)
(define-key global-map [f10] 'gud-next)
(define-key global-map [f11] 'gud-step)
(define-key global-map [(shift f11)] 'gud-finish)

;;;_  . C-?

(define-key global-map [(control return)] 'other-window)

(define-key global-map [(control ?z)] 'collapse-or-expand)

;;;_  . M-?

(autoload 'anything-lisp-complete-symbol-partial-match
  "anything-complete" nil t)

(define-key global-map [(meta ?,)] 'anything-resume)
(define-key global-map [(meta ?/)] 'dabbrev-expand)
(define-key global-map [(meta ??)] 'anything-lisp-complete-symbol-partial-match)

(define-key global-map [(meta ?g) ?g] 'anything-find-git-file)

(defun delete-indentation-forward ()
  (interactive)
  (delete-indentation t))

(define-key global-map [(meta ?n)] 'ignore)
(define-key global-map [(meta ?p)] 'ignore)

(define-key global-map [(meta ?j)] 'delete-indentation-forward)
(define-key global-map [(meta ?J)] 'delete-indentation)

(defvar gnus-unbury-window-configuration nil)

(defun switch-to-gnus (&optional arg)
  (interactive "P")
  (let ((alist '(("\\`\\*unsent")
                 ("\\`\\*Article")
                 ("\\`\\*Summary")
                 ("\\`\\*Group"
                  (lambda (buf)
                    (with-current-buffer buf
                      (gnus-group-get-new-news))))))
        candidate)
    (catch 'found
      (dolist (item alist)
        (let ((regexp (nth 0 item))
              (test (nth 1 item))
              last)
          (dolist (buf (buffer-list))
            (if (string-match regexp (buffer-name buf))
                (setq last buf)))
          (if (and last (or (null test)
                            (funcall test last)))
              (throw 'found (setq candidate last))))))
    (if candidate
        (ido-visit-buffer candidate ido-default-buffer-method)
      (let ((gnus-startup-hook (if arg nil gnus-startup-hook)))
        (gnus)))))

(defun show-compilation ()
  (interactive)
  (let ((compile-buf
         (catch 'found
           (dolist (buf (buffer-list))
             (if (string-match "\\*compilation\\*" (buffer-name buf))
                 (throw 'found buf))))))
    (if compile-buf
        (switch-to-buffer-other-window compile-buf)
      (call-interactively 'compile))))

(defun show-debugger ()
  (interactive)
  (let ((gud-buf
         (catch 'found
           (dolist (buf (buffer-list))
             (if (string-match "\\*gud-" (buffer-name buf))
                 (throw 'found buf))))))
    (if gud-buf
        (switch-to-buffer-other-window gud-buf)
      (call-interactively 'gud-gdb))))

(define-key global-map [(meta shift ?o)] 'show-compilation)
(define-key global-map [(meta shift ?b)] 'show-debugger)
(define-key global-map [(meta shift ?c)] 'jump-to-org-agenda)
(define-key global-map [(meta shift ?g)] 'switch-to-gnus)
(define-key global-map [(meta ?m)] 'org-smart-capture)
(define-key global-map [(meta shift ?m)] 'org-inline-note)
;;(define-key global-map [(meta shift ?t)] 'tags-search)
(define-key global-map [(meta shift ?t)] 'anything-gtags-select)

(defun find-grep-in-project (command-args)
  (interactive
   (progn
     (list (read-shell-command
            "Run find (like this): "
            '("git ls-files -z | xargs -P4 -0 egrep -nH -e " . 45)
            'grep-find-history))))
  (when command-args
    (let ((null-device nil))            ; see grep
      (grep command-args))))

(defun my-anything-occur ()
  (interactive)
  (require 'anything-config)
  (anything-other-buffer 'anything-c-source-occur "*Anything Occur*"))

(define-key global-map [(meta ?s) ?a] 'anything-do-grep)
(define-key global-map [(meta ?s) ?b] 'my-anything-occur)
(define-key global-map [(meta ?s) ?c] 'highlight-changes-mode)
(define-key global-map [(meta ?s) ?d] 'find-grep-dired)
(define-key global-map [(meta ?s) ?f] 'find-grep)
(define-key global-map [(meta ?s) ?F] 'anything-for-files)
(define-key global-map [(meta ?s) ?g] 'grep)
(define-key global-map [(meta ?s) ?h] 'crosshairs-mode)
(define-key global-map [(meta ?s) ?l] 'hl-line-mode)
(define-key global-map [(meta ?s) ?n] 'find-name-dired)
(define-key global-map [(meta ?s) ?o] 'occur)
(define-key global-map [(meta ?s) ?p] 'find-grep-in-project)
(define-key global-map [(meta ?s) ?r] 'highlight-regexp)
(define-key global-map [(meta ?s) ?R] 'highlight-lines-matching-regexp)
(define-key global-map [(meta ?s) ?w] 'highlight-phrase)

(define-key global-map [remap eval-expression] 'pp-eval-expression)

(define-key global-map [(meta ?\')] 'insert-pair)
(define-key global-map [(meta ?\")] 'insert-pair)

(defun align-code (beg end &optional arg)
  (interactive "rP")
  (if (null arg)
      (align beg end)
    (let ((end-mark (copy-marker end)))
      (indent-region beg end-mark nil)
      (align beg end-mark))))

(define-key global-map [(meta ?\[)] 'align-code)
(define-key global-map [(meta ?`)]  'other-frame)

(defun mark-line (&optional arg)
  (interactive "p")
  (beginning-of-line)
  (let ((here (point)))
    (dotimes (i arg)
      (end-of-line))
    (set-mark (point))
    (goto-char here)))

(defun mark-sentence (&optional arg)
  (interactive "P")
  (backward-sentence)
  (mark-end-of-sentence arg))

(define-key global-map [(meta shift ?w)] 'mark-word)
(define-key global-map [(meta shift ?l)] 'mark-line)
(define-key global-map [(meta shift ?s)] 'mark-sentence)
(define-key global-map [(meta shift ?x)] 'mark-sexp)
(define-key global-map [(meta shift ?h)] 'mark-paragraph)
(define-key global-map [(meta shift ?d)] 'mark-defun)

(define-key global-map [(meta alt ?w)] 'copy-code-as-rtf)

;;;_  . C-M-?

(define-key global-map [(control meta backspace)] 'backward-kill-sexp)

(defun isearch-backward-other-window ()
  (interactive)
  (split-window-vertically)
  (call-interactively 'isearch-backward))

(define-key global-map [(control meta ?r)]
  'isearch-backward-other-window)

(defun isearch-forward-other-window ()
  (interactive)
  (split-window-vertically)
  (call-interactively 'isearch-forward))

(define-key global-map [(control meta ?s)]
  'isearch-forward-other-window)

(defun collapse-or-expand ()
  (interactive)
  (if (> (length (window-list)) 1)
      (delete-other-windows)
    (bury-buffer)))

;;;_  . A-?

(if t
    (define-key key-translation-map (kbd "A-TAB") (kbd "M-TAB"))
  (define-key key-translation-map [(alt tab)] [(meta tab)]))

;;;_ , ctl-x-map

(defun ido-switch-buffer-tiny-frame (buffer)
  (interactive (list (ido-read-buffer "Buffer: " nil t)))
  (with-selected-frame
      (make-frame '((width                . 80)
                    (height               . 22)
                    (left-fringe          . 0)
                    (right-fringe         . 0)
                    (vertical-scroll-bars . nil)
                    (unsplittable         . t)
                    (has-modeline-p       . nil)
                    ;;(background-color     . "grey80")
                    (minibuffer           . nil)))
    (switch-to-buffer buffer)
    (set (make-local-variable 'mode-line-format) nil)))

(define-key ctl-x-map [?5 ?t] 'ido-switch-buffer-tiny-frame)

(eval-when-compile
  (require 'bookmark))

(defun ido-bookmark-jump (bookmark &optional display-func)
  (interactive
   (list
    (ido-completing-read "Jump to bookmark: "
                         (mapcar #'car bookmark-alist)
                         nil 0 nil 'bookmark-history)))
  (unless bookmark
    (error "No bookmark specified"))
  (bookmark-maybe-historicize-string bookmark)
  (bookmark--jump-via bookmark (or display-func 'switch-to-buffer)))

(define-key ctl-x-map [?r ?b] 'ido-bookmark-jump)

(defun edit-with-sudo ()
  (interactive)
  (find-file (concat "/sudo::" (buffer-file-name))))

(define-key ctl-x-map [?d] 'delete-whitespace-rectangle)
(define-key ctl-x-map [?f] 'anything-find-git-file)
(define-key ctl-x-map [(shift ?f)] 'set-fill-column)
(define-key ctl-x-map [?g] 'magit-status)
(define-key ctl-x-map [?m] 'compose-mail)
(define-key ctl-x-map [(shift ?s)] 'edit-with-sudo)
(define-key ctl-x-map [?t] 'toggle-truncate-lines)

;;;_  . C-x C-?

(define-key ctl-x-map [(control ?b)] 'ibuffer)

(defun duplicate-line ()
  "Duplicate the line containing point."
  (interactive)
  (save-excursion
    (let (line-text)
      (goto-char (line-beginning-position))
      (let ((beg (point)))
        (goto-char (line-end-position))
        (setq line-text (buffer-substring beg (point))))
      (if (eobp)
          (insert ?\n)
        (forward-line))
      (open-line 1)
      (insert line-text))))

(define-key ctl-x-map [(control ?d)] 'duplicate-line)
(define-key ctl-x-map [(control ?e)] 'pp-eval-last-sexp)
(define-key ctl-x-map [(control ?n)] 'next-line)
(define-key ctl-x-map [(control ?z)] 'eshell-toggle)

;;;_  . C-x M-?

(define-key ctl-x-map [(meta ?n)] 'set-goal-column)

(defun refill-paragraph (arg)
  (interactive "*P")
  (let ((fun (if (memq major-mode '(c-mode c++-mode))
                 'c-fill-paragraph
               (or fill-paragraph-function
                   'fill-paragraph)))
        (width (if (numberp arg) arg))
        prefix beg end)
    (forward-paragraph 1)
    (setq end (copy-marker (- (point) 2)))
    (forward-line -1)
    (let ((b (point)))
      (skip-chars-forward "^A-Za-z0-9`'\"(")
      (setq prefix (buffer-substring-no-properties b (point))))
    (backward-paragraph 1)
    (if (eolp)
        (forward-char))
    (setq beg (point-marker))
    (delete-horizontal-space)
    (while (< (point) end)
      (delete-indentation 1)
      (end-of-line))
    (let ((fill-column (or width fill-column))
          (fill-prefix prefix))
      (if prefix
          (setq fill-column
                (- fill-column (* 2 (length prefix)))))
      (funcall fun nil)
      (goto-char beg)
      (insert prefix)
      (funcall fun nil))
    (goto-char (+ end 2))))

(define-key ctl-x-map [(meta ?q)] 'refill-paragraph)

(define-key ctl-x-map [(meta ?z)] 'shell-toggle)

;;;_ , mode-specific-map

;;;_  . C-c ?

(define-key mode-specific-map [tab] 'ff-find-other-file)

(define-key mode-specific-map [space] 'just-one-space)
(define-key mode-specific-map [? ] 'just-one-space)

;; inspired by Erik Naggum's `recursive-edit-with-single-window'
(defmacro recursive-edit-preserving-window-config (body)
  "*Return a command that enters a recursive edit after executing BODY.
 Upon exiting the recursive edit (with\\[exit-recursive-edit] (exit)
 or \\[abort-recursive-edit] (abort)), restore window configuration
 in current frame."
  `(lambda ()
     "See the documentation for `recursive-edit-preserving-window-config'."
     (interactive)
     (save-window-excursion
       ,body
       (recursive-edit))))

(define-key mode-specific-map [?0]
  (recursive-edit-preserving-window-config (delete-window)))
(define-key mode-specific-map [?1]
  (recursive-edit-preserving-window-config
   (if (one-window-p 'ignore-minibuffer)
       (error "Current window is the only window in its frame")
     (delete-other-windows))))

(define-key mode-specific-map [?a] 'org-agenda)

(defun switch-to-bitlbee ()
  (interactive)
  (switch-to-buffer-other-window "&bitlbee")
  (call-interactively 'erc-channel-names)
  (goto-char (point-max)))

(define-key mode-specific-map [?b] 'switch-to-bitlbee)

(define-key mode-specific-map [?c] 'compile)
(define-key mode-specific-map [?C] 'indirect-region)

(defun delete-current-line (&optional arg)
  (interactive "p")
  (let ((here (point)))
    (beginning-of-line)
    (kill-line arg)
    (goto-char here)))

(define-key mode-specific-map [?d] 'delete-current-line)

(defun do-eval-buffer ()
  (interactive)
  (call-interactively 'eval-buffer)
  (message "Buffer has been evaluated"))

(defun find-which (name)
  (interactive "sCommand name: ")
  (find-file-other-window
   (substring (shell-command-to-string (format "which %s" name)) 0 -1)))

(define-key mode-specific-map [?e ?E] 'elint-current-buffer)
(define-key mode-specific-map [?e ?b] 'do-eval-buffer)
(define-key mode-specific-map [?e ?c] 'cancel-debug-on-entry)
(define-key mode-specific-map [?e ?d] 'debug-on-entry)
(define-key mode-specific-map [?e ?e] 'toggle-debug-on-error)
(define-key mode-specific-map [?e ?f] 'emacs-lisp-byte-compile-and-load)
(define-key mode-specific-map [?e ?l] 'find-library)
(define-key mode-specific-map [?e ?r] 'eval-region)
(define-key mode-specific-map [?e ?s] 'scratch)
(define-key mode-specific-map [?e ?v] 'edit-variable)
(define-key mode-specific-map [?e ?w] 'find-which)
(define-key mode-specific-map [?e ?z] 'byte-recompile-directory)

(define-key mode-specific-map [?f] 'flush-lines)
(define-key mode-specific-map [?g] 'goto-line)
(define-key mode-specific-map [?G] 'gist-region-or-buffer)
(define-key mode-specific-map [?h] 'crosshairs-mode)

(define-key mode-specific-map [?i ?b] 'flyspell-buffer)
(define-key mode-specific-map [?i ?c] 'ispell-comments-and-strings)
(define-key mode-specific-map [?i ?d] 'ispell-change-dictionary)
(define-key mode-specific-map [?i ?f] 'flyspell-mode)
(define-key mode-specific-map [?i ?k] 'ispell-kill-ispell)
(define-key mode-specific-map [?i ?m] 'ispell-message)
(define-key mode-specific-map [?i ?r] 'ispell-region)

;; (define-key mode-specific-map [?j] 'dired-jump-other-window)

(defun my-activate-sunrise ()
  (interactive)
  (let ((sunrise-exists
         (count-if (lambda (buf)
                     (string-match " (Sunrise)$" (buffer-name buf)))
                   (buffer-list))))
    (if (> sunrise-exists 0)
        (call-interactively 'sunrise)
      (sunrise "~/dl/" "~/Archives/"))))

(define-key mode-specific-map [?j] 'my-activate-sunrise)
(define-key mode-specific-map [(control ?j)] 'sunrise-cd)

(defun dired-double-jump (first-dir second-dir)
  (interactive
   (list (ido-read-directory-name "First directory: "
                                  (expand-file-name "~") nil nil "dl/")
         (ido-read-directory-name "Second directory: "
                                  (expand-file-name "~") nil nil "Archives/")))
  (if t
      (sunrise first-dir second-dir)
    (dired first-dir)
    (dired-other-window second-dir)))

(define-key mode-specific-map [?J] 'dired-double-jump)

(define-key mode-specific-map [?k] 'keep-lines)

(defun my-ledger-start-entry (&optional arg)
  (interactive "p")
  (find-file-other-window "~/Documents/Accounts/ledger.dat")
  (goto-char (point-max))
  (skip-syntax-backward " ")
  (if (looking-at "\n\n")
      (goto-char (point-max))
    (delete-region (point) (point-max))
    (insert ?\n)
    (insert ?\n))
  (insert (format-time-string "%Y/%m/%d ")))

(define-key mode-specific-map [?L] 'my-ledger-start-entry)

(defun ledger-matchup ()
  (interactive)
  (while (re-search-forward "\\(\\S-+Unknown\\)\\s-+\\$\\([-,0-9.]+\\)" nil t)
    (let ((account-beg (match-beginning 1))
          (account-end (match-end 1))
          (amount (match-string 2))
          account answer)
      (goto-char account-beg)
      (set-window-point (get-buffer-window) (point))
      (recenter)
      (redraw-display)
      (with-current-buffer (get-buffer "nrl-mastercard-old.dat")
        (goto-char (point-min))
        (when (re-search-forward (concat "\\(\\S-+\\)\\s-+\\$" amount) nil t)
          (setq account (match-string 1))
          (goto-char (match-beginning 1))
          (set-window-point (get-buffer-window) (point))
          (recenter)
          (redraw-display)
          (setq answer
                (read-char (format "Is this a match for %s (y/n)? "
                                   account)))))
      (when (eq answer ?y)
        (goto-char account-beg)
        (delete-region account-beg account-end)
        (insert account))
      (forward-line))))

(defun emacs-min ()
  (interactive)
  (set-frame-parameter (selected-frame) 'fullscreen nil)
  (set-frame-parameter (selected-frame) 'vertical-scroll-bars nil)
  (set-frame-parameter (selected-frame) 'horizontal-scroll-bars nil)
  (set-frame-parameter (selected-frame) 'top 26)
  (set-frame-parameter (selected-frame) 'left
                       (- (x-display-pixel-width)
                          (if (>= emacs-major-version 24)
                              925
                            920)))
  (set-frame-parameter (selected-frame) 'width 100)
  (if (= 1050 (x-display-pixel-height))
      (set-frame-parameter (selected-frame) 'height
                           (if (>= emacs-major-version 24)
                               66
                             100))
    (set-frame-parameter (selected-frame) 'height
                         (if (>= emacs-major-version 24)
                             76
                           100))))

(defun emacs-max ()
  (interactive)
  (if t
      (progn
        (set-frame-parameter (selected-frame) 'fullscreen 'fullboth)
        (set-frame-parameter (selected-frame) 'vertical-scroll-bars nil)
        (set-frame-parameter (selected-frame) 'horizontal-scroll-bars nil))
    (set-frame-parameter (selected-frame) 'top 26)
    (set-frame-parameter (selected-frame) 'left 2)
    (set-frame-parameter (selected-frame) 'width
                         (floor (/ (float (x-display-pixel-width)) 9.15)))
    (if (= 1050 (x-display-pixel-height))
        (set-frame-parameter (selected-frame) 'height
                             (if (>= emacs-major-version 24)
                                 66
                               55))
      (set-frame-parameter (selected-frame) 'height
                           (if (>= emacs-major-version 24)
                               75
                             64)))))

(defun emacs-toggle-size ()
  (interactive)
  (if (> (cdr (assq 'width (frame-parameters))) 100)
      (emacs-min)
    (emacs-max)))

(define-key mode-specific-map [?m] 'emacs-toggle-size)

(defun markdown-preview-file ()
  "run Marked on the current file and revert the buffer"
  (interactive)
  (shell-command
   (format "open -a /Applications/Marked.app %s"
           (shell-quote-argument (buffer-file-name)))))

(add-to-list 'auto-mode-alist '("\\.md$" . markdown-mode))

(define-key mode-specific-map [shift ?m] 'markdown-preview-file)

(defcustom user-initials nil
  "*Initials of this user."
  :set
  #'(lambda (symbol value)
      (if (fboundp 'font-lock-add-keywords)
          (mapc
           #'(lambda (mode)
               (font-lock-add-keywords
                mode (list (list (concat "\\<\\(" value " [^:\n]+\\):")
                                 1 font-lock-warning-face t))))
           '(c-mode c++-mode emacs-lisp-mode lisp-mode
                    python-mode perl-mode java-mode groovy-mode)))
      (set symbol value))
  :type 'string
  :group 'mail)

(defun insert-user-timestamp ()
  "Insert a quick timestamp using the value of `user-initials'."
  (interactive)
  (insert (format "%s (%s): " user-initials
                  (format-time-string "%Y-%m-%d" (current-time)))))

(define-key mode-specific-map [?n] 'insert-user-timestamp)
(define-key mode-specific-map [?o] 'customize-option)
(define-key mode-specific-map [?O] 'customize-group)

(defvar printf-index 0)

(defun insert-counting-printf (arg)
  (interactive "P")
  (if arg
      (setq printf-index 0))
  (if t
      (insert (format "std::cerr << \"step %d..\" << std::endl;\n"
                      (setq printf-index (1+ printf-index))))
    (insert (format "printf(\"step %d..\\n\");\n"
                    (setq printf-index (1+ printf-index)))))
  (forward-line -1)
  (indent-according-to-mode)
  (forward-line))

(define-key mode-specific-map [?p] 'insert-counting-printf)

(define-key mode-specific-map [?q] 'fill-region)
(define-key mode-specific-map [?r] 'replace-regexp)
(define-key mode-specific-map [?s] 'replace-string)

(define-key mode-specific-map [?S] 'org-store-link)
(define-key mode-specific-map [?l] 'org-insert-link)

(define-key mode-specific-map [?t ?.] 'gtags-find-rtag)
(define-key mode-specific-map [?t ?f] 'gtags-find-file)
(define-key mode-specific-map [?t ?p] 'gtags-parse-file)
(define-key mode-specific-map [?t ?g] 'gtags-find-with-grep)
(define-key mode-specific-map [?t ?i] 'gtags-find-with-idutils)
(define-key mode-specific-map [?t ?s] 'gtags-find-symbol)
(define-key mode-specific-map [?t ?r] 'gtags-find-rtag)
(define-key mode-specific-map [?t ?v] 'gtags-visit-rootdir)

;;(define-key mode-specific-map [?t ?%] 'tags>-query-replace)
;;(define-key mode-specific-map [?t ?a] 'tags-apropos)
;;(define-key mode-specific-map [?t ?e] 'tags-search)
;;(define-key mode-specific-map [?t ?v] 'visit-tags-table)

(define-key mode-specific-map [?u] 'rename-uniquely)
(define-key mode-specific-map [?v] 'ffap)

(defun view-clipboard ()
  (interactive)
  (delete-other-windows)
  (switch-to-buffer "*Clipboard*")
  (let ((inhibit-read-only t))
    (erase-buffer)
    (clipboard-yank)
    (goto-char (point-min))
    (html-mode)
    (view-mode)))

(define-key mode-specific-map [?V] 'view-clipboard)

(define-key mode-specific-map [?w ?f] 'yaoddmuse-browse-page-default)
(define-key mode-specific-map [?w ?e] 'yaoddmuse-edit-default)
(define-key mode-specific-map [?w ?p] 'yaoddmuse-post-library-default)

(define-key mode-specific-map [?z] 'clean-buffer-list)

(define-key mode-specific-map [?\[] 'align-regexp)
(define-key mode-specific-map [?=]  'count-matches)
(define-key mode-specific-map [?\;] 'comment-or-uncomment-region)

;;;_  . C-c C-?

(define-key mode-specific-map [(control ?r)] 'quickrun)

(defun delete-to-end-of-buffer ()
  (interactive)
  (kill-region (point) (point-max)))

(define-key mode-specific-map [(control ?z)] 'delete-to-end-of-buffer)

;;;_  . C-c M-?

(defun unfill-paragraph (arg)
  (interactive "*p")
  (let (beg end)
    (forward-paragraph arg)
    (setq end (copy-marker (- (point) 2)))
    (backward-paragraph arg)
    (if (eolp)
        (forward-char))
    (setq beg (point-marker))
    (when (> (count-lines beg end) 1)
      (while (< (point) end)
        (goto-char (line-end-position))
        (let ((sent-end (memq (char-before) '(?. ?\; ?! ??))))
          (delete-indentation 1)
          (if sent-end
              (insert ? )))
        (end-of-line))
      (save-excursion
        (goto-char beg)
        (while (re-search-forward "[^.;!?:]\\([ \t][ \t]+\\)" end t)
          (replace-match " " nil nil nil 1))))))

(defun unfill-region (beg end)
  (interactive "r")
  (setq end (copy-marker end))
  (save-excursion
    (goto-char beg)
    (while (< (point) end)
      (unfill-paragraph 1)
      (forward-paragraph))))

(define-key mode-specific-map [(meta ?q)] 'unfill-paragraph)

;;;_ , help-map

(define-key help-map [?a] 'anything-apropos)

(defun scratch ()
  (interactive)
  (switch-to-buffer-other-window (get-buffer-create "*scratch*"))
  ;;(lisp-interaction-mode)
  (text-mode)
  (goto-char (point-min))
  (when (looking-at ";")
    (forward-line 4)
    (delete-region (point-min) (point)))
  (goto-char (point-max)))

(defun my-describe-symbol  (symbol &optional mode)
  (interactive
   (info-lookup-interactive-arguments 'symbol current-prefix-arg))
  (let (info-buf find-buf desc-buf cust-buf)
    (save-window-excursion
      (ignore-errors
        (info-lookup-symbol symbol mode)
        (setq info-buf (get-buffer "*info*")))
      (let ((sym (intern-soft symbol)))
        (when sym
          (if (functionp sym)
              (progn
                (find-function sym)
                (setq find-buf (current-buffer))
                (describe-function sym)
                (setq desc-buf (get-buffer "*Help*")))
            (find-variable sym)
            (setq find-buf (current-buffer))
            (describe-variable sym)
            (setq desc-buf (get-buffer "*Help*"))
            ;;(customize-variable sym)
            ;;(setq cust-buf (current-buffer))
            ))))

    (delete-other-windows)

    (flet ((switch-in-other-buffer
            (buf)
            (when buf
              (split-window-vertically)
              (switch-to-buffer-other-window buf))))
      (switch-to-buffer find-buf)
      (switch-in-other-buffer desc-buf)
      (switch-in-other-buffer info-buf)
      ;;(switch-in-other-buffer cust-buf)
      (balance-windows))))

(defvar lisp-find-map)
(define-prefix-command 'lisp-find-map)
(define-key help-map [?e] 'lisp-find-map)
(define-key lisp-find-map [?a] 'my-anything-apropos)
(define-key lisp-find-map [?c] 'finder-commentary)
(define-key lisp-find-map [?e] 'view-echo-area-messages)
(define-key lisp-find-map [?f] 'find-function)
(define-key lisp-find-map [?F] 'find-face-definition)
(define-key lisp-find-map [?d] 'my-describe-symbol)
(define-key lisp-find-map [?i] 'info-apropos)
(define-key lisp-find-map [?k] 'find-function-on-key)
(define-key lisp-find-map [?l] 'find-library)
(define-key lisp-find-map [?s] 'scratch)
(define-key lisp-find-map [?v] 'find-variable)

;;;_. Post initialization

(when window-system
  (add-hook 'after-init-hook 'emacs-min)
  (add-hook 'after-init-hook 'server-start t)
  (if nil
      (add-hook 'after-init-hook
                (lambda ()
                  (org-agenda-list)
                  (org-fit-agenda-window)
                  (org-resolve-clocks)) t))
  )

;; Local Variables:
;;   mode: emacs-lisp
;;   mode: allout
;;   after-save-hook: (my-byte-recompile-file)
;;   outline-regexp: "^;;;_\\([,. ]+\\)"
;; End:

;;; emacs.el ends here
