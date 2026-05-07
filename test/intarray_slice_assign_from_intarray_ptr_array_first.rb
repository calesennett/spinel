# `arr[start, len] = src` slice-assign where `src` came from
# `<X>_ptr_array.first` (or `.last`). Spinel's compile_bracket_assign
# already had a same-prefix slice-assign path for `int_array[i, n] =
# int_array`, but `infer_type` for `.first` / `.last` fell through
# to "int" on a `_ptr_array` receiver, so the slice-assign branch's
# `infer_type(arg_ids[2]) == "int_array"` test missed and the call
# silently lowered to `arr[start] = len` (using arg_ids[1] as the
# value, dropping arg_ids[2] entirely).

class C
  def initialize
    buf = (0...32).to_a
    @banks = (0...2).map { buf.slice!(0, 8) }
    @ref = [0] * 24
    @ref[5, 8] = @banks.first
    @ref[15, 8] = @banks.last
  end

  def show
    @ref.each { |x| print x, " " }
    puts
  end
end

C.new.show
