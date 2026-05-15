# #508. Bare `attr_reader_name` and `self.attr_reader_name`
# inside a subclass instance method failed to resolve when the
# reader was declared via `attr_accessor` / `attr_reader` on the
# parent class. Codegen's attr_reader lookup only consulted
# @cls_attr_readers[current_class] and didn't walk the parent
# chain.
#
# Fix: swap the per-class loop for a call to
# `cls_has_attr_reader(ci, mname)`, which already walks
# @cls_parents recursively. Two emit sites: the bare-name path
# in compile_call_expr (instance method body, no receiver) and
# the obj-receiver path in compile_object_method_expr (the
# `self.fmt` shape).

class Base
  attr_accessor :fmt
  attr_reader :tag
  def initialize
    @fmt = :html
    @tag = :base_tag
  end
end

class Sub < Base
  def doit
    fmt == :html ? "html" : "json"
  end
  def doit_self
    self.fmt == :html ? "html-self" : "json-self"
  end
  def tag_str
    tag.to_s
  end
end

s = Sub.new
puts s.doit
puts s.doit_self
puts s.tag_str

# Deeper chain: grandchild via Mid -> Base.
class Mid < Base
end

class Leaf < Mid
  def show
    fmt.to_s + "/" + tag.to_s
  end
end

puts Leaf.new.show
