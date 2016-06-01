"""
Handling convergence ciretron for iterative algorithms

@author : Spencer Lyon <spencer.lyon@stern.nyu.edu>
@date : 2015-04-13 11:29:12

"""
module IterationManagers

abstract IterationManager
abstract IterationState{T}

export
# types
    IterationManager, IterationState, IterTolManager,  DefaultManager,
    IterManager, DefaultState, ExtraState,

# functions
    finished, update!, managed_iteration,
    verbose, print_now, display_iter, num_iter

for s in ["default", "extra"]
    include("states/$s.jl")
end

for m in ["itertol", "tol", "iter"]
    include("managers/$m.jl")
end

include("api.jl")

end # module
