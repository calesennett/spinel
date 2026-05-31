# A `require` of a natively-provided lib (json) is a silent no-op and the
# module still works. A `require` of an unsupported stdlib (tmpdir) warns
# at compile time ("not available in Spinel"; goes to stderr, not checked
# here) but is ignored so the rest of the program still compiles and runs.
require "json"
require "tmpdir"
puts JSON.generate([1, 2, 3])
puts "ok"
