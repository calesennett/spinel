# Issue #398: `@@x op= rhs` was rejected as unsupported syntax
# (`ClassVariableOperatorWriteNode` had no parser/codegen handling).
# `@@x = @@x op rhs` worked. Same gap for `||=` / `&&=`. Adds the
# parser cases (PM_CLASS_VARIABLE_{OPERATOR,OR,AND}_WRITE_NODE) and
# codegen arms (compile_stmt, compile_expr, compile_body_return).
#
# Limited to type-compatible cvar slots: cvar widening (e.g.
# `@@x = nil; @@x ||= "str"` needing the slot to widen from int
# to string) is a separate issue (sister to ivar widening at
# scan_ivars).

class Counter
  @@count = 0
  @@total = 100
  @@flag = 1

  def self.bump
    @@count += 1
    @@total += 10
  end

  def self.shift
    @@count <<= 2
  end

  def self.zero_flag
    @@flag &&= 7
  end

  def self.report
    puts @@count
    puts @@total
    puts @@flag
  end
end

Counter.bump
Counter.bump
Counter.bump
Counter.report     # 3, 130, 1

Counter.shift
Counter.report     # 12, 130, 1

Counter.zero_flag  # @@flag is truthy (1), so &&= writes 7
Counter.report     # 12, 130, 7
