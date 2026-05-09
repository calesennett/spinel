# Issue #387: `case <poly> when :sym_lit` previously lowered to
# `mrb_int _t = lv_poly;` (a struct→int copy that doesn't compile)
# followed by `_t == SPS_<sym>` (which would compare the union's
# tag byte to the sym id even if the assignment had compiled).
#
# Fix: when pred type is poly, hold the temp as `sp_RbVal` and
# emit per-when-arm tag-check + value-compare matched to the
# literal's type (sym / str / int / float / nil / true / false).

class C
  def lookup(name)
    case name
    when :id     then "id-result"
    when :body   then "body-result"
    when "raw"   then "raw-result"
    when 42      then "forty-two"
    when nil     then "nil-result"
    when true    then "true-result"
    when false   then "false-result"
    else              "other"
    end
  end
end

c = C.new
puts c.lookup(:id)
puts c.lookup(:body)
puts c.lookup("raw")
puts c.lookup(42)
puts c.lookup(nil)
puts c.lookup(true)
puts c.lookup(false)
puts c.lookup(:unknown)
puts c.lookup("string-key")
puts c.lookup(99)
