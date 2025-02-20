;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(nyxt:define-package :nyxt/mode/bookmark-frequent-visits
  (:documentation "Package for `bookmark-frequent-visits-mode', mode to bookmark frequently visited URLs.
The substance of it is `bookmark-frequent-visit' function."))
(in-package :nyxt/mode/bookmark-frequent-visits)

(define-mode bookmark-frequent-visits-mode ()
  "Mode to bookmark frequently visited URLs while navigating the web.
Does not need any setup and commands: it bookmarks the visited pages once they
hit a `threshold'. To change it to a different threshold (e.g. 50), do

\(define-configuration :bookmark-frequent-visits-mode
  \"Change the threshold of `bookmark-frequent-visits-mode' to not clutter bookmarks too much.\"
  ((threshold 50)))"
  ((visible-in-status-p nil)
   (threshold
    20
    :documentation "The number of hits after which to ")))

(defun bookmark-frequent-visit (url threshold)
  "Check if current URL is frequently visited and not included in the
bookmarks. If this is the case, prompt the user about bookmarking it."
  (labels ((bookmarked-url-p (url-address)
             "The local function `bookmarked-url-p' checks if the current URL is
             already bookmarked or not."
             (let ((bookmark-url-strings
                     (mapcar #'(lambda (e) (render-url (url e)))
                             (files:content (nyxt/mode/bookmark:bookmarks-file (current-buffer))))))
               (find url-address bookmark-url-strings :test #'string=))))
    (and-let* ((implicit-visits-value (count url
                                             (history-vector *browser*)
                                             :test 'equalp :key 'url))
               (current-url-string url))
      (when (and (> implicit-visits-value threshold)
                 (not (bookmarked-url-p current-url-string)))
        (if-confirm ((format nil "Bookmark ~a?" current-url-string))
            (nyxt/mode/bookmark:bookmark (quri:uri current-url-string)))))))

(defmethod nyxt:on-signal-load-finished ((mode bookmark-frequent-visits-mode) url title)
  (declare (ignore title))
  (bookmark-frequent-visit url (threshold mode))
  url)
