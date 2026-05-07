# Auto-unbox poly RHS into a primitive int local slot. Common
# case: `lv = arr[i]` where arr's element dispatch returns poly
# (heterogeneous element types) but the local was already inferred
# as int from a prior write. Spinel previously emitted
# `lv = <sp_RbVal>;` and the C compile failed (`incompatible
# types when assigning to type 'mrb_int' from type 'sp_RbVal'`).
#
# Repro: an ivar widened to poly via two distinct array shapes
# (an int_array and a poly_array). The local `pixel` was first
# set from an int_array (so its declared C type is mrb_int),
# then a second write reassigns from the poly slot. Without
# auto-unbox, the second assignment fails.

class C
  def make_int_arr
    @arr = [10, 20, 30]
  end
  def make_poly_arr
    @arr = [nil] * 3
    @arr[0] = 99
    @arr[1] = "x"
    @arr[2] = :y
  end
  def first_int
    @arr[0]
  end
end

c = C.new
c.make_int_arr
pixel = c.first_int   # int from int_array
puts pixel.to_s

c.make_poly_arr
pixel = c.first_int   # poly from poly_array, must auto-unbox
puts pixel.to_s
