
# RUN apt-get install -y vim

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

ADD Make.user /julia
WORKDIR /julia

RUN ${L32} git checkout ${REVISION}
RUN ${L32} make -j4 ${ARCH_FLAGS} 
RUN ${L32} make -j4 ${ARCH_FLAGS} prefix=/tmp/usr install
RUN ${L32} ./contrib/fixup-libgfortran.sh /tmp/usr/lib/julia/
CMD cd /tmp && tar chvzf /work/julia32.tar.gz usr