# Defines the __cpp_exception tag that clang -fwasm-exceptions emits as an
# undefined `env` import in every EH object. wasm-ld never synthesizes it on
# bare wasm32-unknown-unknown. This module-local definition gets merged with
# those imports at link time, so the module links and instantiates with no
# `env` import and no post-link rewrite.
	.tagtype	__cpp_exception i32
	.globl	__cpp_exception
__cpp_exception:
