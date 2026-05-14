class HitState
  def initialize
    @material_index = nil
  end

  def hit!(idx)
    @material_index = idx
  end

  def label
    @material_index.nil? ? "miss" : "hit"
  end
end

state = HitState.new
puts state.label
state.hit!(0)
puts state.label

class ResetState
  def initialize
    @material_index = 0
  end

  def clear!
    @material_index = nil
  end

  def label
    @material_index.nil? ? "miss" : "hit"
  end
end

reset = ResetState.new
puts reset.label
reset.clear!
puts reset.label

class ParamResetState
  def initialize
    @material_index = 0
  end

  def set(idx)
    @material_index = idx
  end

  def label
    @material_index.nil? ? "miss" : "hit"
  end
end

param_reset = ParamResetState.new
puts param_reset.label
param_reset.set(nil)
puts param_reset.label
