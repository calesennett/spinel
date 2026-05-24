# Bundled tests:
#   - bound_method_array
#   - bound_method_basic

# === bound_method_array ===
# An array of Methods naturally infers as a ptr_array of
# obj_Method, since Method is just a regular user class as
# far as the type system is concerned. Each entry survives the
# round-trip through sp_PtrArray_get and dispatches to its captured
# (self, fn) pair.

class T_bound_method_array_C
  def double(x); x * 2; end
  def triple(x); x * 3; end
  def quad(x);   x * 4; end

  def fns
    [method(:double), method(:triple), method(:quad)]
  end
end

c = T_bound_method_array_C.new
fns = c.fns
puts fns.length
puts fns[0].call(5)
puts fns[1].call(5)
puts fns[2].call(5)

# === bound_method_basic ===
# `method(:foo)` inside a class body must yield a value that survives
# being stored in an ivar / passed across a method-call boundary, then
# called with `bm.call(x)` or `bm[x]`. Spinel's pre-fix path treated
# `method(:foo)` as a compile-time alias only — the variable held a
# placeholder int and the call body silently miscompiled to `return 0`.

class T_bound_method_basic_C
  def initialize
    @bm = method(:double)
  end

  def double(x)
    x * 2
  end

  def via_call(x)
    @bm.call(x)
  end

  def via_bracket(x)
    @bm[x]
  end
end

c = T_bound_method_basic_C.new
puts c.via_call(7)
puts c.via_bracket(20)

