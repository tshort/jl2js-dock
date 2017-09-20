
FROM ubuntu:16.04

# Install packages needed for running 32-bit Julia and using emscripten
RUN apt-get update \
 && apt-get install -y build-essential gcc g++ cmake curl gfortran git m4 python xz-utils bzip2 nodejs \
 && ln -s nodejs /usr/bin/node

# Get the most recent emsdk
RUN curl -sSL https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz -o emsdk-portable.tar.gz
RUN tar -xzf  emsdk-portable.tar.gz 

# Set up emscripten -- use 1.37.6 to match LLVM versions with Julia
RUN cd /emsdk-portable \
 && ./emsdk update \
 && ./emsdk install sdk-1.37.6-64bit \
 && ./emsdk activate sdk-1.37.6-64bit \
 && /bin/bash /emsdk-portable/emsdk_env.sh \
 && find /emsdk-portable -name "llvm-nm" -exec ln -s {} /usr/bin/llvm-nm  ";" \
 && find /emsdk-portable/emscripten/ -maxdepth 2 -executable -type f -name 'em*' -exec ln -s {} /usr/bin/ \; 
RUN emcc --version \
 && mkdir -p /tmp/emscripten_test && cd /tmp/emscripten_test \
 && printf '#include <iostream>\nint main(){std::cout<<"HELLO"<<std::endl;return 0;}' > test.cpp \
 && em++ -O2 test.cpp -o test.js && node test.js \
 && em++ test.cpp -o test.js && node test.js \
 && em++ -O2 test.cpp -o test.js -s BINARYEN=1 \
 && em++ test.cpp -o test.js -s BINARYEN=1 \
 && cd / \
 && rm -rf /tmp/*

RUN curl -sSL https://github.com/JuliaLang/julia/releases/download/v0.6.0/julia-0.6.0.tar.gz -o julia.tar.gz
RUN mkdir /julia
RUN tar -xzf  julia.tar.gz -C /julia --strip-components=1
ADD Makefile /julia/src
COPY Makefile.support /julia/src/support/Makefile
ADD usr /julia/usr

WORKDIR /julia/src/support
RUN make -j4 
WORKDIR /julia/src
RUN make -j4 

CMD cp libjulia.bc /work
