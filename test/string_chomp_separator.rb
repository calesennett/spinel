# Issue #881: String#chomp with an explicit separator argument
# strips that suffix. Without the fix the arg was silently dropped
# and the default newline rules were applied.
puts "hello!".chomp("!").inspect
puts "hello\n".chomp.inspect
puts "hello\r\n".chomp.inspect
puts "hello".chomp("!").inspect
puts "hello\n\n".chomp("").inspect
