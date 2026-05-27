# Numeric#coerce - CRuby returns [other.cast, self.cast] where the
# common type is Float when either operand is Float, else Integer.
# Previously SEGV'd: int.coerce(...) fell through unresolved-call
# emitting 0, then the destructure dereferenced as pointer.

a1, b1 = 1.coerce(2.5)
puts a1.inspect
puts b1.inspect

a2, b2 = 3.coerce(7)
puts a2.inspect
puts b2.inspect

a3, b3 = 2.5.coerce(1)
puts a3.inspect
puts b3.inspect

a4, b4 = 1.5.coerce(2.5)
puts a4.inspect
puts b4.inspect

# Idiomatic use: implement a numeric op via coerce.
x, y = 1.coerce(2.5)
puts x + y
