(defun make-card (rank suit)
  (list :rank rank :suit suit))

(defun rank (card)
  (getf card :rank))

(defun suit (card)
  (getf card :suit))

(defun make-hand (&rest cards)
  (loop while cards
        collecting (make-card (pop cards) (pop cards))))

(defun possible-combinations (hand)
  (if (null hand)
    (list nil)
    (let ((prev (possible-combinations (cdr hand))))
      (append (mapcar #'(lambda (elt) (cons (car hand) elt)) prev)
              prev))))

(defun sort-hand (hand)
  (sort hand
        #'<
        :key #'rank))

(defun value (card)
  (if (> 10 (rank card))
    (rank card)
    10))

(defun rank->sym (rank)
  (cond
    ((< rank 11) rank)
    ((eql 11 rank) 'J)
    ((eql 12 rank) 'Q)
    ((eql 13 rank) 'K)
    (t 'wat)))

(defun fmt-card (card)
  (format nil "~a~a" (rank->sym (rank card)) (suit card)))

(defun print-hand (cards)
  (format t "~{~a ~}~%" (map 'list #'fmt-card cards)))

(defun sum-hand (cards)
  (reduce
    #'+
    (map 'list #'value cards)))

(defun count-15s (hand start-card)
  (let* ((cards (cons start-card hand))
         (possible-15s (possible-combinations cards)))
    (count-if
      #'(lambda (c) (eql (sum-hand c) 15))
      possible-15s)))

(defun pair-p (cards)
  (if (eql (length cards) 2)
    (eql (rank (first cards)) (rank (second cards)))))

(defun count-pairs (hand start-card)
  (let* ((cards (cons start-card hand))
         (possible-pairs (possible-combinations cards)))
    (count-if #'pair-p possible-pairs)))

(defun find-jacks (cards)
  (remove-if-not
    #'(lambda (c) (eql (rank c) 11))
    cards))

(defun nobs-p (jack start-card)
  (eql (suit jack) (suit start-card)))

(defun his-nobs (hand start-card)
  (reduce
    #'(lambda (&optional a b) (or a b))
    (map 'list
         #'(lambda (jack) (nobs-p jack start-card))
         (find-jacks hand))))

(defun run-p (cards)
  (let* ((sorted (sort-hand cards))
         (fst-val (rank (first sorted)))
         (scd-val (rank (second sorted))))
    (cond
      ((null cards) nil)
      ((eql (length sorted) 2) (eql (+ fst-val 1) scd-val))
      ((eql (+ fst-val 1) scd-val) (run-p (cdr sorted)))
      (t nil))))

(defun sub-search (l l-of-l)
  "sub-search searches the lists inside l-of-l for l and returns true if found, nil otherwise"
  (cond
    ((null l-of-l) nil)
    ((and (search l (car l-of-l) :test #'equal) (not (equal l (car l-of-l)))) t)
    (t (sub-search l (cdr l-of-l)))))

(defun score-runs (hand start-card)
  (let* ((cards (cons start-card hand))
         (possible-runs (possible-combinations cards)) ;borked?
         (runs-with-subs (remove-if-not #'run-p possible-runs))
         (runs (remove-if #'(lambda (run) (sub-search run runs-with-subs)) runs-with-subs))
         (lengths (map 'list #'length runs)))
    (progn
      (format t "runs: ~A~%" (length lengths))
      (reduce #'+ lengths))))

(defun score-hand (hand start-card &key crib)
  "Returns the number of points a hand scores"
  (+
    (score-runs hand start-card)
    (if (his-nobs hand start-card) 1 0)
    (* 2 (count-pairs hand start-card))
    (* 2 (count-15s hand start-card))))
    ;TODO (score-flush hand start-card)
