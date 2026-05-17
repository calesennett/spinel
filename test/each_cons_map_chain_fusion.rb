# Phase A of Enumerator-chain strategy (#566): `arr.each_cons(n)`
# called without a block returns an Enumerator in CRuby. When the
# very next call is a terminal like `.map { |pair| ... }`, the
# Enumerator is consumed immediately and the chain has the same
# observable result as eagerly materialising each window. Spinel
# fuses the source + terminal into a single C loop, so no
# Enumerator object is allocated and no intermediate
# array-of-arrays is built (one window allocation per iteration,
# bounded by .map's accumulator).
#
# The terminal block may take the window as a single param
# (`|pair|`, typed as the receiver's array shape) or destructure
# it (`|(a, b)|`, binds individual locals -- the per-iteration
# window allocation is skipped on this path).

# T1: plain |pair| form, scalar block result
p [1, 2, 3, 4].each_cons(2).map { |pair| pair[0] + pair[1] }

# T2: destructure |(a, b)|, scalar block result
p [10, 20, 30, 40].each_cons(2).map { |(a, b)| b - a }

# T3: |pair| with array-returning block -> result is int_array_ptr_array
p [1, 2, 3].each_cons(2).map { |pair| [pair[0], pair[1]] }

# T4: empty / short receiver (length < n) -> empty result
p [1].each_cons(2).map { |pair| pair[0] }
