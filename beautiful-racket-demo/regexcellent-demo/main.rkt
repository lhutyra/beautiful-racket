#lang br/quicklang
(require brag/support "grammar.rkt")
(provide (all-from-out br/quicklang) (all-defined-out))

(module+ reader
  (provide read-syntax))

(define-lex-abbrev regex-chars (char-set "()*+?.^$|<!=[]"))
  
(define lex
  (lexer
   [(:+ "\n") (token 'NEWLINE lexeme)]
   [(from/stop-before ";" "\n") (token 'COMMENT #:skip? #t)]
   [(:+ whitespace) (token 'SP lexeme #:skip? #t)]
   [regex-chars lexeme]
   [alphabetic (token 'LITERAL lexeme)]))

(define (read-syntax src ip)
  (define parse-tree (parse (λ () (lex ip))))
  (strip-context
   (with-syntax ([PT parse-tree])
     #'(module regexcellent-mod regexcellent-demo
         (for ([line (in-list PT)])
           (displayln line))))))

(define-macro (top . LINES) #'(list . LINES))

(define (line . pieces)
  (format "This pattern matches ~a." (string-join pieces ", followed by ")))

(define (pat . xs)
  (if (= (length xs) 1)
      (car xs)
      (format "a sequence starting with ~a" (string-join xs ", followed by "))))

(define (lookbehind pat)
  (format "a lookbehind assertion of ~a" pat))
(define (lookahead pat)
  (format "a lookahead assertion of ~a" pat))

(define (choice . pats)
  (format "a choice of ~a" (string-join pats "; or ")))

(define (repeat thing [quantifier #f] [maybe-non-greedy? #f])
  (string-join
   (filter values
           (list thing
                 (case quantifier
                   [("*") "repeated zero or more times"]
                   [("+") "repeated one or more times"]
                   [("?") "zero or once"]
                   [else #f])
                 (and maybe-non-greedy? "non-greedily")))
   " "))

(define (group pat)
  (format "the group containing ~a" pat))

(define (any) "any character")
(define (start) "the start of the input")
(define (end) "the end of the input")

(define (literals . strs)
  (format "the literal string ~v" (string-join strs "")))
(define (chars . lits)
  (format "any member of the character set {~a}" (string-join (map ~v lits) ", ")))