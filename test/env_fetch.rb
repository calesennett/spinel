# Regression: `ENV.fetch(key, default)` returns the env value when
# set, otherwise `default`. Pre-fix the codegen emitted "cannot
# resolve call to 'fetch' on int" and segfaulted at runtime.

# ---- unset / default branch ----

# Literal default.
puts ENV.fetch("DEFINITELY_UNSET_VAR_XYZ_42", "fallback-value")

# Default expression need not be a literal.
default = "computed-default"
puts ENV.fetch("ANOTHER_UNSET_VAR_XYZ_42", default)

# Default by string concatenation.
puts ENV.fetch("THIRD_UNSET_VAR_XYZ_42", "pre-" + "fix")

# ---- set / retrieval branch ----
# Spinel doesn't currently expose `ENV[]=` from Ruby, so we can't
# set a var ourselves. HOME is always exported by POSIX `make` and
# in CI, so we use that as the "set" probe. We only assert "non-
# empty + not the fallback string" so the test stays portable
# across runners (the actual home value differs per machine).
# A regression that inverted the getenv-result ternary would
# return the fallback here and print "set=fallback-not-used".
home = ENV.fetch("HOME", "fallback-not-used")
if home.length > 0 && home != "fallback-not-used"
  puts "set=ok"
else
  puts "set=" + home
end

# Symmetric: an unset var with a literal default round-trips
# through the same ternary. (Would catch a regression that always
# returned the env value -- empty string -- regardless.)
maybe = ENV.fetch("DEFINITELY_UNSET_VAR_ABC_99", "fallback-used")
puts "unset=" + maybe
