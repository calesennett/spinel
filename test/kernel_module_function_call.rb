# Issue #428. `Kernel.<m>` cmeth-style calls (the disambiguator
# users reach for when a `def self.<m>` shadows a Kernel
# module-function) emitted `0` instead of dispatching. Bare
# `<m>(...)` worked but couldn't be used inside a method body
# that shadowed the name -- which is exactly when callers
# write `Kernel.<m>`.
#
# Fix: in compile_object_method_expr's recv_type == "class"
# arm, when the recv AST is the ConstantReadNode "Kernel",
# route through compile_no_recv_call_expr. The bare-dispatch
# path already handles every Kernel module-function the
# runtime ships (sleep / puts / print / rand / etc.), so the
# Kernel-prefixed form gets the same shape uniformly.

class Sched
  def self.nap(seconds)
    # Kernel-prefixed to disambiguate from a hypothetical
    # def self.sleep on the same class.
    Kernel.sleep(seconds)
    0
  end
end

Sched.nap(0)
puts "ok"
