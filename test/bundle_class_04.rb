# Bundled tests:
#   - array_new_block_typed_container
#   - array_new_empty_inner_deferred

# === array_new_block_typed_container ===
# `Array.new(N) { block }` should pick its accumulator container
# from the block's return type, not collapse to IntArray. Without
# the fix, `Array.new(N) { _x = [0]; _x.clear; _x }` (the seed-int
# idiom for an empty-but-typed inner array) emits a flat IntArray
# at the T_array_new_block_typed_container_C level, then later `<<` pushes silently cast pointers
# to ints — every read returns 0.
#
# The fix mirrors compile_map_expr's range / typed-container
# branch: infer the block tail's type and emit StrArray /
# FloatArray / PtrArray<X> / PolyArray accordingly. Three call
# sites need it (infer_type, infer_ivar_init_type,
# compile_constructor_expr) so the ivar widening pipeline stays
# consistent.

class T_array_new_block_typed_container_C
  def initialize
    @typed = Array.new(4) { _a = [0]; _a.clear; _a }
    @strs  = Array.new(3) { |i| "row#{i}" }
    @flts  = Array.new(3) { |i| i.to_f * 0.5 }
  end
  def push_typed(i, v); @typed[i] << v; end
  def get_typed(i, j); @typed[i][j]; end
  def get_str(i); @strs[i]; end
  def get_flt(i); @flts[i]; end
end

c = T_array_new_block_typed_container_C.new
c.push_typed(0, 100)
c.push_typed(0, 200)
c.push_typed(2, 999)
puts c.get_typed(0, 0)    # 100
puts c.get_typed(0, 1)    # 200
puts c.get_typed(2, 0)    # 999
puts c.get_str(0)         # row0
puts c.get_str(2)         # row2
puts c.get_flt(0)         # 0.0
puts c.get_flt(2)         # 1.0

# === array_new_empty_inner_deferred ===
# `Array.new(N) { [].dup }` returns an array of N empty-array
# inners. The static element type of `[]` is ambiguous — int_array
# is the natural default but if later pushes drop pointer-typed
# values (3-tuples, IntArrays, ...) into the inner, that fallback
# silently truncates the pointer to mrb_int and the cache is
# corrupt.
#
# After the fix, `Array.new(N) { [].dup }` (and `{ [] }`) emits
# each inner as a fresh sp_PolyArray. Pushes go through the
# sp_poly_shl runtime cls_id dispatch (any kind survives), and
# `arr[i][j]` reads back the boxed element with its real cls_id
# preserved. The outer Array.new returns `poly_array` so the
# whole structure is sp_PolyArray of sp_PolyArrays.
#
# Also covers the multi-write destructure poly RHS shape that
# arises naturally:
# `@a, @b, = entries[key]` against entries: poly_poly_hash whose
# values are 3-element arrays. compile_multi_write now recognizes
# val_t_local == "poly" and unboxes via cls_id-POLY_ARRAY check.

class T_array_new_empty_inner_deferred_C
  def initialize
    @inners = [Array.new(4) { [].dup }, Array.new(4) { [].dup }]
  end
  def add_tuple(b, i, io, ptr, shift)
    entry = [io, ptr, shift]
    @inners[b][i] << entry
  end
  def get_io(b, i, k);    @inners[b][i][k][0]; end
  def get_shift(b, i, k); @inners[b][i][k][2]; end
  def len(b, i);          @inners[b][i].length; end
end

c = T_array_new_empty_inner_deferred_C.new
inner_a = [10, 20, 30]
inner_b = [40, 50, 60]
c.add_tuple(0, 0, 0x100, inner_a, 4)
c.add_tuple(0, 0, 0x200, inner_b, 6)
c.add_tuple(1, 2, 0x300, inner_a, 0)
puts c.get_io(0, 0, 0)        # 256
puts c.get_shift(0, 0, 0)     # 4
puts c.get_io(0, 0, 1)        # 512
puts c.get_shift(0, 0, 1)     # 6
puts c.get_io(1, 2, 0)        # 768
puts c.len(0, 0)              # 2
puts c.len(1, 2)              # 1
puts c.len(0, 3)              # 0

