# Issue #383: bare `return` (no value) in a method whose declared
# return type is `sp_RbVal` (poly) emitted literal `return 0;`
# instead of `return sp_box_nil();` — gcc errors `incompatible
# types when returning type 'int' but 'sp_RbVal' was expected`.
# The implicit end-of-function fallthrough already emitted the
# correct boxed nil; only bare-return statements were missed.
#
# Sister to the void-initialize and obj_<C>-class-method fixes
# (#337 / #314 follow-up). compile_return_stmt's bare-return
# path now has a poly arm that emits `sp_box_nil()`.

class Adapter
  def self.lookup(key)
    return unless key == "x"     # poly-returning fn, bare return
    if key.length > 5
      "long-string"
    else
      [1, 2, 3]
    end
  end
end

# Heterogeneous return types collapse to poly; the bare-return
# branch needs to box nil into the same slot.
puts Adapter.lookup("x").to_s
puts Adapter.lookup("none").to_s
