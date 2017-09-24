#!/bin/sh
echo $1
echo $2
/julia/usr/bin/julia --output-bc $1.bc --sysimage /julia/base/sys.ji --startup-file=no $1.jl
# llvm-nm $1.bc | grep 
EMCC_DEBUG=2 EMCC_WASM_BACKEND=1  /emscripten/emcc -v $1.bc -o /work/$1.js -s EXPORTED_FUNCTIONS="$2" -s TOTAL_MEMORY=134217728 -s WASM=1
grep jlplt $1.js
