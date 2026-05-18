# `Regexp.new("literal")` / `Regexp.compile("literal")` with a
# string-literal argument folds into the same static pattern table
# as a `/literal/` regex literal. The LV/const holding the value
# is a placeholder; `.match?` / `.match` / `=~` resolve at the call
# site through `regex_pat_c_expr`, dispatching to `sp_re_pat_<i>`.
# Without this, the LV was typed `obj_Regexp` and codegen emitted
# `sp_Regexp *lv_x = NULL;` which doesn't compile (no such type).

# Direct call on the constructor expression.
puts Regexp.new("foo").match?("foobar")   # true
puts Regexp.new("xyz").match?("foobar")   # false

# Local variable bound to a Regexp.new result.
pat = Regexp.new("\\d+")
puts pat.match?("hello 42")                # true
puts pat =~ "abc 123"                      # 4

# Compile alias.
pat2 = Regexp.compile("foo")
puts pat2.match?("foobar")                 # true

# Constant bound to a Regexp.new result.
RE = Regexp.new("foo")
puts RE.match?("foobar")                   # true
puts "abc foo def" =~ RE                   # 4
