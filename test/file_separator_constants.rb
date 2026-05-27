# Issue #891: File::SEPARATOR / PATH_SEPARATOR / ALT_SEPARATOR
# resolved at compile time as string literals.
puts File::SEPARATOR
puts File::PATH_SEPARATOR
puts "a" + File::SEPARATOR + "b"
