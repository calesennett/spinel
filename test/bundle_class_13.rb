# Bundled tests:
#   - chained_or_assign_collection_array_nested
#   - chained_or_assign_collection_element

# === chained_or_assign_collection_array_nested ===
# 4-level chained `||=` mirroring optcarrot's PPU#setup_lut
# `@lut_update` shape:
#
#     (((@h[b] ||= [])[i] ||= [nil, nil])[0] ||= []) << v
#
# Levels 1, 2, 3 are all `||=` against poly-element receivers
# (poly_poly_hash, then a poly value carrying a poly_array twice).
# Pre-fix only level 1 was lowered; levels 2 and 3 fell through to
# the int default and the chain collapsed to `0 << ...`. The fix
# threads sp_RbVal temps through every level and promotes ArrayNode
# rhs literals (`[]`, `[nil, nil]`) to poly_array so each
# intermediate `cls_id == SP_BUILTIN_POLY_ARRAY` probe matches at
# runtime.

class T_chained_or_assign_collection_array_nested_C
  def initialize
    @h = {}
  end
  def push(b, i, v)
    (((@h[b] ||= [])[i] ||= [nil, nil])[0] ||= []) << v
  end
  def count(b, i); @h[b][i][0].length; end
end

c = T_chained_or_assign_collection_array_nested_C.new
c.push(0, 5, 10)
c.push(0, 5, 20)
c.push(0, 7, 30)
c.push(1, 0, 100)
puts c.count(0, 5)   # 2
puts c.count(0, 7)   # 1
puts c.count(1, 0)   # 1

# === chained_or_assign_collection_element ===
# `(@h[k] ||= []) << v` — chained `||=` over a Hash element with a
# trailing method call. The parenthesised subexpression evaluates
# to the (just-created or pre-existing) Array; `<<` then pushes
# into it.
#
# Pre-fix the IndexOrWriteNode expression-form fell through to the
# default catch-all and emitted literal `0` as the chain
# receiver — the resulting `sp_poly_shl(0, …)` failed T_chained_or_assign_collection_element_C compile
# (`0` is `int`, sp_poly_shl wants `sp_RbVal`). Spinel now lowers
# `(h[k] ||= v)` into a get-then-set temp that the chain reads.

class T_chained_or_assign_collection_element_C
  def initialize
    @h = {}                       # promotes to sym_poly_hash on first []=
  end
  def add(k, v)
    (@h[k] ||= []) << v
  end
  def count(k); @h[k].length; end
end

c = T_chained_or_assign_collection_element_C.new
c.add(:a, 1)
c.add(:a, 2)
c.add(:b, 10)
c.add(:b, 20)
c.add(:b, 30)
puts c.count(:a)   # 2
puts c.count(:b)   # 3

