# Bundled tests:
#   - bare_imeth_subclass_dispatch
#   - bare_return_in_cls_method
#   - bare_return_in_poly_method
#   - bare_self_method_float_return_local
#   - block_local_arg_to_method_call

# === bare_imeth_subclass_dispatch ===
# Bare-receiver instance method call from inside a parent-defined
# method dispatches to the subclass override at runtime, not to the
# parent's stub. Pre-fix the codegen resolved imeth statically
# against the method body's defining class, so a T_bare_imeth_subclass_dispatch_Child instance
# routed through T_bare_imeth_subclass_dispatch_Base#run always landed on T_bare_imeth_subclass_dispatch_Base#hook.
#
# Imeth analog of the cmeth dispatch handled by the
# self_class_subclass_dispatch sibling test. The bare imeth call
# site lowers to a `switch (self->cls_id)` when descendants of the
# current class override the imeth.
#
# Coverage:
#   - Plain T_bare_imeth_subclass_dispatch_Base/T_bare_imeth_subclass_dispatch_Child override.
#   - Multi-level (T_bare_imeth_subclass_dispatch_GrandChild overrides hook).
#   - Subclass that doesn't override -- inherits via the default
#     (T_bare_imeth_subclass_dispatch_Sibling has no #hook, falls through to T_bare_imeth_subclass_dispatch_Base).
#   - Direct T_bare_imeth_subclass_dispatch_Base instance still routes to T_bare_imeth_subclass_dispatch_Base.

class T_bare_imeth_subclass_dispatch_Base
  def run
    hook
  end

  def hook
    puts "BASE"
  end
end

class T_bare_imeth_subclass_dispatch_Child < T_bare_imeth_subclass_dispatch_Base
  def hook
    puts "CHILD"
  end
end

class T_bare_imeth_subclass_dispatch_GrandChild < T_bare_imeth_subclass_dispatch_Child
  def hook
    puts "GRANDCHILD"
  end
end

class T_bare_imeth_subclass_dispatch_Sibling < T_bare_imeth_subclass_dispatch_Base
end

T_bare_imeth_subclass_dispatch_Base.new.run
T_bare_imeth_subclass_dispatch_Child.new.run
T_bare_imeth_subclass_dispatch_GrandChild.new.run
T_bare_imeth_subclass_dispatch_Sibling.new.run

# === bare_return_in_cls_method ===
# Issue #314 follow-up: a class method whose return type was
# inferred as `obj_<C>` (because every explicit return path
# produced a value of that class) lowered a bare `return` to
# `return self;` — but class methods have no `self` C param, so
# gcc complained `'self' undeclared`.
#
# Fix: thread a `@current_method_has_self` flag through the
# instance-method / class-method / top-level / constructor-
# synthesis emit paths. compile_return_stmt's bare-return-with-
# obj_<C>-return path emits `return self;` only when has_self=1,
# otherwise `return c_return_default(...);` (which knows about
# value vs pointer object types).
#
# Companion to b9d6303 (#337) which added the obj_<C> branch for
# constructor synthesis.
#
# Surfaced via Roundhouse's `InMemoryAdapter.update` — a module
# class method whose return type was inferred as obj_HWIA via
# the `attrs.each` last-expression, with an early `return if
# row.nil?` lowering to broken `return self;`.

class T_bare_return_in_cls_method_Holder
  attr_reader :id
  def initialize(id)
    @id = id
  end

  def self.maybe(id)
    if id < 0
      return       # ← bare return; bug emitted `return self;`
    end
    T_bare_return_in_cls_method_Holder.new(id)
  end
end

# Pushing into a [T_bare_return_in_cls_method_Holder] array forces T_bare_return_in_cls_method_Holder out of the value-type
# bucket so `T_bare_return_in_cls_method_Holder.maybe` returns `sp_Holder *` (pointer) and the
# bare-return shape exercises the pointer fallback.
holders = [T_bare_return_in_cls_method_Holder.new(0)]

a = T_bare_return_in_cls_method_Holder.maybe(42)
holders << a
puts a.id                 # 42

b = T_bare_return_in_cls_method_Holder.maybe(-1)
puts b.nil?               # true

# === bare_return_in_poly_method ===
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

class T_bare_return_in_poly_method_Adapter
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
puts T_bare_return_in_poly_method_Adapter.lookup("x").to_s
puts T_bare_return_in_poly_method_Adapter.lookup("none").to_s

# === bare_self_method_float_return_local ===
class T_bare_self_method_float_return_local_Vec3
  def initialize(x, y, z)
    @x = x
    @y = y
    @z = z
  end

  def length2
    @x * @x + @y * @y + @z * @z
  end

  def length
    Math.sqrt(length2)
  end

  def normalize
    len = length
    return T_bare_self_method_float_return_local_Vec3.new(0.0, 0.0, 0.0) if len <= 0.0

    inv = 1.0 / len
    T_bare_self_method_float_return_local_Vec3.new(@x * inv, @y * inv, @z * inv)
  end

  attr_reader :x
end

puts T_bare_self_method_float_return_local_Vec3.new(2.5, 0.0, 0.0).normalize.x

# === block_local_arg_to_method_call ===
# #484. A class method whose body iterates `arr.each do |bp| ... end`
# and passes `bp` to another class method's call previously left the
# callee's param at the `mrb_int` default. The same shape at top-
# level worked because infer_main_call_types uses the full scan_locals
# walker which already records block-param types into scope before
# scan_new_calls widens call-site arg types. The class-method path
# used scan_locals_first_type which omitted block-param handling.
# Fix: scan_locals_first_type now picks up RequiredParameterNode
# entries for `recv.method do |bp| ... end` blocks and records the
# inferred element type (str_array -> string, etc.).

class T_block_local_arg_to_method_call_M
  def self.use(s)
    s.length
  end

  def self.driver
    ["a", "b"].each do |pair|
      T_block_local_arg_to_method_call_M.use(pair)
    end
  end
end

T_block_local_arg_to_method_call_M.driver
puts "ok"

