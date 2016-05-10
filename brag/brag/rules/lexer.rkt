#lang racket/base
(require (for-syntax racket/base "parser.rkt"))
(require parser-tools/lex
         (prefix-in : parser-tools/lex-sre)
         "parser.rkt"
         "rule-structs.rkt")

(provide lex/1 tokenize)

;; A newline can be any one of the following.
(define-lex-abbrev NL (:or "\r\n" "\r" "\n"))

;; chars used for quantifiers & parse-tree filtering
(define-for-syntax quantifiers "+:*")
(define-lex-trans reserved-chars
  (λ(stx) #`(char-set #,(format "~a~a~a" quantifiers hide-char splice-char))))

(define-lex-abbrevs
   [letter (:or (:/ "a" "z") (:/ #\A #\Z))]
   [digit (:/ #\0 #\9)]
   [id-char (:or letter digit (:& (char-set "+:*@!-.$%&/=?^_~<>") (char-complement (reserved-chars))))]
 )

(define-lex-abbrev id
  (:& (complement (:+ digit))
      (:+ id-char)))


(define lex/1
  (lexer-src-pos
   [(:: "'"
        (:* (:or "\\'" (:~ "'" "\\")))
        "'")
    (token-LIT lexeme)]
   [(:: "\""
        (:* (:or "\\\"" (:~ "\"" "\\")))
        "\"")
    (token-LIT lexeme)]
   ["("
    (token-LPAREN lexeme)]
   ["["
    (token-LBRACKET lexeme)]
   [")"
    (token-RPAREN lexeme)]
   ["]"
    (token-RBRACKET lexeme)]
   ["/"
    (token-HIDE lexeme)]
   ["@"
    (token-SPLICE lexeme)]
   ["|"
    (token-PIPE lexeme)]
   [(:or "+" "*")
    (token-REPEAT lexeme)]
   [whitespace
    ;; Skip whitespace
    (return-without-pos (lex/1 input-port))]
   ;; Skip comments up to end of line
   [(:: (:or "#" ";")
        (complement (:: (:* any-char) NL (:* any-char)))
        (:or NL ""))
    ;; Skip comments up to end of line.
    (return-without-pos (lex/1 input-port))]
   [(eof)
    (token-EOF lexeme)]
   [(:: id (:* whitespace) ":")
    (token-RULE_HEAD lexeme)]
   [(:: "/" id (:* whitespace) ":")
    (token-RULE_HEAD_HIDDEN lexeme)]
   [(:: "@" id (:* whitespace) ":")
    (token-RULE_HEAD_SPLICED lexeme)]
   [id
    (token-ID lexeme)]
   
   ;; We call the error handler for everything else:
   [(:: any-char)
    (let-values ([(rest-of-text end-pos-2)
                 (lex-nonwhitespace input-port)])
      ((current-parser-error-handler)
       #f
       'error
       (string-append lexeme rest-of-text)
       (position->pos start-pos)
       (position->pos end-pos-2)))]))


;; This is the helper for the error production.
(define lex-nonwhitespace
  (lexer
   [(:+ (char-complement whitespace))
    (values lexeme end-pos)]
   [any-char
    (values lexeme end-pos)]
   [(eof)
    (values "" end-pos)]))



;; position->pos: position -> pos
;; Coerses position structures from parser-tools/lex to our own pos structures.
(define (position->pos a-pos)
  (pos (position-offset a-pos)
       (position-line a-pos)
       (position-col a-pos)))



;; tokenize: input-port -> (-> token)
(define (tokenize ip
                  #:source [source (object-name ip)])
  (lambda ()
    (parameterize ([file-path source])
      (lex/1 ip))))