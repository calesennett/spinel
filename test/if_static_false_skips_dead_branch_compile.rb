# `compile_cond_expr` already returns the literal "FALSE" for a
# predicate whose static type is `nil` (e.g. an attr-style read
# of an ivar only ever assigned `nil`). The if/unless emit then
# wraps the dead body in `if (FALSE) { … }`, but the body's C
# statements still pass through gcc — and they often type-error
# against ivars/methods whose shapes only make sense when the
# predicate is true. Skipping body emission lets the rest of
# the program compile.

class Profiler
  def initialize
    # `@mode` is statically nil — only ever assigned this literal.
    # The read in the predicate below folds to `if (FALSE)`.
    @mode = nil
  end

  def run
    # Dead branch when @mode is nil. Pre-fix, spinel emits the
    # body anyway: `sp_str_sub("...", "MODE", iv_mode)` with
    # iv_mode typed as `mrb_int` (its only init being `= nil`)
    # — the 3rd arg fails -Wint-conversion.
    if @mode
      out = "label_MODE".sub("MODE", @mode)
      puts out
    end
    puts "ran"
  end
end

# `if @nil_ivar; ... else; ... end` with a trailing stmt forces
# the if into statement position (compile_if_stmt). The else arm
# is the live one when the predicate is statically nil.
class Either
  def initialize
    @verbose = nil
  end

  def run
    if @verbose
      out = "label_MODE".sub("MODE", @verbose)
      puts out
    else
      puts "quiet"
    end
    puts "done"
  end
end

Profiler.new.run
Either.new.run
