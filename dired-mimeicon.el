;;; dired-mimeicon.el --- Dired Mimetype Icon Mode  -*- lexical-binding: t; -*-

;; Filename: dired-mimeicon.el
;; Description: Dired Mimetype Icon Mode for Emacs.
;; Author: Reion Wong <reionwong@gmail.com>
;; Maintainer: Reion Wong <reionwong@gmail.com>
;; Copyright (C) 2023, Reion Wong, all rights reserved.
;; Created: 2023-02-27 02:24:17 +0800
;; Version: 0.1
;; Last-Updated: 2023-02-27 02:24:17 +0800
;; URL: https://github.com/reionwong/dired-mimeicon
;; Keywords:
;; Compatibility: emacs-version >= 27
;;
;; Please check README
;;

;;; Code:
(require 'cl-lib)
(require 'dired)

(defgroup dired-mimeicon nil
  "Group dired mimeicon"
  :group 'edit)

(defcustom dired-mimeicon-name "Qogir"
  "The name of the icon theme"
  :type 'string
  :group 'dired-mimeicon)

(defconst dired-mimeicon-root-dir
  (expand-file-name "themes" (file-name-directory load-file-name)))

(defvar dired-mimeicon-dir
  (concat dired-mimeicon-root-dir "/" dired-mimeicon-name "/"))

(defun dired-mimeicon-overlays-in (begin-point end-point)
  (cl-remove-if-not
   (lambda (cur-overlay)
     (overlay-get cur-overlay 'dired-mimeicon-overlay))
   (overlays-in begin-point end-point)))

(defun dired-mimeicon-clear-overlays ()
  "Remove all overlays."
  (save-restriction
    (widen)
    (mapc #'delete-overlay
	  (dired-mimeicon-overlays-in (point-min) (point-max)))))

(defun dired-mimeicon-insert-icon-to-overlay (pos icon-filename)
  "Add ICONS"
  (let ((cur-overlay (make-overlay (1- pos) pos)))
    (overlay-put cur-overlay 'dired-mimeicon-overlay t)
    (overlay-put cur-overlay 'display (create-image icon-filename 'svg nil
						    :ascent 'center
						    :width '26
						    :height '26))
    (overlay-put cur-overlay 'after-string " ")
    ;; (overlay-put cur-overlay 'after-string (propertize " " 'face `(:background ,(face-attribute 'hl-line :background))))
    ))

(defun dired-mimeicon-refresh ()
  "Refresh the dired buffer."
  (dired-mimeicon-clear-overlays)
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (when (dired-move-to-filename nil)
	(let ((filename (dired-get-filename 'relative 'noerror)))
	  (when filename
	    (setq mimetype "")
	    (let* ((mime-type (mailcap-extension-to-mime
			       (file-name-extension filename t)))
		   overlay)
	      (if mime-type
		  (setq mimetype (replace-regexp-in-string "/" "-" mime-type))
		))
	    (let ((icon-filename (if (file-directory-p filename)
				     (concat dired-mimeicon-dir "inode-directory.svg")
				   (concat dired-mimeicon-dir mimetype ".svg")
				   )))
	      (unless (and icon-filename (file-exists-p icon-filename))
		(setq icon-filename (concat dired-mimeicon-dir "application-x-sharedlib.svg"))
		)
	      (dired-mimeicon-insert-icon-to-overlay (point) icon-filename)
	      ))))
      (forward-line 1))))

(defun dired-mimeicon-refresh-advice (fn &rest args)
  "Advice function for FN with ARGS."
  (apply fn args)
  (when dired-mimeicon-mode
    (dired-mimeicon-refresh)
    )
  )

(defun dired-mimeicon-enable ()
  "Enable the Dired Mimeicon Mode."
  (when (derived-mode-p 'dired-mode)
    (advice-add 'dired-readin :around #'dired-mimeicon-refresh-advice)
    (advice-add 'dired-revert :around #'dired-mimeicon-refresh-advice)
    (advice-add 'dired-do-kill-lines :around #'dired-mimeicon-refresh-advice)
    (advice-add 'dired-insert-subdir :around #'dired-mimeicon-refresh-advice)
    (advice-add 'dired-internal-do-deletions :around #'dired-mimeicon-refresh-advice)
    (with-eval-after-load 'dired-narrow
      (advice-add 'dired-narrow--internal :around #'dired-mimeicon-refresh-advice)
      )
    (dired-mimeicon-refresh)
    )
  )

(defun dired-mimeicon-disable ()
  "Is not enabled Dired Mimeicon Mode."
  (dired-mimeicon-clear-overlays)
  (advice-remove 'dired-readin #'dired-mimeicon-refresh-advice)
  (advice-remove 'dired-revert #'dired-mimeicon-refresh-advice)
  (advice-remove 'dired-do-kill-lines #'dired-mimeicon-refresh-advice)
  (advice-remove 'dired-insert-subdir #'dired-mimeicon-refresh-advice)
  (advice-remove 'dired-internal-do-deletions #'dired-mimeicon-refresh-advice)
  (advice-remove 'dired-narrow--internal #'dired-mimeicon-refresh-advice)
  )

;;;###autoload
(define-minor-mode dired-mimeicon-mode
  "Use mimetype icon as dired buffer display."
  :lighter "dired-mimeicon-mode"
  (when (and (derived-mode-p 'dired-mode) (display-graphic-p))
    (if dired-mimeicon-mode
	(dired-mimeicon-enable)
      (dired-mimeicon-disable))))

(provide 'dired-mimeicon)
