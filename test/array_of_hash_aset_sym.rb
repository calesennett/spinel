# Chained `[]=` / `[]op=` on a poly_array element that is a
# boxed SymIntHash: `arr[i][:k] = v` and `arr[i][:k] += v`.
#
# Mirror of Issue #456 (chained_aset_on_poly_hash_recv.rb) for
# the symbol-idx side. The string-idx arm was already present in
# the poly-recv `[]=` dispatch, but the symbol-idx arm was
# missing — the assignment fell through to the Array arms
# (PolyArray / PtrArray / IntArray) whose cls_id never matched
# SP_BUILTIN_SYM_INT_HASH, so the write silently no-op'd.
#
# Same gap existed for `compile_index_op_assign` (`[]op=`): when
# recv was inferred as poly (e.g. `arr[i]` returning sp_RbVal),
# no Hash-storage arm was emitted, so `arr[i][:k] += v` and the
# each-block analog `f[:k] += v` (with `f` widened to poly)
# silently dropped the modification.
#
# Fix: add a symbol-idx arm next to the string-idx arm in the
# `[]=` dispatch (SymIntHash + SymPolyHash), and a poly-recv +
# symbol-idx arm to `compile_index_op_assign` (SymIntHash;
# SymPolyHash compound-assign needs poly-op semantics, deferred).

# T1: direct `[]=` on poly_array of sym_int_hash
arr1 = [{x: 1}]
arr1[0][:x] = 99
puts arr1[0][:x].to_s

# T2: compound `[]+=` on poly_array of sym_int_hash
arr2 = [{x: 1}]
arr2[0][:x] += 100
puts arr2[0][:x].to_s

# T3: `each` block mutating each hash via `f[:k] += v`
arr3 = []
arr3 << {x: 1}
arr3 << {x: 3}
arr3.each { |f| f[:x] += 100 }
puts arr3[0][:x].to_s
puts arr3[1][:x].to_s

# T4: `each_with_index` block doing direct `f[:k] = v`
arr4 = [{x: 1}, {x: 3}]
arr4.each_with_index { |f, i| f[:x] = i * 10 }
puts arr4[0][:x].to_s
puts arr4[1][:x].to_s
