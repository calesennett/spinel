# Bundled tests:
#   - call_op_write
#   - case_expr_sibling_classes_box

# === call_op_write ===
# CallOperatorWriteNode -- `obj.attr += val`, `obj.attr -= val`, etc.
#
# CRuby evaluates the receiver exactly once even though the source
# `obj.bar += v` expands conceptually to `obj.bar = obj.bar + v`.
# The temp pattern in compile_call_assign_typed mirrors that.
#
# Spinel restriction: only typed instance receivers with
# attr_accessor (or struct field) on the class are supported. For
# everything else the codegen exits with a precise error rather
# than emit silently-wrong C.

class T_call_op_write_Counter
  attr_accessor :n
  def initialize
    @n = 0
  end
end

c = T_call_op_write_Counter.new
c.n += 5
puts c.n            # 5
c.n += 10
puts c.n            # 15
c.n -= 3
puts c.n            # 12
c.n *= 2
puts c.n            # 24
c.n /= 4
puts c.n            # 6
c.n |= 1
puts c.n            # 7
c.n &= 5
puts c.n            # 5
c.n ^= 4
puts c.n            # 1
c.n <<= 3
puts c.n            # 8
c.n >>= 1
puts c.n            # 4

# String-valued attr -- `+=` becomes string concat.
class T_call_op_write_Greeting
  attr_accessor :msg
  def initialize
    @msg = "hello"
  end
end

g = T_call_op_write_Greeting.new
g.msg += " world"
puts g.msg          # hello world

# === case_expr_sibling_classes_box ===
# #580 (Sam Ruby). T_case_expr_sibling_classes_box_A `case` expression whose `when` branches
# return instances of unrelated sibling classes typed the overall
# result as sp_RbVal at the expression level, but the per-branch
# emit assigned the raw `sp_<Class> *` pointer into the sp_RbVal
# slot. C rejected the assignment with `incompatible types`.
#
# Fix: route each arm's last expression through box_when_arm_to_
# target, which inserts sp_box_obj (or whatever box_value_to_poly
# resolves to for the arm's type) when the unified target is poly
# and the arm's static type is something narrower.

class T_case_expr_sibling_classes_box_A
  def name; "T_case_expr_sibling_classes_box_A-instance"; end
end

class T_case_expr_sibling_classes_box_B
  def name; "T_case_expr_sibling_classes_box_B-instance"; end
end

n = 1
x = case n
    when 0 then T_case_expr_sibling_classes_box_A.new
    when 1 then T_case_expr_sibling_classes_box_B.new
    end
puts x.is_a?(T_case_expr_sibling_classes_box_A)
puts x.is_a?(T_case_expr_sibling_classes_box_B)

