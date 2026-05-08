# Regression: a setter call (`obj.x = val`) on a parameter typed as
# a class union must execute the assignment. Previously the dispatch
# loop emitted no arms for attr_writer setters on poly receivers and
# silently dropped the store.

class Foo
  attr_accessor :x
  def initialize; @x = 0; end
end

class Bar
  # No `x`; coexists only to widen `obj` to a class union.
end

def set_x(obj, v)
  obj.x = v
end

foo = Foo.new
bar = Bar.new
set_x(foo, 42)
set_x(bar, 99) rescue nil

puts foo.x

# And the case that bit tep: two classes share an ivar name. Both
# arms must emit, and the result temp's C type must match the slot
# (string here, not the default int).
class Req
  attr_accessor :body
  def initialize; @body = ""; end
end

class Res
  attr_accessor :body
  def initialize; @body = ""; end
end

def set_body(o, b)
  o.body = b
end

req = Req.new
res = Res.new
set_body(req, "REQ")
set_body(res, "RES")
puts req.body
puts res.body
