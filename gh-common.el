;;; gh-common.el --- common objects for gh.el

;; Copyright (C) 2011  Yann Hodique

;; Author: Yann Hodique <yann.hodique@gmail.com>
;; Keywords:

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;

;;; Code:

(eval-when-compile
  (require 'cl))

(require 'eieio)

(defclass gh-object ()
  ())

(defmethod gh-object-read :static ((obj gh-object) data)
  (let ((target (if (object-p obj) obj
                  (make-instance obj))))
    (gh-object-read-into target data)
    target))

(defmethod gh-object-reader :static ((obj gh-object))
  (apply-partially 'gh-object-read obj))

(defmethod gh-object-list-read :static ((obj gh-object) data)
  (mapcar (gh-object-reader obj) data))

(defmethod gh-object-list-reader :static ((obj gh-object))
  (apply-partially 'gh-object-list-read obj))

(defmethod gh-object-read-into ((obj gh-object) data))

(defclass gh-user (gh-object)
  ((login :initarg :login)
   (id :initarg :id)
   (gravatar-url :initarg :gravatar-url)
   (url :initarg :url))
  "Github user object")

(defmethod gh-object-read-into ((user gh-user) data)
  (call-next-method)
  (with-slots (login id gravatar-url url)
      user
    (setq login (gh-read data 'login)
          id (gh-read data 'id)
          gravatar-url (gh-read data 'gravatar_url)
          url (gh-read data 'url))))

(defun gh-read (obj field)
  (cdr (assoc field obj)))

(defun gh-config (key)
  "Returns a GitHub specific value from the global Git config."
  (let ((strip (lambda (string)
                 (if (> (length string) 0)
                     (substring string 0 (- (length string) 1)))))
        (git (executable-find "git")))
  (funcall strip (shell-command-to-string
                  (concat git " config --global github." key)))))

(defun gh-set-config (key value)
  "Sets a GitHub specific value to the global Git config."
  (let ((git (executable-find "git")))
    (shell-command-to-string
     (concat git " config --global github." key " " value))))

(provide 'gh-common)
;;; gh-common.el ends here
