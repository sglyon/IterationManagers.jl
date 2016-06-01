"""
IterTolManager: convergence based on iterations and tolerance

@author : Spencer Lyon <spencer.lyon@stern.nyu.edu>
@date : 2015-04-13 11:29:12

"""

immutable IterTolManager <: IterationManager
    tol::Float64
    maxiter::Int
    verbose::Bool
    print_skip::Int
    print_prefix::ASCIIString
end
typealias DefaultManager IterTolManager

IterTolManager(tol::Float64, maxiter::Int) =
    IterTolManager(tol, maxiter, true, div(maxiter, 5), "")

function IterTolManager(;tol::Float64=1e-10, maxiter::Int=1000,
                         verbose::Bool=true, print_skip=div(maxiter, 5),
                         print_prefix="")
    IterTolManager(tol, maxiter, verbose, print_skip, print_prefix)
end

function Base.writemime(io::IO, ::MIME"text/plain", dm::DefaultManager)
    @printf(io,
            "DefaultManager. %2.4e tolerance level, %i max iterations (%s)",
            dm.tol, dm.maxiter, dm.verbose ? "verbose" : "not verbose")
end

finished(mgr::DefaultManager, istate::IterationState) =
    num_iter(istate) > mgr.maxiter || norm(istate) <= mgr.tol
