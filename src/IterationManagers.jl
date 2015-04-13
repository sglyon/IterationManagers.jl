"""
Handling convergence ciretron for iterative algorithms

@author : Spencer Lyon <spencer.lyon@stern.nyu.edu>
@date : 2015-04-13 11:29:12

"""

module IterationManagers

using Formatting

abstract IterationManager
abstract IterationState{T}

export
# types
    IterationManager, IterationState, IterTolManager,  DefaultManager,
    IterManager, DefaultState,

# functions
    finished, update!, managed_iteration,
    verbose, print_now, display_iter


for m in ["itertol", "tol", "iter"]
    include("managers/$m.jl")
end

for s in ["default"]
    include("states/$s.jl")
end

include("api.jl")

end # module
