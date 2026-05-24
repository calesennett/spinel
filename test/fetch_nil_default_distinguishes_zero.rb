# #682: hash.fetch(k, nil).nil? must distinguish missing-key
# from a legit zero value.

# Present key with value 0
h0 = {k: 0}
v0 = h0.fetch(:k, nil)
puts v0.nil? ? "missing" : "found-0"

# Missing key
hm = {}
vm = hm.fetch(:k, nil)
puts vm.nil? ? "missing" : "found-m"

# Present key with non-zero value
h1 = {k: 42}
v1 = h1.fetch(:k, nil)
puts v1.nil? ? "missing" : "found-#{v1}"

# Same shape with str_int_hash
hs = {"a" => 0}
vs = hs.fetch("a", nil)
puts vs.nil? ? "missing-str" : "found-str-#{vs}"

hsm = {}
vsm = hsm.fetch("a", nil)
puts vsm.nil? ? "missing-str-key" : "found-str-bad"
