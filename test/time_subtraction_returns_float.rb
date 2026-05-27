# Issue #901: Time - Time returns Float (elapsed seconds). LV
# slot inferred as sp_Time on pass 1, refined to float on pass 2
# once the rhs LV was declared as time. merge_refined_local_type
# now accepts time -> float refinement.
start = Time.now
diff = Time.now - start
puts diff >= 0
puts diff.class
