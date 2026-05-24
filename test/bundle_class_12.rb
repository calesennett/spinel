# Bundled tests:
#   - case_poly_when_lit
#   - chained_attr_setter
#   - chained_ivar_op_assign_emits_inner_write
#   - chained_ivar_write_split
#   - chained_ivar_write_subclass

# === case_poly_when_lit ===
# Issue #387: `case <poly> when :sym_lit` previously lowered to
# `mrb_int _t = lv_poly;` (a struct→int copy that doesn't compile)
# followed by `_t == SPS_<sym>` (which would compare the union's
# tag byte to the sym id even if the assignment had compiled).
#
# Fix: when pred type is poly, hold the temp as `sp_RbVal` and
# emit per-when-arm tag-check + value-compare matched to the
# literal's type (sym / str / int / float / nil / true / false).

class T_case_poly_when_lit_C
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

c = T_case_poly_when_lit_C.new
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

# === chained_attr_setter ===
# `@a = obj.attr = val` and similar chains used to mistype the
# outer LHS. `infer_call_type` had no special case for an
# attr-writer CallNode (`obj.attr = val`), so it fell through to
# the int default. Codegen was emitting the right C-level
# assignment expression `(rc->iv_attr = arg)` (which evaluates
# to the rhs in C), but the surrounding LHS was declared as
# `mrb_int`, so `outer = (rc->iv_attr = obj_value)` typed the
# outer slot as int and any later use went through the wrong
# dispatch.
#
# Fix: when `infer_call_type` sees a CallNode whose name ends
# with `=` (and isn't `==` / `<=` / etc.), and the receiver is
# obj-typed and has an attr_writer for the slot, return the rhs
# argument's type. Ruby semantics: an assignment expression
# evaluates to the rhs.

class T_chained_attr_setter_Box
  def initialize(n); @n = n; @arr = []; @arr << n; end
  attr_reader :n
end

class T_chained_attr_setter_Holder
  attr_writer :box
end

# Simple chain — the result of `h.box = T_chained_attr_setter_Box.new(...)` should be
# a T_chained_attr_setter_Box, not an int.
h = T_chained_attr_setter_Holder.new
b = (h.box = T_chained_attr_setter_Box.new(42))
puts b.n   # 42

# Optcarrot-shape chain: `@a = obj.x = expr`. Both `@a` and
# `obj.x` get the same T_chained_attr_setter_Box; reading either back gives the
# same value.
class T_chained_attr_setter_Apu
  def initialize(n); @n = n; @arr = []; @arr << n; end
  attr_reader :n
end

class T_chained_attr_setter_Cpu
  attr_writer :apu
  attr_reader :apu
end

class T_chained_attr_setter_Nes
  def initialize
    @cpu = T_chained_attr_setter_Cpu.new
    @apu = @cpu.apu = T_chained_attr_setter_Apu.new(99)
  end
  attr_reader :apu, :cpu
end

n = T_chained_attr_setter_Nes.new
puts n.apu.n        # 99
puts n.cpu.apu.n    # 99

# === chained_ivar_op_assign_emits_inner_write ===
# `@b = @a &= 0x80` parses as InstanceVariableWriteNode whose value
# is an InstanceVariableOperatorWriteNode. Without an inner-write
# emitter, the `@a &= ...` evaporated and `@b = ...` saw `0` —
# both ivars ended up wrong. Verifies the chained form against the
# parens-rewrite (`@b = (@a = @a & 0x80)`) and the manual two-stmt
# split — all three should produce the same `@a=128 @b=128`.

class T_chained_ivar_op_assign_emits_inner_write_C
  attr_reader :a, :b
  def initialize
    @a = 0xff
    @b = 0
  end
  def m_chain
    @b = @a &= 0x80
  end
  def m_paren
    @b = (@a = @a & 0x80)
  end
  def m_split
    @a = @a & 0x80
    @b = @a
  end
end

c1 = T_chained_ivar_op_assign_emits_inner_write_C.new; c1.m_chain; puts "chain: a=#{c1.a} b=#{c1.b}"
c2 = T_chained_ivar_op_assign_emits_inner_write_C.new; c2.m_paren; puts "paren: a=#{c2.a} b=#{c2.b}"
c3 = T_chained_ivar_op_assign_emits_inner_write_C.new; c3.m_split; puts "split: a=#{c3.a} b=#{c3.b}"

# === chained_ivar_write_split ===
# Chained `@a = @b = ... = literal` where the targets have different
# concrete slot types (here: a string ivar and an int ivar). Without
# splitting the chain into per-target writes, the outer assignment's
# RHS picks up the inner ivar's recorded type, and the T_chained_ivar_write_split_C compiler
# rejects the cross-typed slot store.

class T_chained_ivar_write_split_C
  def initialize
    @a = "hello"
    @b = 42
  end

  def reset
    @a = @b = nil
  end

  def show
    puts @a
    puts @b
  end
end

c = T_chained_ivar_write_split_C.new
c.show
c.reset
puts "reset ok"

# === chained_ivar_write_subclass ===
# Issue #238 follow-up to #235: chained `@a = @b = nil` in a parent
# class, with concrete writes in a subclass that pin the slots to
# typed pointers (string + int). Without restricting the
# chain-head bypass to `at == "int"`, the parent's nil-chain forces
# "nil" into the slot type each iteration of the inference fixpoint
# while the subclass's typed write cascades back up — the slot
# ping-pongs between obj_X and obj_X? and lands on poly, which
# then rejects the typed-pointer store as a C type error.

class T_chained_ivar_write_subclass_Base
  def reset
    @a = @b = nil
  end
end

class T_chained_ivar_write_subclass_Sub < T_chained_ivar_write_subclass_Base
  def initialize
    @a = "hello"
    @b = 42
  end
  attr_reader :a, :b
end

s = T_chained_ivar_write_subclass_Sub.new
puts s.a
puts s.b

