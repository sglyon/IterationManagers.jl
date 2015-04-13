"""
IterManager: convergence based only on number of iterations

@author : Spencer Lyon <spencer.lyon@stern.nyu.edu>
@date : 2015-04-13 11:29:12

"""

immutable IterManager <: IterationManager
    maxiter::Int
    verbose::Bool
    print_skip::Int
end

IterManager(maxiter::Int) = IterManager(maxiter, true, div(maxiter, 5))

function Base.writemime(io::IO, ::MIME"text/plain", im::IterManager)
    m = "IterManager: {1} max iterations ({2})"
    printfmt(io, m, im.maxiter, im.verbose ? "verbose" : "not verbose")
end
