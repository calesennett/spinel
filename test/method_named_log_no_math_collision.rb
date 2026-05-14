# Method names that collide with Math module functions (log, sin,
# cos, sqrt, exp, atan2, hypot, ...) should not be misinferred as
# float-returning. Previously, infer_math_and_misc_type blindly
# matched on the method name and returned float regardless of the
# receiver — so a `def log; @log; end` accessor on a non-Math
# class typed callers' locals as float and the downstream
# `obj.log[i]` index emit dispatched as float (bit access). Fix:
# gate the Math.<fn> branch on `recv` being either the literal
# Math module ConstantReadNode or absent.

class Notebook
  attr_accessor :log
  def initialize
    @log = []
  end
  def add(line)
    @log.push(line)
  end
end

n = Notebook.new
n.add("first")
n.add("second")
entries = n.log
puts entries[0]
puts entries[1]
puts entries.length.to_s

# Also verify Math.log still works
puts Math.log(1.0).to_i.to_s
