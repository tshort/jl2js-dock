# Compile **libjulia** with emscripten

Generates a `libjulia.bc` compiled by emscripten.

Use:

```
docker build -t libjulia .
docker run -v $(pwd):/work libjulia
```

To access the container interactively, use:

```
docker run -v $(pwd):/julia -it libjulia /bin/bash
```
