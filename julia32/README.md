# Compiles a 32-bit version of Julia

Needed because we want to disable threading. Threading complicates the compiled bitcode.

Based on:

https://github.com/staticfloat/julia-docker/blob/9488b7029828895187ea1939d397e9ce40f107fa/julia/build/v0.6.0-rc2/Dockerfile.x86

Use:

```
docker build -t j32 .
docker run -v $(pwd):/work j32
```
