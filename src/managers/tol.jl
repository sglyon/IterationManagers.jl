"""
TolManager: convergence based only on tolerance

@author : Spencer Lyon <spencer.lyon@stern.nyu.edu>
@date : 2015-04-13 11:29:12

"""

immutable TolManager <: IterationManager
    tol::Float64
    verbose::Bool
    print_skip::Int
end

TolManager(tol::Float64) = TolManager(tol, true, 50)

function Base.writemime(io::IO, ::MIME"text/plain", tm::TolManager)
    @printf(io,
            "TolManager: %2.4e tolerance level (%s)",
            tm.tol, tm.verbose)
end

finished(mgr::TolManager, istate::IterationState) =
    norm(istate) <= mgr.tol
