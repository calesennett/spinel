# Bundled tests:
#   - attr_writer_poly_box
#   - attr_writer_poly_no_double_eval
#   - attr_writer_returns_rhs
#   - auto_unbox_keeps_int_slot
#   - auto_unbox_poly_to_int_local

# === attr_writer_poly_box ===
# `obj.attr = v` codegen emitted `slot = arg0` regardless of slot
# type. When the slot is poly (sp_RbVal — widened by heterogeneous
# writes) and the rhs is typed (int / string / obj_X / ...), C
# rejects the assignment as a struct-from-scalar/pointer mismatch.

class T_attr_writer_poly_box_Bag
  attr_accessor :item
  def initialize
    @item = "tag"     # string first…
    @item = 5         # …then int — slot widens to poly
  end
end

class T_attr_writer_poly_box_Caller
  def stuff(bag)
    bag.item = 99     # statement-form attr-writer on poly slot
    bag.item
  end
end

b = T_attr_writer_poly_box_Bag.new
puts T_attr_writer_poly_box_Caller.new.stuff(b)   # 99
puts (b.item = 7)          # 7  (expression-form; `=` returns rhs)
puts b.item                # 7

# === attr_writer_poly_no_double_eval ===
# Expression-form `obj.attr = rhs` on a poly slot used to lower to
# the comma expression `(slot = box(rhs), rhs)`, which evaluates rhs
# textually twice in C. If rhs has side effects (a method call, a
# string allocation, etc.) they run twice. Verify rhs runs exactly
# once by spilling to a typed temp via statement expression.

class T_attr_writer_poly_no_double_eval_Counter
  def initialize
    @n = 0
  end
  def step
    @n = @n + 1
    @n
  end
end

class T_attr_writer_poly_no_double_eval_Bag
  attr_accessor :item
  def initialize
    @item = "tag"   # widen slot to poly via heterogeneous writes
    @item = 5
  end
end

c = T_attr_writer_poly_no_double_eval_Counter.new
b = T_attr_writer_poly_no_double_eval_Bag.new
puts (b.item = c.step)   # 1  (chain value is rhs; step runs once)
puts (b.item = c.step)   # 2
puts (b.item = c.step)   # 3

# === attr_writer_returns_rhs ===
# `obj.attr = v` as an expression should evaluate to `v`, the rhs,
# matching Ruby semantics. Codegen used to emit `(rc->iv = v, 0)` —
# the trailing `, 0` made the C expression value `0`, so chained
# writes `local = obj.attr = v` saw 0 instead of v.

class T_attr_writer_returns_rhs_Box
  attr_accessor :n
  def initialize
    @n = 0
  end
end

b = T_attr_writer_returns_rhs_Box.new
local = (b.n = 42)
puts local      # 42
puts b.n        # 42

# Chained variant — both lvalues should land on the same rhs value.
b1 = T_attr_writer_returns_rhs_Box.new
b2 = T_attr_writer_returns_rhs_Box.new
b1.n = b2.n = 7
puts b1.n       # 7
puts b2.n       # 7

# === auto_unbox_keeps_int_slot ===
# Followup to PR #347: when a poly RHS is auto-unboxed into an
# int local slot, the slot's tracked type must stay int so a
# *subsequent* poly RHS write also unboxes. Without this, the
# first auto-unbox-write widened the slot's tracked type to
# poly; the second poly write then emitted `lv = <sp_RbVal>;`
# (no unbox) into the still-int T_auto_unbox_keeps_int_slot_C declaration, failing the T_auto_unbox_keeps_int_slot_C
# compile (`incompatible types when assigning to type 'mrb_int'
# from type 'sp_RbVal'`).
#
# Reproduces optcarrot's chained `pixel0 = sprite[N]` writes:
# the function-level slot stays mrb_int (set by an earlier
# int_array read), but later sprite[N] writes are poly.

class T_auto_unbox_keeps_int_slot_C
  def make_int_arr; @arr = [10, 20, 30]; end
  def make_poly_arr
    @arr = [nil] * 3
    @arr[0] = 100
    @arr[1] = 200
    @arr[2] = 300
  end
  def at(i); @arr[i]; end
end

c = T_auto_unbox_keeps_int_slot_C.new

# Two consecutive poly RHS writes into the same int slot. Both
# must auto-unbox; without the fix, the second one fails T_auto_unbox_keeps_int_slot_C compile.
c.make_int_arr
val = c.at(0)            # int RHS, val slot established as int
puts val

c.make_poly_arr
val = c.at(0)            # 1st poly RHS — already worked in PR #347
puts val

val = c.at(2)            # 2nd poly RHS — must also unbox; failed pre-fix
puts val

# === auto_unbox_poly_to_int_local ===
# Auto-unbox poly RHS into a primitive int local slot. Common
# case: `lv = arr[i]` where arr's element dispatch returns poly
# (heterogeneous element types) but the local was already inferred
# as int from a prior write. Spinel previously emitted
# `lv = <sp_RbVal>;` and the T_auto_unbox_poly_to_int_local_C compile failed (`incompatible
# types when assigning to type 'mrb_int' from type 'sp_RbVal'`).
#
# Repro: an ivar widened to poly via two distinct array shapes
# (an int_array and a poly_array). The local `pixel` was first
# set from an int_array (so its declared T_auto_unbox_poly_to_int_local_C type is mrb_int),
# then a second write reassigns from the poly slot. Without
# auto-unbox, the second assignment fails.

class T_auto_unbox_poly_to_int_local_C
  def make_int_arr
    @arr = [10, 20, 30]
  end
  def make_poly_arr
    @arr = [nil] * 3
    @arr[0] = 99
    @arr[1] = "x"
    @arr[2] = :y
  end
  def first_int
    @arr[0]
  end
end

c = T_auto_unbox_poly_to_int_local_C.new
c.make_int_arr
pixel = c.first_int   # int from int_array
puts pixel.to_s

c.make_poly_arr
pixel = c.first_int   # poly from poly_array, must auto-unbox
puts pixel.to_s

