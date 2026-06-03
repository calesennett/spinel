# Struct#to_h with a block yields each (member_symbol, value) pair and
# builds a hash from the [k, v] arrays the block returns. The block keys
# below are stringified so the output is independent of the symbol-key
# inspect format (which differs across Ruby versions).
Person = Struct.new(:name, :age)
p = Person.new("Alice", 30)
puts(p.to_h { |name, val| [name.to_s, val] }.inspect)

Point = Struct.new(:x, :y)
pt = Point.new(3, 4)
# transform the value too
puts(pt.to_h { |k, v| [k.to_s, v * 2] }.inspect)
# both elements stringified (block returns a str_array)
puts(pt.to_h { |k, v| [k.to_s, v.to_s] }.inspect)

# heterogeneous members (string, int, bool)
Rec = Struct.new(:label, :count, :on)
r = Rec.new("widget", 7, true)
puts(r.to_h { |k, v| [k.to_s, v] }.inspect)
