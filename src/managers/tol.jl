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
    m = "TolManager: {1:2.4e} tolerance level ({2})"
    printfmt(io, m, tm.tol, tm.verbose ? "verbose" : "not verbose")
end
