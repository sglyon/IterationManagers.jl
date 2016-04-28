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
end
typealias DefaultManager IterTolManager

IterTolManager(tol::Float64, maxiter::Int) =
    IterTolManager(tol, maxiter, true, div(maxiter, 5))

function Base.writemime(io::IO, ::MIME"text/plain", dm::DefaultManager)
    m = "DefaultManager: {1:2.4e} tolerance level, {2} max iterations ({3})"
    printfmt(io, m, dm.tol, dm.maxiter, dm.verbose ? "verbose" : "not verbose")
end

finished(mgr::DefaultManager, istate::IterationState) =
    num_iter(istate) > mgr.maxiter || norm(istate) <= mgr.tol
