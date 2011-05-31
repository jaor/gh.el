;;; gh-api.el --- api definition for gh.el

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

(require 'json)
(require 'gh-auth)

(defclass gh-api ()
  ((sync :initarg :sync :initform t)
   (base :initarg :base :type string)
   (auth :initarg :auth))
  "Github API")

(defmethod gh-api-expand-resource ((api gh-api)
                                   resource)
  resource)

(defmethod gh-api-get-username ((api gh-api))
  (oref (oref api :auth) :username))

(defun gh-api-get-password-authenticator ()
  ;; hack to skip initialization at class def time
  (unless eieio-skip-typecheck
    (gh-password-authenticator "pwd-auth")))

(defclass gh-api-v3 (gh-api)
  ((base :initarg :base :initform "https://api.github.com")
   (auth :initarg :auth :initform (gh-api-get-password-authenticator)))
  "Github API v3")

(defclass gh-api-request ()
  ((method :initarg :method :type string)
   (url :initarg :url :type string)
   (headers :initarg :headers)
   (data :initarg :data :initform "" :type string)))

(defclass gh-api-response ()
  ((data :initarg :data :initform nil))
  "Base class for API responses")

(defclass gh-api-sync-response (gh-api-response)
  ()
  "Synchronous response")

(defclass gh-api-async-response (gh-api-response)
  ()
  "Asynchronous response")

(defun gh-api-json-decode (repr)
  (if (or (null repr) (string= repr ""))
      'empty
    (let ((json-array-type 'list))
      (json-read-from-string repr))))

(defun gh-api-json-encode (json)
  (json-encode-list json))

(defmethod gh-api-response-init ((resp gh-api-response)
                                 buffer transform)
  (declare (special url-http-end-of-headers))
  (with-current-buffer buffer
    (goto-char (1+ url-http-end-of-headers))
    (oset resp :data (let ((raw (buffer-substring (point) (point-max))))
                       (if transform
                           (funcall transform (gh-api-json-decode raw))
                         raw))))
  (kill-buffer buffer)
  resp)

(defun gh-api-set-response (status resp transform)
  (gh-api-response-init resp (current-buffer)))

(defmethod gh-api-authenticated-request 
  ((api gh-api) transformer method resource &optional data)
  (let ((req (gh-auth-modify-request (oref api :auth)
              (gh-api-request "request" 
                              :method method
                              :url (concat (oref api :base) 
                                           (gh-api-expand-resource api resource))
                              :headers nil
                              :data (or (gh-api-json-encode data) "")))))
    (let ((url-request-method (oref req :method))
          (url-request-data (oref req :data))
          (url-request-extra-headers (oref req :headers))
          (url (oref req :url))) 
      (if (oref api :sync)
          (let ((resp (gh-api-sync-response "sync")))
            (gh-api-response-init resp
                                  (url-retrieve-synchronously url)
                                  transformer)
            (oref resp :data))
        (let ((resp (gh-api-async-response "async")))
          (url-retrieve url 'gh-api-set-response (list resp transformer)))))))

(provide 'gh-api)
;;; gh-api.el ends here
