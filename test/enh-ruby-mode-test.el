(load-file "helper.el")
(load-file "../enh-ruby-mode.el")

(local-set-key (kbd "C-c C-r")
               (lambda ()
                 (interactive)
                 (require 'ert)
                 (ert-delete-all-tests)
                 (load-file "../enh-ruby-mode.el")
                 (eval-buffer)
                 (ert-run-tests-interactively t)))

;; In batch mode, face-attribute returns 'unspecified,
;; and it causes wrong-number-of-arguments errors.
;; This is a workaround for it.
(defun erm-darken-color (name)
  (let ((attr (face-attribute name :foreground)))
    (unless (equal attr 'unspecified)
      (color-darken-name attr 20)
      "#000000")))

(ert-deftest enh-ruby-backward-sexp-test ()
  (with-temp-enh-rb-string
   "def foo
  xxx
end
"

   (end-of-buffer)
   (enh-ruby-backward-sexp 1)
   (line-should-equal "def foo")))

(ert-deftest enh-ruby-backward-sexp-test-inner ()
  :expected-result :failed
  (with-temp-enh-rb-string
   "def backward_sexp
  \"string #{expr \"another\"} word\"
end
"

   (search-forward " word")
   (move-end-of-line nil)
   (enh-ruby-backward-sexp 2)
   (line-should-equal "\"string #{expr \"another\"} word\"")))

(ert-deftest enh-ruby-forward-sexp-test ()
  (with-temp-enh-rb-string
   "def foo
  xxx
 end

def backward_sexp
  xxx
end
"

   (beginning-of-buffer)
   (enh-ruby-forward-sexp 1)
   (forward-char 2)
   (line-should-equal "def backward_sexp")))

(ert-deftest enh-ruby-up-sexp-test ()
  (with-temp-enh-rb-string
   "def foo
  %_bosexp#{sdffd} test1_[1..4].si
end"

   (search-forward "test1_")
   (enh-ruby-up-sexp)
   (line-should-equal "def foo")))      ; maybe this should be %_bosexp?

(ert-deftest enh-ruby-indent-trailing-dots ()
  (with-temp-enh-rb-string
   "a.b.
c
"

   (indent-region (point-min) (point-max))
   (buffer-should-equal "a.b.
  c
")))

(ert-deftest enh-ruby-end-of-defun ()
  (with-temp-enh-rb-string
   "class Class
def method
# blah
end # method
end # class"

   (search-forward "blah")
   (enh-ruby-end-of-defun)
   (line-should-equal " # method")))

(ert-deftest enh-ruby-end-of-block ()
  (with-temp-enh-rb-string
   "class Class
def method
# blah
end # method
end # class"

   (search-forward "blah")
   (enh-ruby-end-of-block)
   (line-should-equal " # method")))

(ert-deftest enh-ruby-indent-leading-dots ()
  (with-temp-enh-rb-string
   "d.e
.f
"

   (indent-region (point-min) (point-max))
   (buffer-should-equal "d.e
  .f
")))

(ert-deftest enh-ruby-indent-leading-dots-ident ()
  (with-temp-enh-rb-string
   "b
.c
.d
"

   (indent-region (point-min) (point-max))
   (buffer-should-equal "b
  .c
  .d
")))

(ert-deftest enh-ruby-indent-leading-dots-ivar ()
  (with-temp-enh-rb-string
   "@b
.c
.d
"

   (indent-region (point-min) (point-max))
   (buffer-should-equal "@b
  .c
  .d
")))

(ert-deftest enh-ruby-indent-leading-dots-gvar ()
  (with-temp-enh-rb-string
   "$b
.c
.d
"

   (indent-region (point-min) (point-max))
   (buffer-should-equal "$b
  .c
  .d
")))

(ert-deftest enh-ruby-indent-leading-dots-cvar ()
  (with-temp-enh-rb-string
   "@@b
.c
.d
"

   (indent-region (point-min) (point-max))
   (buffer-should-equal "@@b
  .c
  .d
")))

(ert-deftest enh-ruby-indent-pct-w-array ()
  (with-temp-enh-rb-string
   "words = %w[
moo
]
"

   (indent-region (point-min) (point-max))
   (buffer-should-equal "words = %w[
         moo
        ]
")))

(ert-deftest enh-ruby-indent-array-of-strings ()
  (with-temp-enh-rb-string
   "
words = ['cow',
'moo'
]
"

   (indent-region (point-min) (point-max))
   (buffer-should-equal "
words = ['cow',
         'moo'
        ]
")))

(ert-deftest enh-ruby-indent-hash ()
  ;; https://github.com/zenspider/enhanced-ruby-mode/issues/78
  (with-temp-enh-rb-string
   "
{
a: a,
b: b
}
"

   (indent-region (point-min) (point-max))
   (buffer-should-equal "
{
  a: a,
  b: b
}
")))

(ert-deftest enh-ruby-indent-hash-after-cmd ()
  ;; https://github.com/zenspider/enhanced-ruby-mode/issues/78
  :expected-result :failed
  (with-temp-enh-rb-string
   "
x
{
a: a,
b: b
}"

   (indent-region (point-min) (point-max))
   (buffer-should-equal "
x
{
  a: a,
  b: b
}")))

(defun toggle-to-do ()
  (enh-ruby-toggle-block)
  (buffer-should-equal "7.times do |i|
  puts \"number #{i+1}\"
end
"))

(defun toggle-to-brace ()
  (enh-ruby-toggle-block)
  (buffer-should-equal "7.times { |i| puts \"number #{i+1}\" }
"))

(ert-deftest enh-ruby-toggle-block/both ()
  (with-temp-enh-rb-string
   "7.times { |i|
  puts \"number #{i+1}\"
}
"

   (toggle-to-do)
   (toggle-to-brace)))

(ert-deftest enh-ruby-toggle-block/brace ()
  :expected-result t ; https://github.com/zenspider/enhanced-ruby-mode/issues/132
  (with-temp-enh-rb-string
   "7.times { |i|
  puts \"number #{i+1}\"
}
"

   (toggle-to-do)))

(ert-deftest enh-ruby-toggle-block/do ()
  (with-temp-enh-rb-string
   "7.times do |i|
  puts \"number #{i+1}\"
end
"

   (toggle-to-brace)))

(ert-deftest enh-ruby-indent-heredocs-test/unset ()
  (with-temp-enh-rb-string
   "meth <<-DONE
  a b c
d e f
DONE
"

   (search-forward "d e f")
   (move-beginning-of-line nil)
   (indent-for-tab-command)             ; hitting TAB char
   (buffer-should-equal "meth <<-DONE
  a b c
d e f
DONE
")))

(ert-deftest enh-ruby-indent-heredocs-test/on ()
  (with-temp-enh-rb-string
   "meth <<-DONE
  a b c
d e f
DONE
"

   (search-forward "d e f")
   (move-beginning-of-line nil)
   (let ((enh-ruby-preserve-indent-in-heredocs t))
     (indent-for-tab-command)           ; hitting TAB char
     (buffer-should-equal "meth <<-DONE
  a b c
  d e f
DONE
"))))

(ert-deftest enh-ruby-indent-heredocs-test/off ()
  (with-temp-enh-rb-string
   "meth <<-DONE
  a b c
d e f
DONE
"

   (search-forward "d e f")
   (move-beginning-of-line nil)
   (let ((enh-ruby-preserve-indent-in-heredocs nil))
     (indent-for-tab-command)           ; hitting TAB char
     (buffer-should-equal "meth <<-DONE
  a b c
d e f
DONE
"))))

(ert-deftest enh-ruby-deep-indent-def-after-private ()
  (with-temp-enh-rb-string
   "class Foo
private def foo
x
end
end
"

   (let ((enh-ruby-deep-indent-construct t))
     (indent-region (point-min) (point-max))
     (buffer-should-equal "class Foo
  private def foo
            x
          end
end
"))))

(ert-deftest enh-ruby-indent-def-after-private ()
  (with-temp-enh-rb-string
   "class Foo
private def foo
x
end
end
"

   (let ((enh-ruby-deep-indent-construct nil))
     (indent-region (point-min) (point-max))
     (buffer-should-equal "class Foo
  private def foo
    x
  end
end
"))))

(ert-deftest enh-ruby-deep-indent-if-in-assignment ()
  (with-temp-enh-rb-string
   "foo = if bar
x
else
y
end
"

   (let ((enh-ruby-deep-indent-construct t))
     (indent-region (point-min) (point-max))
     (buffer-should-equal "foo = if bar
        x
      else
        y
      end
"))))

(ert-deftest enh-ruby-dont-deep-indent-eol-opening ()
  (with-temp-enh-rb-string
   "
foo(:bar,
:baz)
foo(
:bar,
:baz,
)
[:foo,
:bar]
[
:foo,
:bar
]"

   (let ((enh-ruby-deep-indent-paren t))
     (indent-region (point-min) (point-max))
     (buffer-should-equal
      "
foo(:bar,
    :baz)
foo(
  :bar,
  :baz,
)
[:foo,
 :bar]
[
  :foo,
  :bar
]"))))

(ert-deftest enh-ruby-indent-if-in-assignment ()
  (with-temp-enh-rb-string
   "foo = if bar
x
else
y
end
"

   (let ((enh-ruby-deep-indent-construct nil))
     (indent-region (point-min) (point-max))
     (buffer-should-equal "foo = if bar
  x
else
  y
end
"))))
