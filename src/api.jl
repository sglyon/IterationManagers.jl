"""
Main generic API

@author : Spencer Lyon <spencer.lyon@stern.nyu.edu>
@date : 2015-04-13 11:29:12

"""

# ----------- #
# Manager API #
# ----------- #
verbose(m::IterationManager) = isdefined(m, :verbose) ? m.verbose : false

print_now(mgr::IterationManager, n::Int) =
    verbose(mgr) && isdefined(mgr, :print_skip) ? n % mgr.print_skip == 0 :
                                                  false

# --------- #
# State API #
# --------- #

# default methods for the `by` argument of `update!`
default_by{T<:Array}(x::T, y::T) = maxabs(x - y)
default_by{T<:Number}(x::T, y::T) = abs(x - y)

function default_by{S, T}(x::S, y::T)
    msg = "default_by not implemented for types x::$S, y::$T"
    throw(ArgumentError(msg))
end

display_iter(istate::IterationState) = display_iter(STDOUT, istate)

display_iter{T<:IterationState}(io::IO, istate::T) =
    error("display_iter be implemented directly by type $T")

# --------------------------- #
# Combining Manager and State #
# --------------------------- #

finished(mgr::DefaultManager, istate::DefaultState) =
    istate.n > mgr.maxiter || abs(istate.change) <= mgr.tol

finished(mgr::IterManager, istate::DefaultState) =  istate.n > mgr.maxiter
finished(mgr::TolManager, istate::DefaultState) =
    abs(istate.change) <= mgr.tol

# default hooks
pre_hook(mgr::IterationManager, istate::IterationState) =
    verbose(mgr) && display_iter(istate)

iter_hook(mgr::IterationManager, istate::IterationState) =
    print_now(mgr, istate.n) && display_iter(istate)

function post_hook(mgr::IterationManager, istate::IterationState)
    if !(isdefined(mgr, :maxiter))
        return nothing
    end
    if istate.n >= mgr.maxiter
        m = "Maximum iterations exceeded. Algorithm may not have converged"
        warn(m)
    end
    nothing
end

function managed_iteration(f::Function, mgr::IterationManager,
                           istate::IterationState;
                           by=default_by)
    pre_hook(mgr, istate)

    while !(finished(mgr, istate))
        v = f(istate.prev)
        update!(istate, v; by=by)
        iter_hook(mgr, istate)
    end

    post_hook(mgr, istate)
    istate
end

# kwarg version to create default manger/state
function managed_iteration(f::Function, init; tol::Float64=NaN,
                           maxiter::Int=reinterpret(Int, Inf),
                           by=default_by,
                           verbose=true,
                           print_skip=div(maxiter, 5))
    mgr = DefaultManager(tol, maxiter, verbose, print_skip)
    istate = DefaultState(init)
    managed_iteration(f, mgr, istate)
end
