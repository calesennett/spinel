# Bundled tests:
#   - class_var_write
#   - class_with_undefined_namespace
#   - cls_cmeth_param_from_callee_slot
#   - cls_ivar_type_parent_defer
#   - cls_meth_block

# === class_var_write ===
# ClassVariableWriteNode -- `@@var = value`.
#
# Spinel stores cvars as per-(class, name) C globals named
# `cvar_<ClassName>_<var>`. The static declaration is emitted at
# file scope alongside constants; ClassVariableReadNode (next
# commit) consumes the same storage.
#
# This commit's test only exercises the write side -- a follow-up
# Read commit prints @@count to verify round-trip.

class T_class_var_write_Counter
  @@count = 0
end

class T_class_var_write_Other
  @@count = 99    # independent slot from T_class_var_write_Counter's @@count
end

puts "ok"

# === class_with_undefined_namespace ===
# #524. `class M::Foo` with `M` undefined elsewhere used to emit
# `sp_class_constructors[SP_CLASS_COUNT]` while the
# `#define SP_CLASS_COUNT N` was gated on @needs_class_table = 1.
# Programs that declared a namespaced class with no other class-
# hierarchy usage (no `.class`, no `is_a?`, no `ancestors`) left
# @needs_class_table at 0, the SP_CLASS_COUNT define was skipped,
# and the Tier 5 dispatch table tripped a C "undeclared identifier"
# error.
#
# Fix (permissive synthesis): pre-scan for any user class that
# supports a no-arg new and lift @needs_class_table = 1. The
# namespaced class itself is registered with its `M_Foo` merged
# name regardless. CRuby would NameError on the undefined parent
# but spinel-AOT can't follow rubygem requires anyway (the
# real-world case is `class Minitest::Test` reopens that need to
# compile even though Minitest comes from a CRuby gem) -- the
# class-level methods still resolve, only call sites against
# external receivers fall through to the cannot-resolve warning.

class T_class_with_undefined_namespace_SomeUnknown::Thing
  def x
    42
  end
end

puts T_class_with_undefined_namespace_SomeUnknown::Thing.new.x

# === cls_cmeth_param_from_callee_slot ===
# Real-class class method (`def self.X`) param back-propagation:
# a body that forwards a param to a sibling cmeth whose slot is
# `void *` (or an obj pointer) should widen the outer param to
# the same pointer type.
#
# Symmetric to the closed sibling case for module class methods
# (test/param_ptr_from_callee_slot.rb). The earlier pass only
# walked @meth_* (top-level and module synthetics); real-class
# cmeths live in @cls_cmeth_* and were skipped.
#
# Also pins the literal-zero unification: passing `0` to a
# pointer-typed slot is C's null-pointer-constant, not a genuine
# poly. Prior to the fix, `column_bool(0, 0)` widened the param
# to poly and overrode the body-derived `void *`.

class T_cls_cmeth_param_from_callee_slot_Box
  def self.read_int(p)
    p.length
  end

  def self.read_bool(p)
    read_int(p) != 0
  end
end

puts T_cls_cmeth_param_from_callee_slot_Box.read_int("abc")
puts T_cls_cmeth_param_from_callee_slot_Box.read_bool("xyz")

# Three-deep sibling chain inside a class (vs the module-class
# sibling test).
class T_cls_cmeth_param_from_callee_slot_Chain
  def self.head(s)
    middle(s)
  end

  def self.middle(s)
    tail(s)
  end

  def self.tail(s)
    s.length
  end
end

puts T_cls_cmeth_param_from_callee_slot_Chain.head("hello")
puts T_cls_cmeth_param_from_callee_slot_Chain.middle("world")
puts T_cls_cmeth_param_from_callee_slot_Chain.tail("hi")

# === cls_ivar_type_parent_defer ===
# When the same ivar is registered on both a child class and a
# parent, the C struct embeds the parent's field at the parent's
# recorded type (`emit_class_fields` skips own copies that are also
# in the parent chain). `cls_ivar_type` used to return the child's
# own-table entry — letting downstream emit sites disagree with
# the actual struct field type.

class T_cls_ivar_type_parent_defer_Parent
  def initialize
    @x = 0
    @x = "s"      # heterogeneous int+string → @x widens to poly
  end
end

class T_cls_ivar_type_parent_defer_Child < T_cls_ivar_type_parent_defer_Parent
  def initialize
    super
    @x = 7        # write through the inherited (poly) slot
  end
  def read_x
    @x
  end
end

c = T_cls_ivar_type_parent_defer_Child.new
# Reading back via a T_cls_ivar_type_parent_defer_Child-defined method that emits `self->iv_x`.
# Without the fix, cls_ivar_type(T_cls_ivar_type_parent_defer_Child, "@x") returned the int from
# T_cls_ivar_type_parent_defer_Child's own table; the struct field is sp_RbVal (T_cls_ivar_type_parent_defer_Parent's poly);
# the read miscompiled / yielded a garbage int. With the fix the
# emit goes through the poly read path and unboxes correctly.
v = c.read_x
puts v        # 7

# === cls_meth_block ===
class T_cls_meth_block_Foo
  def self.with(&block)
    block.call(42)
  end
end

T_cls_meth_block_Foo.with { |n| puts n }

