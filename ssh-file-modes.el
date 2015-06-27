;;; ssh-file-modes.el --- major modes for ssh authorized_keys and known_hosts files

;; Copyright (C) 2015 Peter Eisentraut

;; Author: Peter Eisentraut <peter@eisentraut.org>
;; URL: https://github.com/petere/emacs-ssh-file-modes
;; Version: 0
;; Keywords: languages

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This library provides `ssh-authorized-keys-mode' and
;; `ssh-known-hosts-mode'.  The focus is on proper syntax tables and
;; font-lock configuration for legible display and easy navigation.
;; There aren't any special editing commands or key bindings.
;;
;; The minor mode `ssh-abbreviated-keys-mode' makes some part of the
;; SSH keys invisible so that the content of the files fits better on
;; the screen.  It is enabled by default, but it can be turned off by
;; running `(ssh-abbreviated-keys-mode 0)'.

;;; Code:

(defgroup ssh-file nil
  "Modes for editing SSH files"
  :group 'tools)

(defgroup ssh-file-faces nil
  "Faces for highlighting SSH files"
  :prefix "ssh-file-"
  :group 'ssh-file-
  :group 'faces)

(defface ssh-file-hashed-hostname-face
  '((t (:inherit font-lock-preprocessor-face)))
  "Face used to highlight hashed host names in SSH files"
  :group 'ssh-file-faces)

(defface ssh-file-key-face
  '((t (:inherit font-lock-string-face)))
  "Face used to highlight keys in SSH files"
  :group 'ssh-file-faces)

(defface ssh-file-key-type-face
  '((t (:inherit font-lock-constant-face)))
  "Face used to highlight key types in SSH files"
  :group 'ssh-file-faces)

(defun ssh-abbreviated-keys-overlay ()
  "Create overlay for making part of key invisible."
  (save-excursion
    (goto-char 1)
    (while (re-search-forward  "\\<AAAA\\(?:\\s_\\|\\w\\)\\{8\\}\\(\\(?:\\s_\\|\\w\\)+\\)\\(?:\\s_\\|\\w\\)\\{8\\}" nil t)
      (let ((ov (make-overlay (match-beginning 1) (match-end 1))))
        (overlay-put ov 'evaporate t)
        (overlay-put ov 'invisible 'ssh-file-key)))))

(define-minor-mode ssh-abbreviated-keys-mode
  "Minor mode that hides parts of lengthy SSH keys."
  :init-value t
  (if ssh-abbreviated-keys-mode
      (progn
        (ssh-abbreviated-keys-overlay)
        (add-to-invisibility-spec '(ssh-file-key . t)))
    (remove-from-invisibility-spec '(ssh-file-key . t))))

(defvar ssh-authorized-keys-mode-hook nil
  "*Hook to setup `ssh-authorized-keys-mode'.")

(defvar ssh-authorized-keys-mode-font-lock-keywords
  (list
   `(,(regexp-opt '("cert-authority"
                    "command"
                    "environment"
                    "from"
                    "no-agent-forwarding"
                    "no-port-forwarding"
                    "no-pty"
                    "no-user-rc"
                    "no-X11-forwarding"
                    "permitopen"
                    "principals"
                    "tunnel") 'words) . font-lock-keyword-face)
   `(,(regexp-opt '("ecdsa-sha2-nistp256"
                    "ecdsa-sha2-nistp384"
                    "ecdsa-sha2-nistp521"
                    "ssh-ed25519"
                    "ssh-dss"
                    "ssh-rsa") 'words) . 'ssh-file-key-type-face)
   '("\\<AAAA\\(?:\\s_\\|\\w\\)+" . 'ssh-file-key-face)
   '("\\<AAAA\\(?:\\s_\\|\\w\\)+\\s-+\\(.+\\)$" . (1 font-lock-comment-face)) ;; trailing comment
   ))

(defvar ssh-authorized-keys-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?/ "_" table)  ;; part of key
    (modify-syntax-entry ?+ "_" table)  ;; part of key
    (modify-syntax-entry ?= "_" table)  ;; part of key
    (modify-syntax-entry ?. "_" table)  ;; part of user@host in comments
    (modify-syntax-entry ?@ "_" table)  ;; part of user@host in comments
    table)
  "Syntax table used by `ssh-authorized-keys-mode'.")

;;;###autoload
(defun ssh-authorized-keys-mode ()
  "Major mode for ssh authorized_keys files."
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'ssh-known-hosts-mode
        mode-name "SSH[authorized_keys]")
  (set-syntax-table ssh-authorized-keys-mode-syntax-table)
  (setq comment-start "#"
        comment-end "")
  (setq font-lock-defaults '(ssh-authorized-keys-mode-font-lock-keywords nil t))
  (setq truncate-lines t)
  (ssh-abbreviated-keys-mode (symbol-value 'ssh-abbreviated-keys-mode))
  (run-hooks 'ssh-authorized-keys-mode-hook))

;;;###autoload
(add-to-list 'auto-mode-alist '(".ssh/authorized_keys2?\\'" . ssh-authorized-keys-mode))

(defvar ssh-known-hosts-mode-hook nil
  "*Hook to setup `ssh-known-hosts-mode'.")

(defvar ssh-known-hosts-mode-font-lock-keywords
  (list
   `(,(regexp-opt '("@cert-authority") 'words) . font-lock-keyword-face)
   `(,(regexp-opt '("@revoked") 'words) . font-lock-warning-face)
   `(,(regexp-opt '("!")) . font-lock-negation-char-face)
   '("|\\S-+" . 'ssh-file-hashed-hostname-face)
   '("^\\(?:\\s-*@[a-z-]+\\)?\\s-*\\S-+\\s-+\\(\\S-+\\)" . (1 'ssh-file-key-type-face))
   '("^\\(?:\\s-*@[a-z-]+\\)?\\s-*\\S-+\\s-+\\S-+\\s-+\\(\\(?:\\s_\\|\\w\\)+\\)" . (1 'ssh-file-key-face))
   '("^\\(?:\\s-*@[a-z-]+\\)?\\s-*\\S-+\\s-+\\S-+\\s-+\\(?:\\s_\\|\\w\\)+\\s-+\\(.+\\)$" . (1 font-lock-comment-face)))) ;; trailing comment

(defvar ssh-known-hosts-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?/ "_" table)  ;; part of key
    (modify-syntax-entry ?+ "_" table)  ;; part of key
    (modify-syntax-entry ?= "_" table)  ;; part of key
    (modify-syntax-entry ?. "_" table)  ;; part of host names
    (modify-syntax-entry ?: "_" table)  ;; host:port
    (modify-syntax-entry ?? "_" table)  ;; wildcard
    (modify-syntax-entry ?* "_" table)  ;; wildcard
    (modify-syntax-entry ?! "." table)
    (modify-syntax-entry ?@ "w" table)  ;; marker prefix
    table)
  "Syntax table used by `ssh-known-hosts-mode'.")

;;;###autoload
(defun ssh-known-hosts-mode ()
  "Major mode for ssh known_hosts files."
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'ssh-known-hosts-mode
        mode-name "SSH[known_hosts]")
  (set-syntax-table ssh-known-hosts-mode-syntax-table)
  (setq comment-start "#"
        comment-end "")
  (setq font-lock-defaults '(ssh-known-hosts-mode-font-lock-keywords))
  (setq truncate-lines t)
  (ssh-abbreviated-keys-mode (symbol-value 'ssh-abbreviated-keys-mode))
  (run-hooks 'ssh-known-hosts-mode-hook))

;;;###autoload
(add-to-list 'auto-mode-alist '(".ssh/known_hosts\\'" . ssh-known-hosts-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("ssh_known_hosts\\'" . ssh-known-hosts-mode))

(provide 'ssh-file-modes)

;;; ssh-file-modes.el ends here
