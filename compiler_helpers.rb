# Shared helpers used by both spinel_analyze.rb and
# spinel_codegen.rb. Extracted to avoid byte-for-byte
# duplication between the two compiler passes. Both passes
# already share node-table accessors (@nd_type / @nd_name /
# @nd_arguments / etc.) and class-table accessors
# (cls_find_method / cls_method_return / etc.) by virtue of
# both defining a `class Compiler`; the methods here only
# depend on that shared surface.
#
# To add a helper here it must:
# - depend only on instance vars / methods that exist on
#   BOTH the analyze-side and codegen-side Compiler
# - not perform pass-specific side effects (emit, push narrow
#   stack only via methods both sides define, etc.)
# - have identical semantics in both passes (drift between
#   the two would re-introduce the original bug)
class Compiler

 # ---- Nil-guard narrow helpers (#550) ----

 # `<lv>.nil?` predicate. Returns the LV name; otherwise "".
  def parse_nil_predicate(pred_id)
    if pred_id < 0
      return ""
    end
    if @nd_type[pred_id] != "CallNode"
      return ""
    end
    if @nd_name[pred_id] != "nil?"
      return ""
    end
    recv = @nd_receiver[pred_id]
    if recv < 0 || @nd_type[recv] != "LocalVariableReadNode"
      return ""
    end
    @nd_name[recv]
  end

 # Body ends with a definite scope exit. Used by the nil-guard
 # narrow (issue #550) to identify guards whose continuation
 # only fires when the predicate held. Recognizes:
 # - `return X` (ReturnNode)
 # - `raise ...` / `throw ...` (CallNode)
 # - `break` / `next` (BreakNode / NextNode) -- both unwind
 #   the iteration / loop, so the narrow applies to the rest
 #   of the enclosing block.
  def body_definitely_exits?(body_id)
    if body_id < 0
      return 0
    end
    stmts_r = get_stmts(body_id)
    if stmts_r.length == 0
      return 0
    end
    last = stmts_r[stmts_r.length - 1]
    if @nd_type[last] == "ReturnNode"
      return 1
    end
    if @nd_type[last] == "BreakNode" || @nd_type[last] == "NextNode"
      return 1
    end
    if @nd_type[last] == "CallNode" && (@nd_name[last] == "raise" || @nd_name[last] == "throw")
      return 1
    end
    0
  end

 # Given the rhs of the most recent write to a local variable
 # whose nil? was just checked, return the type the variable
 # narrows to after the nil-exit. Currently recognizes
 # `<string>.index(needle)` / rindex / find_index returning
 # int-or-nil; the non-nil arm is mrb_int. Returns "" when the
 # writer's shape isn't a known int-or-nil source so the caller
 # leaves the type alone. Issue #550.
  def infer_nil_guard_narrow_type(expr_id)
    if expr_id < 0
      return ""
    end
    if @nd_type[expr_id] != "CallNode"
      return ""
    end
    mname_eg = @nd_name[expr_id]
    if mname_eg != "index" && mname_eg != "rindex" && mname_eg != "find_index"
      return ""
    end
    recv_eg = @nd_receiver[expr_id]
    if recv_eg < 0
      return ""
    end
    rt_eg = infer_type(recv_eg)
    if rt_eg == "string" || rt_eg == "mutable_str"
      return "int"
    end
    ""
  end

 # Recognize `return X if h.nil?` shape; return the LV name or
 # "". Caller threads the stmt list separately into
 # scan_back_writer_narrow_for to derive the narrow type. (Two
 # separate calls instead of one [var, type] return because
 # spinel-self's inference widens an array-return into poly,
 # cascading into push_type_narrow's param signature.)
 # Issue #550.
  def parse_nil_guard_var(nid)
    if nid < 0
      return ""
    end
    if @nd_type[nid] != "IfNode"
      return ""
    end
    body_i = @nd_body[nid]
    if body_definitely_exits?(body_i) == 0
      return ""
    end
    sub_i = @nd_subsequent[nid]
    else_i = @nd_else_clause[nid]
    if sub_i >= 0 || else_i >= 0
      return ""
    end
    parse_nil_predicate(@nd_predicate[nid])
  end

  def scan_back_writer_narrow_for(stmts_list, before_idx, varname)
    j = before_idx - 1
    while j >= 0
      stmt = stmts_list[j]
      if @nd_type[stmt] == "LocalVariableWriteNode" && @nd_name[stmt] == varname
        return infer_nil_guard_narrow_type(@nd_expression[stmt])
      end
      j = j - 1
    end
    ""
  end

end
