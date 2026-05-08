# `arr.each {|a, b| ... }` over a poly receiver (an sp_RbVal that
# carries an array of arrays at runtime) should auto-splat each
# element across the block params, matching CRuby's
# `arr.each {|*args| a, b, *_ = args }` shape.  Pre-fix the poly
# branch only assigned `bp1` and dropped `bp2`, so e.g.
# `[[1, 2], [3, 4]].each {|a, b| sum += a + b }` skipped `b`
# entirely.  Cover both inner kinds the destructuring uses:
# poly_array (heterogeneous element types) and int_array
# (homogeneous int element types — what `[i, fixed]` lowers to in
# optcarrot's `setup_lut`).

class C
  def initialize
    @h = {}
  end

  def push_int(bank, pair)
    # `pair` lowers to int_array because both elements are ints.
    (@h[bank] ||= []) << pair
  end

  def push_poly(bank, pair)
    # `pair` lowers to poly_array because the elements are mixed.
    (@h[bank] ||= []) << pair
  end

  def each_pair(bank)
    arr = @h[bank]
    sum = 0
    arr.each {|a, b| sum += a.to_i + b.to_i }
    sum
  end
end

c = C.new
c.push_int(0, [10, 20])
c.push_int(0, [3,  4])
puts c.each_pair(0)         # 10 + 20 + 3 + 4 = 37

d = C.new
d.push_poly(1, [100, "x"])  # b is a string, exercising the poly_array branch
d.push_poly(1, [5,   "y"])
puts d.each_pair(1)         # 100 + 0 + 5 + 0 = 105 (string `to_i` of "x" / "y" = 0)
