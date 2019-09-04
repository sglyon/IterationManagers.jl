"""
IterManager: convergence based only on number of iterations

@author : Spencer Lyon <spencer.lyon@stern.nyu.edu>
@date : 2015-04-13 11:29:12

"""

struct IterManager <: IterationManager
    maxiter::Int
    verbose::Bool
    print_skip::Int
end

IterManager(maxiter::Int) = IterManager(maxiter, true, div(maxiter, 5))

function Base.show(io::IO, ::MIME"text/plain", im::IterManager)
    verb = im.verbose ? "verbose" : "not verbose"
    println(io, "IterManager: $(im.maxiter) max iterations ($(verb))")
end

finished(mgr::IterManager, istate::IterationState) =
    num_iter(istate) > mgr.maxiter
