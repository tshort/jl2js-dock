
const mintrials = 5
const mintime = 2000.0
print_output = isempty(ARGS)
codespeed = length(ARGS) > 0 && ARGS[1] == "codespeed"

if codespeed
    using JSON
    using HTTPClient.HTTPC

    # Ensure that we've got the environment variables we want:
    if !haskey(ENV, "JULIA_FLAVOR")
        error( "You must provide the JULIA_FLAVOR environment variable identifying this julia build!" )
    end

    # Setup codespeed data dict for submissions to codespeed's JSON endpoint.  These parameters
    # are constant across all benchmarks, so we'll just let them sit here for now
    csdata = Dict()
    csdata["commitid"] = Base.GIT_VERSION_INFO.commit
    csdata["project"] = "Julia"
    csdata["branch"] = Base.GIT_VERSION_INFO.branch
    csdata["executable"] = ENV["JULIA_FLAVOR"]
    csdata["environment"] = chomp(readstring(`hostname`))
    csdata["result_date"] = join( split(Base.GIT_VERSION_INFO.date_string)[1:2], " " )    #Cut the timezone out
end

# Takes in the raw array of values in vals, along with the benchmark name, description, unit and whether less is better
function submit_to_codespeed(vals,name,desc,unit,test_group,lessisbetter=true)
    # Points to the server
    codespeed_host = "julia-codespeed.csail.mit.edu"

    csdata["benchmark"] = name
    csdata["description"] = desc
    csdata["result_value"] = mean(vals)
    csdata["std_dev"] = std(vals)
    csdata["min"] = minimum(vals)
    csdata["max"] = maximum(vals)
    csdata["units"] = unit
    csdata["units_title"] = test_group
    csdata["lessisbetter"] = lessisbetter

    println( "$name: $(mean(vals))" )
    ret = post( "http://$codespeed_host/result/add/json/", Dict("json" => json([csdata])) )
    println( json([csdata]) )
    if ret.http_code != 200 && ret.http_code != 202
        error("Error submitting $name [HTTP code $(ret.http_code)], dumping headers and text: $(ret.headers)\n$(String(ret.body))\n\n")
        return false
    end
    return true
end

macro output_timings(t,name,desc,group)
    t = esc(t)
    name = esc(name)
    desc = esc(desc)
    group = esc(group)
    quote
        # If we weren't given anything for the test group, infer off of file path!
        test_group = length($group) == 0 ? basename(dirname(Base.source_path())) : $group[1]
        if codespeed
            submit_to_codespeed( $t, $name, $desc, "seconds", test_group )
        elseif print_output
            @printf "julia,%s,%f,%f,%f,%f\n" $name minimum($t) maximum($t) mean($t) std($t)
        end
        gc()
    end
end

macro timeit(ex,name,desc,group...)
    quote
        t = Float64[]
        tot = 0.0
        i = 0
        while i < mintrials || tot < mintime
            e = 1000*(@elapsed $(esc(ex)))
            tot += e
            if i > 0
                # warm up on first iteration
                push!(t, e)
            end
            i += 1
        end
        @output_timings t $(esc(name)) $(esc(desc)) $(esc(group))
    end
end

macro timeit_init(ex,init,name,desc,group...)
    quote
        t = zeros(mintrials)
        for i=0:mintrials
            $(esc(init))
            e = 1000*(@elapsed $(esc(ex)))
            if i > 0
                # warm up on first iteration
                t[i] = e
            end
        end
        @output_timings t $(esc(name)) $(esc(desc)) $(esc(group))
    end
end

function maxrss(name)
    # FIXME: call uv_getrusage instead here
    @static if is_linux()
        rus = Array{Int64}(div(144,8))
        fill!(rus, 0x0)
        res = ccall(:getrusage, Int32, (Int32, Ptr{Void}), 0, rus)
        if res == 0
            mx = rus[5]/1024
            @printf "julia,%s.mem,%f,%f,%f,%f\n" name mx mx mx 0
        end
    end
end


# seed rng for more consistent timings
srand(1776)

