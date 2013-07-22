;; http://github.com/namin/lambdajam
;;; in racket:
;;; #lang scheme

(load "test-check.scm")
(load "pmatch.scm")
(load "sugar.scm")

;; Scheme

(+ 1 2)
(+ (+ 1 2) (+ 3 4))
(+ 3 7)
((lambda (x) (+ x 1)) 1)
((lambda () 1))
(if (= 1 1) 2 (/ 1 0))

((if (= 1 1) - +) 2 1)
(((lambda () +)) 1 2)
((lambda () (display "hello")))
+

(define a 1)
a
(define inc (lambda (x) (+ x 1)))
(inc 1)

(define adder
  (lambda (x)
    (lambda (y)
      (+ x y))))
(adder 1) ;; #<procedure>
((adder 1) 2) ;; 3

(cons 1
      (cons 2 '())
      )
;; (1 . '(2 . '()))
;; (1 2)
(cdr  (cons 'a 'd))
(pair? (cons 1 2)) ;; #t
(list? (cons 1 2)) ;; #f
(null? '()) ;; #t
(null? (cons 1 '())) ;; #f
(cons 'a (cons 'b 'c))

;;; Proper List
;;; either:
;;; (1) empty list
;;; (2) a pair whose cdr is a proper list

(cadr '(1 2 3))
(car (cdr '(1 2 3)))

(append '(1 2 3) '(4 5 6))
(define append
  (lambda (xs ys)
    (if (null? xs)
        ys
        (cons (car xs) (append (cdr xs) ys)))))

(define append
  (lambda (xs ys)
    (cond
     ((null? xs) ys)
     (else (cons (car xs) (append (cdr xs) ys))))))

(rember 'a '(a b c))   ;; '(b c)
(rember 'b '(a b c b)) ;; '(a c)
(rember 'b '(a (b a) c b)) ;; '(a (a) c)
(rember 'b '(a (b b (b) a b) c b))
(define rember
  (lambda (x xs)
    (cond
     ((null? xs) '())
     
     ((pair? (car xs))
      (cons (rember x (car xs))
            (rember x (cdr xs))))
     
     ((eq? x (car xs))
      (rember x (cdr xs)))
     (else
      (cons (car xs)
            (rember x (cdr xs)))))))


(define foo '(hello there))
`(,foo ,foo)
`(,(+ 1 2) ,(+ 3 4)) ;; (3 7)
`(,(+ 1 2) (+ 3 4)) ;; (3 (+ 3 4))

;;;; -------------------------------------------------

;; Interpreters

;;; Call-By-Value (same as in Scheme)

;;; x, y, z (variables)
;;; e = x           (variable)
;;;     (lambda (x) e_0) (abstraction)
;;;     (e_1 e_2)   (application)

;;; env: variable name -> value
(define empty-env
  (lambda (x) (error 'env-lookup "unbound variable")))

(define eval-exp
  (lambda (exp env)
    (pmatch
     exp
     (,x (guard (symbol? x)) (env x))
     (,n (guard (number? n)) n)
     (,b (guard (boolean? b)) b)
     ((zero? ,e)
      (zero? (eval-exp e env)))
     ((sub1 ,e)
      (sub1 (eval-exp e env)))
     ((* ,e1 ,e2)
      (* (eval-exp e1 env) (eval-exp e2 env)))
     ((if ,c ,a ,b) ;; '(if (zero? 1) 1 2) c will become '(zero? 1)
      (if (eval-exp c env)
          (eval-exp a env)
          (eval-exp b env)))
     ((lambda (,x) ,body) ;; lambda syntax
      (lambda (a) ;; closure representation
        (eval-exp body
                  (lambda (y) ;; env extension
                    (if (eq? y x)
                        a
                        (env y))))))
     ((,e1 ,e2)
      ((eval-exp e1 env)
       (eval-exp e2 env))))))

(define eval-top
  (lambda (exp)
    (eval-exp exp empty-env)))

(eg (eval-exp 'x
              (lambda (y) (if (eq? y 'x) 1 (empty-env y))))
    1)

(eg (eval-top '((lambda (x) 1) 2))
    1)

(eg (eval-exp '((lambda (x) x) 2)
              empty-env)
    2)

;; (eval-exp '((lambda (x) (x x)) (lambda (x) (x x))) empty-env)

(eg (eval-exp '((lambda (y) y) x)
              (lambda (y) (if (eq? y 'x) 1 (empty-env y))))
    1)

(eval-top '(((lambda (fun)
              ((lambda (F)
                 (F F))
               (lambda (F)
                 (fun (lambda (x) ((F F) x))))))
            (lambda (factorial)
              (lambda (n)
                (if (zero? n)
                    1
                    (* n (factorial (sub1 n)))))))
           6))