#=
Main generic API

@author : Spencer Lyon <spencer.lyon@stern.nyu.edu>
@date : 2015-04-13 11:29:12

=#

# ----------- #
# Manager API #
# ----------- #
"""
`verbose(m::IterationManager) -> Bool`

Specifies if the iteration manager should be verbose and print status updates.

Checks the `verbose` field of the manager and returns it. If the field
doesn't exist, the default is false.

"""
verbose(m::IterationManager) = isdefined(m, :verbose) ? m.verbose : false

"""
`prefix(m::IterationManager) -> String`

Defines the prefix that should be applied to all printed messages

Checks the `prefix` field of the manager and returns it. If the field
doesn't exist, the default is `""`.

"""
prefix(m::IterationManager) = isdefined(m, :print_prefix) ? m.print_prefix : ""

"""
`print_now(m::IterationManager, n::Int) -> Bool`

Specifies if the iteration manager should print on the `n`th iteration
"""
function print_now(mgr::IterationManager, n::Int)
    if verbose(mgr)
        n == 1 && return true
        isdefined(mgr, :print_skip) ? n % mgr.print_skip == 0 : true
    else
        false
    end
end

# fallback in case x is not an Int
print_now(mgr::IterationManager, x::Any) = verbose(mgr)

# --------- #
# State API #
# --------- #

# default methods for the `by` argument of `update!`
default_by(x::T, y::T) where T <: AbstractArray = maximum(abs.(x .- y))
default_by(x::T, y::T) where T <: Number = abs(x - y)

function default_by(x::S, y::T) where S where T
    msg = "default_by not implemented for types x::$S, y::$T"
    throw(ArgumentError(msg))
end

num_iter(::IterationState) = nothing
LinearAlgebra.norm(::IterationState) = Inf

"""
`default_by(x, y)`

Gives the default comparison `by` argument to `managed_iteration` based on the
types of x and y
""" default_by

display_iter(istate::IterationState, prefix="") =
    display_iter(stdout, istate, prefix)

display_iter(io::IO, istate::T, prefix="") where T <: IterationState =
    error("`display_iter` must be implemented directly by type $T")

"""
    display_iter([io::IO=stdout], st::IterationState, [prefix::String])

A `display` method for an iteration state. Must be implemented by all concrete
subtypes of `IterationState`
"""
display_iter

# --------------------------- #
# Combining Manager and State #
# --------------------------- #

"""
    finished(mgr::IterationManager, istate::IterationState)::Bool

Given a manager and a state, determine if the iterations have finished and
should thus be terminated
"""
finished

# ------------- #
# default hooks #
# ------------- #
"""
    pre_hook(mgr::IterationManager, istate::IterationState)

Called before iterations begin.

For the default manager and state this is used to print the column headers for
verbose output printing
"""
pre_hook(mgr::IterationManager, istate::IterationState) =
    verbose(mgr) && display_iter(istate, prefix(mgr))

print_now(mgr::IterationManager, istate::IterationState) =
    print_now(mgr, num_iter(istate))

"""
    iter_hook(mgr::IterationManager, istate::IterationState)

Called after every iteration.

For the default manager and state this is used to print updates on the
iterations if `verbose(mgr) == true`.
"""
iter_hook(mgr::IterationManager, istate::IterationState) =
    print_now(mgr, istate) && display_iter(istate, prefix(mgr))

"""
    post_hook(mgr::IterationManager, istate::IterationState)

Called after iterations have finished

For the default manager this is used to print a warning if the maximum number
of iterations was exceeded.
"""
function post_hook(mgr::IterationManager, istate::IterationState)
    if !(isdefined(mgr, :maxiter))
        return nothing
    end
    if num_iter(istate) >= mgr.maxiter
        @warn "Maximum iterations exceeded. Algorithm may not have converged"
    end
    nothing
end

function managed_iteration(
        f::Base.Callable,
        mgr::IterationManager,
        istate::IterationState{T};
        by=default_by
    ) where T
    pre_hook(mgr, istate)

    while !(finished(mgr, istate))
        v = f(istate.prev)::T  # if we don't get a T back it should be an error
        update!(istate, v; by=by)
        iter_hook(mgr, istate)
    end

    post_hook(mgr, istate)
    istate
end

"""
    managed_iteration!(
        f!::Base.Callable,
        mgr::IterationManager,
        dest::T,
        istate::IterationState{T};
        by::Base.Callable=default_by
    ) where T <: AbstractArray

Given a function with signature `f!(dest::T, src::T)`, run a non-allocating
version of managed_iteration where each step calls the mutating function `f!`
that fills its first argument based on the value of the second argument. All
other behavior is equivalent to other forms of `managed_iteration`

"""
function managed_iteration!(
        f!::Base.Callable,
        mgr::IterationManager,
        dest::T,
        istate::IterationState{T};
        by::Base.Callable=default_by
    ) where T <: AbstractArray
    pre_hook(mgr, istate)

    while !(finished(mgr, istate))
        f!(dest, istate.prev)
        update!(istate, dest; by=by)
        iter_hook(mgr, istate)
    end

    post_hook(mgr, istate)
    istate
end

# kwarg version to create default manger/state
function managed_iteration(
        f::Base.Callable,
        init;
        tol::Float64=NaN,
        maxiter::Int=typemax(Int),
        by::Base.Callable=default_by,
        verbose::Bool=true,
        print_skip::Int=div(maxiter, 5)
    )
    mgr = DefaultManager(tol, maxiter, verbose, print_skip)
    istate = DefaultState(init)
    managed_iteration(f, mgr, istate; by=by)
end
