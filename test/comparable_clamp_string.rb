# Issue #899: Comparable#clamp on a string receiver via strcmp.
puts "b".clamp("a", "c")
puts "z".clamp("a", "c")
puts "a".clamp("b", "c")
