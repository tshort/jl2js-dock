# Very Experimental and Quite Broken!


# Conversion of Julia to WebAssembly

Experiments with the experimental LLVM backend for WebAssembly. This is currently broken. Compilation fails because it runs into problems with functions with `ccall` (can't avoid those).

This uses the git version of Julia with threading disabled. It installs LLVM 5.0.0 with the WebAssembly backend.


