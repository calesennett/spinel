# `$PROGRAM_NAME` / `$0` are Ruby's standard aliases for the program
# name as a String. Pre-fix spinel registered them as mrb_int 0 (the
# default for an unwritten GlobalVariableReadNode), so the canonical
# `__FILE__ == $PROGRAM_NAME` autorun guard failed C compile with
# the standard int-to-pointer mismatch.
#
# Now scan_features auto-registers `$PROGRAM_NAME` / `$0` as
# `string`, and emit_main populates the global from argv[0] at
# startup. The runtime value is the binary's argv[0] (not the
# Ruby source path) — `__FILE__` is a compile-time literal that
# carries the source path, so the canonical guard usually won't
# match a compiled-binary invocation. The fix is about compile-
# correctness; runtime semantics for the guard are a known
# limitation noted in the issue.

puts $PROGRAM_NAME.length > 0
puts $0.length > 0
