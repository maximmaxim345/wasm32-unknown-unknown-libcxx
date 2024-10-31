/* clang -target wasm32-unknown-unknown -x c /dev/null -dM -E */

typedef __INTPTR_TYPE__ __intptr_t;
typedef __UINTPTR_TYPE__ __uintptr_t;
typedef __PTRDIFF_TYPE__ __ptrdiff_t;
// typedef __WCHAR_TYPE__ __wchar_t;
typedef __WCHAR_TYPE__ __wctrans_t; // new
typedef __WCHAR_TYPE__ __wctype_t;  // new

#ifndef __wchar_t
// typedef __WCHAR_TYPE__ __wchar_t;
typedef int __wchar_t;
#endif
// typedef unsigned long int __wctype_t;
// typedef const __INT32_TYPE__ *__wctrans_t;

typedef __WINT_TYPE__ __wint_t;
typedef __INT8_TYPE__ __int8_t;
typedef __UINT8_TYPE__ __uint8_t;
typedef __INT16_TYPE__ __int16_t;
typedef __UINT16_TYPE__ __uint16_t;
typedef __INT32_TYPE__ __int32_t;
typedef __UINT32_TYPE__ __uint32_t;
typedef __INT64_TYPE__ __int64_t;
typedef __UINT64_TYPE__ __uint64_t;

// new:
typedef __INT8_TYPE__ __int_fast8_t;
typedef __INT16_TYPE__ __int_fast16_t;
typedef __INT32_TYPE__ __int_fast32_t;
typedef __INT64_TYPE__ __int_fast64_t;
typedef __UINT8_TYPE__ __uint_fast8_t;
typedef __UINT16_TYPE__ __uint_fast16_t;
typedef __UINT32_TYPE__ __uint_fast32_t;
typedef __UINT64_TYPE__ __uint_fast64_t;
typedef __INT64_TYPE__ __intmax_t;
typedef __UINT64_TYPE__ __uintmax_t;

// new:
typedef __INT8_TYPE__ __int_least8_t;
typedef __INT16_TYPE__ __int_least16_t;
typedef __INT32_TYPE__ __int_least32_t;
typedef __INT64_TYPE__ __int_least64_t;
typedef __UINT8_TYPE__ __uint_least8_t;
typedef __UINT16_TYPE__ __uint_least16_t;
typedef __UINT32_TYPE__ __uint_least32_t;
typedef __UINT64_TYPE__ __uint_least64_t;

/* Register size */
typedef long __register_t;

/* VM system types */
typedef unsigned long __vaddr_t;
typedef unsigned long __paddr_t;
typedef unsigned long __vsize_t;
typedef unsigned long __psize_t;

typedef unsigned long __size_t;
typedef long __ssize_t;

typedef float __float_t;
typedef double __double_t;

typedef __builtin_va_list __va_list;
