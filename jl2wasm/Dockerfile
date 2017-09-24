
FROM multiarch/debian-debootstrap:i386-stretch

# Set things like MARCH and JULIA_CPU_TYPES
ARG ARCH_FLAGS="JULIA_CPU_TARGET=pentium4 MARCH=pentium4"
ARG L32="linux32"
ARG REVISION="v0.6.0"

# These are the build dependencies for Julia
ARG BUILD_DEPS="build-essential gfortran m4 python python-dev cmake curl git patchelf"
RUN ${L32} apt update && \
    ${L32} apt install -y ${BUILD_DEPS} && \
    ${L32} git clone https://github.com/JuliaLang/julia.git /julia

# Julia
ADD Make.user /julia
# The following adds LLVM_CMAKE := -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly 
ADD llvm.mk /julia/deps

WORKDIR /julia
RUN ${L32} make -j4 -C deps compile-llvm
RUN ${L32} make -j4 -C deps getall
RUN ${L32} make -j4 -C deps compile
COPY tls.h /julia/src/tls.h
RUN ${L32} make -j4  ${ARCH_FLAGS} 

# Julia setup for compiling to LLVM bitcode
WORKDIR /julia/base
RUN /julia/usr/bin/julia --output-ji inference.ji coreimg.jl
RUN /julia/usr/bin/julia --output-ji sys.ji --sysimage inference.ji --startup-file=no sysimg.jl

# Node
WORKDIR /
RUN apt-get install -y nodejs
RUN ln -s nodejs /usr/bin/node

# Binaryen
RUN ${L32} git clone https://github.com/WebAssembly/binaryen.git 
WORKDIR /binaryen
RUN ${L32} cmake . && make -j4

# Emscripten
RUN ${L32} git clone https://github.com/kripken/emscripten.git /emscripten
WORKDIR /emscripten
RUN ${L32} git checkout -b incoming
RUN ${L32} ./emcc --help
COPY .emscripten /root/.emscripten
RUN cp /julia/usr/bin/clang /julia/usr/tools

# Run a test to store stuff in cache
# RUN emcc --version \
#  && mkdir -p /tmp/emscripten_test && cd /tmp/emscripten_test \
#  && printf '#include <iostream>\nint main(){std::cout<<"HELLO"<<std::endl;return 0;}' > test.cpp \
#  && em++ -O2 test.cpp -o test.js && node test.js \
#  && em++ test.cpp -o test.js && node test.js \
#  && em++ -O2 test.cpp -o test.js -s BINARYEN=1 \
#  && em++ test.cpp -o test.js -s BINARYEN=1 \
#  && cd / \
# && rm -rf /tmp/*