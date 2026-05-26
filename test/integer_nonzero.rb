# Issue #874: Integer#nonzero? returns nil when receiver is 0,
# self otherwise. Surfaces as int? (nullable int).
puts 0.nonzero?.inspect
puts 42.nonzero?.inspect
puts(-5.nonzero? || "default")
