# Float#round(0) — CRuby returns Integer (parity with no-arg form).
# Other non-zero precisions stay Float. Same for ceil / floor / truncate.
puts 3.5.round(0).inspect
puts 3.5.round.inspect
puts 3.5.round(1).inspect
puts 3.5.round(2).inspect

puts 3.7.ceil(0).inspect
puts 3.7.ceil.inspect
puts 3.7.ceil(1).inspect

puts 3.7.floor(0).inspect
puts 3.7.floor.inspect

puts 3.7.truncate(0).inspect
puts 3.7.truncate.inspect
