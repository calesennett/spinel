# Issue #402: array literal of hash literals (`[{n: 3}, {n: 1}]`)
# was typed as `sp_IntArray *` (the bottom default in
# infer_array_elem_type_from_ids), but the elements were emitted
# as `sp_SymIntHash *` -- `sp_IntArray_push(int_array, hash_ptr)`
# fails C-compile with int-from-pointer.
#
# Fix: the inference now recognises hash-typed elements and
# returns `poly_array` (no `<hash>_ptr_array` slot exists in
# Spinel; box each element via the poly path).

arr = [{n: 3}, {n: 1}, {n: 2}]
puts arr.length          # 3
puts arr[0][:n].to_s     # 3
puts arr[1][:n].to_s     # 1
puts arr[2][:n].to_s     # 2

# Mixed hash key/value shapes also work (each element widens to
# poly via box_hash_to_poly).
mixed = [{a: 1}, {b: "x"}]
puts mixed.length        # 2
