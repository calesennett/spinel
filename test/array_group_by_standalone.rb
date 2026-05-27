# Array#group_by — standalone (no fused .each) returns a hash
# keyed by the block result with arrays of matching elements.
# Backed by poly_poly_hash + boxed poly_array values; key insertion
# order is preserved.
puts [1,2,3,4,5,6].group_by { |x| x % 3 }.inspect
puts ["apple","ant","bee","cat","cow"].group_by { |s| s[0] }.inspect
