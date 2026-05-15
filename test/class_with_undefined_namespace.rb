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

class SomeUnknown::Thing
  def x
    42
  end
end

puts SomeUnknown::Thing.new.x
