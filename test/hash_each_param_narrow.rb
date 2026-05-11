# Issue #408. Regression guard for the hash-each body-walker
# narrow path (9ca01d7 + analyze-side port in 02003ad).
#
# Pre-fix shape: a class method whose only signal on its hash
# param is `h.each |k, v|` inside the body left `h` typed as
# poly_poly_hash, made `k` / `v` poly, and the str-concat
# `\"\\\"\" + k + \"\\\":\"` cascaded into compile errors at the C
# layer ("passing sp_RbVal to parameter of incompatible type
# 'const char *'").
#
# Post-fix: the body-walker harvests usage signals -- here, k/v
# both flowing into str-concat -- and narrows the param to
# str_str_hash (or str_int_hash when v is int-shaped). Both
# compile clean and produce the expected output.
#
# This test re-runs the exact confirmation snippet Ori posted on
# #408; closing the issue without a regression guard would leave
# the narrow path exposed to silent regressions on future
# refactors to the each-body walker.

class Encoder
  def self.from_str_hash(h)
    out = "{"
    first = true
    h.each do |k, v|
      out += "," unless first
      first = false
      out += "\"" + k + "\":\"" + v + "\""
    end
    out + "}"
  end

  def self.from_int_hash(h)
    out = "{"
    first = true
    h.each do |k, v|
      out += "," unless first
      first = false
      out += "\"" + k + "\":" + v.to_s
    end
    out + "}"
  end
end

puts Encoder.from_str_hash({"name" => "alice", "city" => "NYC"})
puts Encoder.from_int_hash({"a" => 1, "b" => 2, "c" => 3})
