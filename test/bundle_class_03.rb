# Bundled tests:
#   - array_flat_map
#   - array_method_name_clash

# === array_flat_map ===
# Array#flat_map where the block returns a poly_array / ptr_array
# failed to type the result; the inferred receiver-array type clashed
# with the generated inner accumulator. Both shapes covered.

# poly_array
a = [1, "x"].flat_map { |pe| [pe, pe] }
puts a.length

# ptr_array
class T_array_flat_map_Bar
  def initialize(x); @x = x; end
  attr_accessor :x
end

b = [T_array_flat_map_Bar.new(1), T_array_flat_map_Bar.new(2)].flat_map { |re| [re, re] }
puts b.length

# === array_method_name_clash ===
# A user class with a method whose name overlaps an Array method (e.g.
# `def sample`, `def first`) used to compile to the Array dispatch even
# when the receiver wasn't an array. `array_c_prefix` falls back to
# `IntArray`, so e.g. `m.sample` on `sp_Mixer *` emitted
# `sp_IntArray_get(m, rand() % sp_IntArray_length(m))` and gcc rejected
# the pointer-type mismatch.

class T_array_method_name_clash_Mixer
  def sample
    42
  end
end

m = T_array_method_name_clash_Mixer.new
puts m.sample

