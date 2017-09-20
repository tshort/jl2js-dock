#!/bin/sh
echo $1
echo $2
julia --output-bc $1.bc --sysimage /usr/share/julia/base/sys.ji --startup-file=no $1.jl
emcc -v $1.bc libjulia.bc -o /work/$1.js -s EXPORTED_FUNCTIONS="$2"
