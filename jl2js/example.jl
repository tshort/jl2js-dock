#
# These work
#

@Base.ccallable Float64 myabs(x::Float64) = abs(x)
@Base.ccallable Float64 myfun1(x::Float64) = sum((x, x, 1.0))

#
# These are quirky
#

@Base.ccallable Float64 myfun2(x::Float64) = sum(Float64[x, x, 1.0]) # Need to replace _jlplt_alloc_array_1d_XX with _alloc_array_1d in JS
@Base.ccallable Float64 myfun3(x::Float64) = myfun2(x)
@Base.ccallable Float64 myfun4(x::Float64) = sum((abs(x), asin(x), tan(x))) # Need to replace _jlplt_asin_XX and _jlplt_tan_XX with Math_asin and Math_tan in JS    

#
# These are broken
#

@Base.ccallable Void    hi() = (println("hello world");nothing)
@Base.ccallable Cstring hi1() = Vector{UInt8}("hello world")  # If _jlplt_string_to_array_XX is replace by _jl_string_to_array, returns something, but it's not a string


@Base.ccallable Void function testio(x::Float64)
    open("test.dat", "w") do io
        println(io, 2x)
    end
    # y = open("test.dat") do io
    #     readlines(io)
    # end
    nothing
end

#
# Attempt to print out the internal llvm function names.
# Ordering changes may mess these up.
#

function showname(fun, types)
    io = PipeBuffer()
    code_llvm(io, fun, types)
    println(readlines(io)[2])
    nothing
end
showname(fun) = showname(fun, (Float64,))

showname.((myabs, myfun1, myfun2, myfun3, myfun4))
showname(hi, ())
showname(hi1, ())
showname(testio)
