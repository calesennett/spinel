# Array#zip on heterogeneous (poly_array) receivers — result is a
# poly_array_ptr_array (array of poly_array pairs). The result type
# was being misclassified as int_array_ptr_array, leaving inspect
# walking raw sp_RbVal bytes as ints.
puts [1, "a"].zip([2, "b"]).inspect

# Three heterogeneous arrays
puts [1, "a", :s].zip([2, "b", :t]).inspect
