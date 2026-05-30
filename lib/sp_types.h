/* sp_types.h -- core value-type definitions split out of sp_runtime.h.
 *
 * Holds the primitive typedefs, the small leaf value structs, the GC
 * header, and the typed array / non-poly hash structs. Both
 * sp_runtime.h (which includes this near the top) and libspinel_rt.a
 * sources can include it to see the layouts without pulling in the
 * header's static/inline function bodies. Pure type/macro definitions
 * only -- no function definitions, no global state.
 *
 * Reorganisation step toward slimming sp_runtime.h; sp_RbVal, the poly
 * containers, and the conditional Proc/Fiber/etc. types still live in
 * sp_runtime.h pending a later pass.
 */
#ifndef SP_TYPES_H
#define SP_TYPES_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

/* mrb_int follows pointer width (decided at compile time via intptr_t):
   int64_t on 64-bit hosts -- PCs, no behavior change -- and int32_t on
   32-bit embedded targets, where it gives native-word arithmetic, half
   the memory for every integer/array/hash slot, and a pointer-width
   sp_RbVal union. The two paths differ only in that the 32-bit build
   overflows / narrows foreign 64-bit values (e.g. Time#to_i) at
   INT32 limits; see the overflow-mode handling. */
#if INTPTR_MAX == INT64_MAX
#elif INTPTR_MAX == INT32_MAX
#else
#error "spinel: unsupported intptr_t width (need 32- or 64-bit)"
#endif
typedef intptr_t mrb_int;
typedef double mrb_float;
typedef bool mrb_bool;

/* Sentinel value reserved by the int? (scalar-nullable int) type. An
   int? slot is bit-compatible with mrb_int; SP_INT_NIL marks the
   "nil" inhabitant. The pattern is INTPTR_MIN -- INT64_MIN on 64-bit
   (unchanged), INT32_MIN on 32-bit. On 64-bit this value would auto-
   promote to Bignum in CRuby so the reservation is safe; on 32-bit
   INT32_MIN is a representable Integer, so the sentinel can collide
   with a genuine -2147483648 (an accepted 32-bit-build limitation).
   `sp_int_is_nil(v)` is the canonical predicate; treat any int? value
   produced by runtime helpers as opaque outside this macro. */
#define SP_INT_NIL ((mrb_int)INTPTR_MIN)
#define sp_int_is_nil(v) ((v) == SP_INT_NIL)

/* sp_sym is defined per-program in emit_sym_runtime, but poly helpers
   below need to reference it by forward declaration. */
typedef mrb_int sp_sym;

#ifndef TRUE
#define TRUE true
#endif
#ifndef FALSE
#define FALSE false
#endif

/* ---- Leaf value structs ---- */
typedef struct{mrb_int first;mrb_int last;}sp_Range;
typedef struct{mrb_int cls_id;}sp_Class;
typedef struct{mrb_float re;mrb_float im;}sp_Complex;
typedef struct{mrb_int num;mrb_int den;}sp_Rational;
typedef struct{const char *name;}sp_Encoding;

/* ---- GC headers ---- */
typedef struct sp_gc_hdr { struct sp_gc_hdr *next; void (*finalize)(void *); void (*scan)(void *); size_t size; unsigned marked : 1; unsigned frozen : 1; void (*recycle)(struct sp_gc_hdr *); } sp_gc_hdr;
typedef struct sp_str_hdr { struct sp_str_hdr *next; size_t size; size_t len; } sp_str_hdr;

/* ---- Typed arrays ---- */
#define SP_STRARR_INLINE 4
typedef struct{mrb_int*data;mrb_int start;mrb_int len;mrb_int cap;mrb_int frozen;}sp_IntArray;
typedef struct{mrb_float*data;mrb_int len;mrb_int cap;mrb_int frozen;}sp_FloatArray;
typedef struct{void**data;mrb_int len;mrb_int cap;void(*scan_elem)(void*);mrb_int frozen;}sp_PtrArray;
typedef struct{const char**data;mrb_int len;mrb_int cap;mrb_int frozen;const char*inline_data[SP_STRARR_INLINE];}sp_StrArray;

/* ---- Non-poly typed hashes ---- */
typedef struct{const char**keys;mrb_int*vals;const char**order;mrb_int len;mrb_int cap;mrb_int mask;mrb_int default_v;}sp_StrIntHash;
typedef struct{const char**keys;const char**vals;const char**order;mrb_int len;mrb_int cap;mrb_int mask;const char*default_v;}sp_StrStrHash;
typedef struct{mrb_int*keys;const char**vals;mrb_int*order;mrb_bool*used;mrb_int len;mrb_int cap;mrb_int mask;const char*default_v;}sp_IntStrHash;
typedef struct{mrb_int*keys;mrb_int*vals;mrb_int*order;mrb_bool*used;mrb_int len;mrb_int cap;mrb_int mask;mrb_int default_v;}sp_IntIntHash;

#endif
