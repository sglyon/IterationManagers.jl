"""
Handling convergence ciretron for iterative algorithms

@author : Spencer Lyon <spencer.lyon@stern.nyu.edu>
@date : 2015-04-13 11:29:12

"""
module IterationManagers
import LinearAlgebra
using LinearAlgebra: norm
using Printf

abstract type IterationManager end
abstract type IterationState{T} end

export
# types
    IterationManager, IterationState, IterTolManager,  DefaultManager,
    IterManager, DefaultState, ExtraState,

# functions
    finished, update!, managed_iteration,
    verbose, print_now, display_iter, num_iter

include("states/default.jl")
include("states/extra.jl")

include("managers/itertol.jl")
include("managers/iter.jl")
include("managers/tol.jl")

include("api.jl")

end # module
