# #674: `hash.fetch(k, nil)` into an int-typed LV must not lower to
# ((const char *)NULL) (would trip -Wint-conversion).
#
# #682: the .nil? check on the LV must report "missing" when the key
# is absent. Spinel's int-leaf hash fetch with a nil default returns
# SP_INT_NIL so the LV's int? slot distinguishes missing-key from a
# legit 0 value.

def f(opts = {})
  v = opts.fetch(:k, nil)
  v.nil? ? "missing" : "found"
end

puts f
