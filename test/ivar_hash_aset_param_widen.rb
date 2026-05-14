# #488. A class method writing a param into a typed ivar hash —
# `@data[key] = value` where @data is pinned to e.g. str_str_hash
# by another method — left the writer's `key` and `value` params
# at the `mrb_int` default. The C emit then passed mrb_int into
# the const char * key / value slots and failed -Wint-conversion.
# Sibling to #482's nil-default + Hash-receiver back-propagation
# pass; this one covers the @hash-write side of the same
# back-propagation gap.

class Bag
  def initialize
    @data = {}
  end

  # Pins @data to str_str_hash from a typed source.
  def populate(source)
    source.each do |k, v|
      @data[k] = v
    end
  end

  # No caller; without back-propagation `key` and `value` stayed
  # at mrb_int and the body's sp_StrStrHash_set fired
  # -Wint-conversion.
  def []=(key, value)
    @data[key] = value
  end

  def fetch(k)
    @data[k]
  end
end

b = Bag.new
b.populate({ "x" => "hello" })
puts "ok"
puts b.fetch("x")
