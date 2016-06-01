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

function Base.show(io::IO, ds::DefaultState)
    n, d, t = ds.n, round(ds.change, 4), round(ds.elapsed, 4)
    m = "DefaultState: $n iterations, $d current change $t seconds elapsed"
    print(io, m)
end

num_iter(ds::DefaultState) = ds.n
Base.norm(istate::DefaultState) = abs(istate.change)

function display_iter(io::IO,  ds::DefaultState, prefix="")
    if ds.n == 0  # print banner
        @printf "%s%-13s%-15s%-17s\n" prefix "Iteration" "Distance" "Elapsed (seconds)"
        println(io, prefix, repeat("-", 45))
    else
        @printf "%s%-13i%-15.5e%-18.5f\n" prefix ds.n ds.change ds.elapsed
    end
end

update_prev!{T<:AbstractArray}(istate::DefaultState{T}, v::T) =
    copy!(istate.prev, v)

function update_prev!{T}(istate::DefaultState{T}, v::T)
    istate.prev = copy(v)
end

function update!{T}(istate::DefaultState{T}, v::T; by::Function=default_by)
    istate.n += 1
    istate.change = by(istate.prev, v)
    update_prev!(istate, v)

    new_time = time()
    istate.elapsed += new_time - istate.prev_time
    istate.prev_time = new_time
    nothing
end