using Base.Test

# include("../perfutil.jl")

## recursive fib ##

@Base.ccallable Int fib(n) = n < 2 ? n : fib(n-1) + fib(n-2)

@test fib(20) == 6765
# @timeit fib(20) "fib" "Recursive fibonacci"

## parse integer ##

@Base.ccallable String function parseintperf(t)
    local n, m
    for i=1:t
        n = rand(UInt32)
        s = hex(n)
        m = UInt32(parse(Int64,s,16))
    end
    @test m == n
    return n
end

# @timeit parseintperf(1000) "parse_int" "Integer parsing"

## array constructors ##

@test all(ones(200,200) .== 1)
# @timeit ones(200,200) "ones" "description"

## matmul and transpose ##

A = ones(200,200)
@test all(A*A' .== 200)
# @timeit A*A' "AtA" "description"

## mandelbrot set: complex arithmetic and comprehensions ##

function mandel(z)
    c = z
    maxiter = 80
    for n = 1:maxiter
        if abs(z) > 2
            return n-1
        end
        z = z^2 + c
    end
    return maxiter
end

@Base.ccallable Array{Int,1} mandelperf() = [ mandel(complex(r,i)) for i=-1.:.1:1., r=-2.0:.1:0.5 ]
@test sum(mandelperf()) == 14791
# @timeit mandelperf() "mandel" "Calculation of mandelbrot set"

## numeric vector sort ##

function qsort!(a,lo,hi)
    i, j = lo, hi
    while i < hi
        pivot = a[(lo+hi)>>>1]
        while i <= j
            while a[i] < pivot; i += 1; end
            while a[j] > pivot; j -= 1; end
            if i <= j
                a[i], a[j] = a[j], a[i]
                i, j = i+1, j-1
            end
        end
        if lo < j; qsort!(a,lo,j); end
        lo, j = i, hi
    end
    return a
end

@Base.ccallable Array{Float64,1} sortperf(n) = qsort!(rand(n), 1, n)
@test issorted(sortperf(5000))
# @timeit sortperf(5000) "quicksort" "Sorting of random numbers using quicksort"

## slow pi series ##

@Base.ccallable Float64 function pisum()
    sum = 0.0
    for j = 1:500
        sum = 0.0
        for k = 1:10000
            sum += 1.0/(k*k)
        end
    end
    sum
end

@test abs(pisum()-1.644834071848065) < 1e-12
# @timeit pisum() "pi_sum" "Summation of a power series"

## slow pi series, vectorized ##

@Base.ccallable Float64 function pisumvec()
    s = 0.0
    a = [1:10000]
    for j = 1:500
        s = sum(1./(a.^2))
    end
    s
end

#@test abs(pisumvec()-1.644834071848065) < 1e-12
#@timeit pisumvec() "pi_sum_vec"

## random matrix statistics ##

@Base.ccallable Tuple{Float64,Float64} function randmatstat(t)
    n = 5
    v = zeros(t)
    w = zeros(t)
    for i=1:t
        a = randn(n,n)
        b = randn(n,n)
        c = randn(n,n)
        d = randn(n,n)
        P = [a b c d]
        Q = [a b; c d]
        v[i] = trace((P.'*P)^4)
        w[i] = trace((Q.'*Q)^4)
    end
    return (std(v)/mean(v), std(w)/mean(w))
end

(s1, s2) = randmatstat(1000)
@test 0.5 < s1 < 1.0 && 0.5 < s2 < 1.0
# @timeit randmatstat(1000) "rand_mat_stat" "Statistics on a random matrix"

## largish random number gen & matmul ##

# @timeit rand(1000,1000)*rand(1000,1000) "rand_mat_mul" "Multiplication of random matrices"

## printfd ##

if is_unix()
    function printfd(n)
        open("/dev/null", "w") do io
            for i = 1:n
                @printf(io, "%d %d\n", i, i + 1)
            end
        end
    end

    printfd(1)
    # @timeit printfd(100000) "printfd" "Printing to a file descriptor"
end

maxrss("micro")