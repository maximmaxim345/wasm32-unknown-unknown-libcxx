// Minimal C11 <threads.h> stub for wasm32-unknown-unknown (single-threaded).
// Only provides the `thread_local` macro, which is what libunwind's
// Unwind-wasm.c actually needs. Real thread support is intentionally absent.
#ifndef _WASM32_UNKNOWN_UNKNOWN_LIBCXX_THREADS_H
#define _WASM32_UNKNOWN_UNKNOWN_LIBCXX_THREADS_H

#ifndef thread_local
#define thread_local _Thread_local
#endif

#endif
