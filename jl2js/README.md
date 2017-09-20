# Very Experimental and Quite Broken!

Only the simplest compiled code works.

# Conversion of Julia to JavaScript and/or WebAssembly

Build the docker container:

```
docker build -t jl2js .
```

Convert a Julia file to JavaScript:

```
./jl2js.sh example "['_myabs','_myfun']"
```

The first argument, `example`, is the file to be compiled to JavaScript with no extension. The second argument is a list of the functions you want available. 

Right now, you have to also include the internal functions for each of these as follows:

```
./jl2js.sh example "['_myabs','_julia_myabs_2473','_myfun','_julia_myfun_2533']"
```

