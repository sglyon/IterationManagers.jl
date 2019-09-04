"""
IterTolManager: convergence based on iterations and tolerance

@author : Spencer Lyon <spencer.lyon@stern.nyu.edu>
@date : 2015-04-13 11:29:12

"""

struct IterTolManager <: IterationManager
    tol::Float64
    maxiter::Int
    verbose::Bool
    print_skip::Int
    print_prefix::String
end
const DefaultManager = IterTolManager

function IterTolManager(
        tol::Float64,
        maxiter::Int,
        verbose::Bool=true,
        print_skip::Int=div(maxiter, 5),
    )
    IterTolManager(tol, maxiter, verbose, print_skip, "")
end

function IterTolManager(;tol::Float64=1e-10, maxiter::Int=1000,
                         verbose::Bool=true, print_skip=div(maxiter, 5),
                         print_prefix="")
    IterTolManager(tol, maxiter, verbose, print_skip, print_prefix)
end

function Base.show(io::IO, ::MIME"text/plain", dm::DefaultManager)
    @printf(io,
            "DefaultManager. %2.4e tolerance level, %i max iterations (%s)",
            dm.tol, dm.maxiter, dm.verbose ? "verbose" : "not verbose")
end

finished(mgr::DefaultManager, istate::IterationState) =
    num_iter(istate) > mgr.maxiter || norm(istate) <= mgr.tol
