# Bundled tests:
#   - array_clear_typed
#   - array_concat

# === array_clear_typed ===
# `Array#clear` on typed arrays used to fall through the
# dispatcher and produce no C output, leaving the array
# unchanged. Zero the length (and `start` for IntArray, which
# uses a sliding window) so the next push refills from index 0.

# IntArray
ints = [1, 2, 3]
ints.clear
puts ints.length    # 0
ints.push(7)
puts ints[0]        # 7

# SymArray (shares IntArray internally)
syms = [:a, :b, :c]
syms.clear
puts syms.length    # 0

# FloatArray
floats = [1.5, 2.5, 3.5]
floats.clear
puts floats.length  # 0

# StrArray
strs = ["a", "b", "c"]
strs.clear
puts strs.length    # 0

# PtrArray (array of objects)
class T_array_clear_typed_Box
  attr_reader :n
  def initialize(n); @n = n; end
end
boxes = [T_array_clear_typed_Box.new(1), T_array_clear_typed_Box.new(2)]
boxes.clear
puts boxes.length   # 0

# PolyArray (mixed-type elements)
mixed = [1, "x", :sym, 4.5]
mixed.clear
puts mixed.length   # 0

# === array_concat ===
# Array#concat used to silently miss the type-check on both poly_array
# and ptr_array — the loop never ran, so the receiver kept its
# original length. Both shapes regression-tested here.

# poly_array (heterogeneous)
a = [1, "x"]
a.concat([2, "y"])
puts a.length

# ptr_array (user objects)
class T_array_concat_Bar
  def initialize(x); @x = x; end
  attr_accessor :x
end

b = [T_array_concat_Bar.new(1)]
b.concat([T_array_concat_Bar.new(2), T_array_concat_Bar.new(3)])
puts b.length

