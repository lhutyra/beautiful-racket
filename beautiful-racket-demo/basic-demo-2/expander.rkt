#lang br/quicklang
(require "struct.rkt" "run.rkt" "elements.rkt")
(provide (rename-out [b-module-begin #%module-begin])
         (all-from-out "elements.rkt"))

(define-macro (b-module-begin (b-program LINE ...))
  (with-pattern
      ([((b-line NUM STMT ...) ...) #'(LINE ...)]
       [(LINE-FUNC ...) (prefix-id "line-" #'(NUM ...))]
       [(VAR-NAME ...) (find-unique-var-names #'(LINE ...))])
    #'(#%module-begin
       (define VAR-NAME 0) ...
       LINE ...
       (define line-table
         (apply hasheqv (append (list NUM LINE-FUNC) ...)))
       (void (run line-table)))))

(begin-for-syntax
  (require racket/list)
  (define (find-unique-var-names stx)
    (remove-duplicates
     (for/list ([var-stx (in-list (syntax-flatten stx))]
                #:when (syntax-property var-stx 'b-id))
       var-stx)
     #:key syntax->datum)))
