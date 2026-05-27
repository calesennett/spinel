# Issue #900: String#<=> dispatches strcmp clamped to -1/0/1.
# Pre-fix: always returned 0.
puts "abc" <=> "abd"
puts "abd" <=> "abc"
puts "abc" <=> "abc"
puts "ab" <=> "abc"
