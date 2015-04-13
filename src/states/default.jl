"""
DefaultState: track iterations and elapsed time

@author : Spencer Lyon <spencer.lyon@stern.nyu.edu>
@date : 2015-04-13 11:29:12

"""

type DefaultState{T} <: IterationState{T}
    n::Int              # number of iterations
    change::Float64     # change between previous and current state
    elapsed::Float64    # total time elapsed
    prev::T             # previous value
    prev_time::Float64  # previous absolute time
end

DefaultState{T}(v::T) = DefaultState(0, Inf, 0.0, v, time())

function Base.writemime(io::IO, ::MIME"text/plain", ds::DefaultState)
    n, d, t = ds.n, round(ds.change, 4), round(ds.elapsed, 4)
    m = "DefaultState: $n iterations, $d current change $t seconds elapsed"
    print(io, m)
end

function display_iter(io::IO,  ds::DefaultState)
    if ds.n == 0  # print banner
        fe = FormatExpr("{1:<13}{2:<15}{3:<17}")
        printfmtln(io, fe, "Iteration", "Distance", "Elapsed (seconds)")
        println(io, repeat("-", sum([x.spec.width for x in fe.entries])))
    else
        fe = FormatExpr("{1:<13}{2:<15.5e}{3:<18.5f}")
        printfmtln(io, fe, ds.n, ds.change, ds.elapsed)
    end
end

# inefficient version of copy that should work for arbitrary types
# (like tuples of arrays)
function Base.copy!{T}(a::T, b::T)
    copy(b)
end

function update!{T}(istate::DefaultState{T}, v::T; by::Function=default_by)
    istate.n += 1
    istate.change = by(istate.prev, v)
    istate.prev = copy(v)

    new_time = time()
    istate.elapsed += new_time - istate.prev_time
    istate.prev_time = new_time
    nothing
end
