# Multi-write `a, b = rhs` where rhs's static type is `poly` (an
# sp_RbVal that carries a poly_array at runtime).  Pre-fix:
# `multi_write_target_type` fell through to the default `int` for
# rt == "poly", so `a` / `b` were declared as mrb_int and the
# emit-side dispatch (which DOES handle `val_t_local == "poly"` by
# unboxing to sp_PolyArray*) wrote `(sp_PolyArray_get(...)).v.i`,
# truncating the poly elements to garbage ints.

class C
  def setup
    @h = {}
    [0, 1].each do |bank|
      [0, 1].each do |idx|
        # Outermost ||= produces a poly_poly_hash slot, then a
        # poly_array of poly_arrays of two-tuples — same shape as
        # optcarrot's @lut_update.
        (((@h[bank] ||= [])[idx] ||= [nil, nil])[0] ||= []) << [idx * 10 + bank, idx + bank]
      end
    end
  end

  def name_lut_size(bank, idx)
    # Multi-write whose RHS infers to `poly`: @h[bank][idx] indexes
    # into poly_poly_hash (returns poly), then into the unboxed
    # poly_array (returns poly).
    name_lut_update, _attr_lut_update = @h[bank][idx]
    name_lut_update.length
  end
end

c = C.new
c.setup
# bank=1 / idx=0 yields a 1-element list (one push at this slot).
puts c.name_lut_size(1, 0)
