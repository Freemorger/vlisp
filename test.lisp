; (let (x 14) (print (+ x 4)))

(defvar x 10)

(let (x 20)
  (let (x 25) (
    print (* x 4) ; 100
    )
  )
)

(print x) ; 10

(print 3.14)

(print (/ 4.0 2)) ; 2.0
