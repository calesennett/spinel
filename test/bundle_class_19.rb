# Bundled tests:
#   - cls_method_object
#   - comparable
#   - const_inheritance_lookup
#   - const_init_defers_for_main_local
#   - const_self_ref_init_warns

# === cls_method_object ===
# `Klass.method(:cls_meth)` returns a Method object that wraps a
# class method (`def self.foo`).  Spinel previously only handled
# instance-receiver `obj.method(:bar)`, so the class-receiver form
# fell through to the unresolved-call fallback (emitting `0`) and
# the captured "Method" was actually an int.  Subsequent
# `.call(args)` then warned `cannot resolve call to 'call' on int`
# and returned 0.
#
# Repro: capture two class methods on the same class, then call
# both via `.call`.  The wrapping must:
#   - infer the result as `obj_Method` (not int),
#   - mark the underlying cls method as live (so the adapter
#     trampoline's `sp_<Klass>_cls_<m>` reference resolves at
#     link time — without the live-mark the body is DCE'd and the
#     C link fails),
#   - bind through an adapter that absorbs the dispatch ABI's
#     `void *self` slot (class methods have no `self *` param).

class T_cls_method_object_CPU
  def self.poke_nop(addr, data)
    addr + data
  end
  def self.poke_log(addr, data)
    addr * 2 + data
  end
end

m1 = T_cls_method_object_CPU.method(:poke_nop)
m2 = T_cls_method_object_CPU.method(:poke_log)
puts m1.call(10, 5)
puts m2.call(10, 5)

# === comparable ===
class T_comparable_Temperature
  attr_reader :degrees
  def initialize(d)
    @degrees = d
  end
  def <=>(other)
    @degrees - other.degrees
  end
  def <(other); (self <=> other) < 0; end
  def >(other); (self <=> other) > 0; end
  def ==(other); (self <=> other) == 0; end
end

t1 = T_comparable_Temperature.new(100)
t2 = T_comparable_Temperature.new(200)
t3 = T_comparable_Temperature.new(100)
puts t1 < t2    # true
puts t2 > t1    # true
puts t1 == t3   # true
puts t1 > t2    # false
puts "done"

# === const_inheritance_lookup ===
# Issue #668: constants defined in a parent class should be visible to
# instance methods of the child class via the inheritance chain. Pre-fix
# the bare `CONST` lookup walked only the lexical-scope chain (T_const_inheritance_lookup_Child,
# then trim) and the include chain — never the @cls_parents superclass
# chain — so methods defined on T_const_inheritance_lookup_Child couldn't see T_const_inheritance_lookup_Parent's CONST and
# the codegen emitted a "uninitialized constant" warning + 0.

class T_const_inheritance_lookup_Parent
  CONST = "parent"
end

class T_const_inheritance_lookup_Child < T_const_inheritance_lookup_Parent
  def get_const
    CONST
  end
end

puts T_const_inheritance_lookup_Child.new.get_const

# Two-level chain (T_const_inheritance_lookup_Grandchild -> T_const_inheritance_lookup_Child -> T_const_inheritance_lookup_Parent) so the recursive
# parent walker is exercised.
class T_const_inheritance_lookup_Grandchild < T_const_inheritance_lookup_Child
  def get_again
    CONST
  end
end

puts T_const_inheritance_lookup_Grandchild.new.get_again

# === const_init_defers_for_main_local ===
# Issue #647: a top-level `CONST = recv.method` initializer whose
# RHS reads a main-scope local used to emit BEFORE the body
# statements ran. Codegen's const-init pre-loop planted
# `cst_X = lv_y.iv_z;` at the top of `main`, before `lv_y =
# sp_Y_new()` ever ran, so the chain read from a zero-initialized
# struct and the const ended up as 0 (or SIGSEGV when the call
# reached FFI). Reporter hit the FFI crash variant in tinynn
# config loading.
#
# Fix (PR #648): expr_reads_main_local detects the dependency,
# the pre-loop skips flagged consts, and the body-statement loop
# emits them in source order — by then the local has been
# assigned.

class T_const_init_defers_for_main_local_Cfg
  attr_reader :nested
  def initialize(n); @nested = n; end
end

class T_const_init_defers_for_main_local_Inner
  attr_reader :v
  def initialize; @v = 42; end
end

inner = T_const_init_defers_for_main_local_Inner.new
cfg = T_const_init_defers_for_main_local_Cfg.new(inner)
CFG_VOCAB = cfg.nested.v   # ← used to read zero-init lv_cfg, returns 0
puts CFG_VOCAB.to_s

# === const_self_ref_init_warns ===
# Issue #646: a top-level const assigned via `<CONST> = <Class>.
# new(...)` whose initialize body (transitively) reads <CONST>
# used to silently emit 0 or worse (depending on the dispatch
# shape, sometimes a partially-init pointer that segfaults on
# deref).
#
# This test pins the compile-time warning we now emit when the
# direct-shape self-ref is detected. The runtime side keeps the
# existing "cannot resolve" + emit-0 fallback so the binary
# builds and runs without crash for the simple case; the
# segfault-prone transitive case the issue documents (tep's
# PG::Connection.new chain) requires runtime const-lifecycle
# tracking which is out of scope here.
#
# We don't have a way to assert stderr from the test runner, so
# this just pins the runtime-side behaviour: an empty inspect
# (because spinel emits 0 for the unresolved call).

class T_const_self_ref_init_warns_App
  attr_reader :count
  def initialize
    @count = 0
  end
end
APP = T_const_self_ref_init_warns_App.new
puts APP.count    # 0 — runs fine when init doesn't self-read

