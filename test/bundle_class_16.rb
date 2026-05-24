# Bundled tests:
#   - class_constant_sym_array
#   - class_method_kwarg_pass_through

# === class_constant_sym_array ===
class T_class_constant_sym_array_Parser
  SOFT_IDENTIFIER_KEYWORDS = %i[with]
  SHADOWED = %i[class]

  def soft?(value)
    SOFT_IDENTIFIER_KEYWORDS.include?(value)
  end

  def shadowed?(value)
    SHADOWED.include?(value)
  end
end

SHADOWED = %i[top]

puts T_class_constant_sym_array_Parser.new.soft?(:with)        # true
puts T_class_constant_sym_array_Parser.new.soft?(:without)     # false
puts T_class_constant_sym_array_Parser.new.shadowed?(:class)   # true
puts T_class_constant_sym_array_Parser.new.shadowed?(:top)     # false

# === class_method_kwarg_pass_through ===
# Class-method dispatch with a kwarg passed at the call site
# (`T_class_method_kwarg_pass_through_W.write(200, set_cookies: cookies)`) previously dropped the
# kwarg value to 0 because compile_constant_recv_expr's class-method
# branch used the generic compile_call_args, which walks the
# KeywordHashNode as an opaque arg and lowers it to a literal that
# resolves to 0 at the call site. The fix extracts kwargs by name
# from the call site and routes each pair to the matching param
# slot, falling back to the recorded default for missing slots.
# Same shape as compile_call_args_with_defaults' instance-method
# handler but reading from @cls_cmeth_* tables.

class T_class_method_kwarg_pass_through_W
  def self.write(status, set_cookies: {})
    n = 0
    set_cookies.each do |name, val|
      n = n + 1
    end
    n
  end
end

cookies = { flash_notice: "Hi", deferred: "Bye" }
puts T_class_method_kwarg_pass_through_W.write(200, set_cookies: cookies).to_s
puts T_class_method_kwarg_pass_through_W.write(404).to_s

