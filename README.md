
# IterationManagers

[![Build Status](https://travis-ci.org/spencerlyon2/IterationManagers.jl.svg?branch=master)](https://travis-ci.org/spencerlyon2/IterationManagers.jl)

## Introduction to the types

This lightweight package implements types for handling state and printing updates in iterative algorithms. The package is based on subtypes of two main abstract types: `IterationManager` and `IterationState`.


### IterationManager

The `IterationManager{T}` type is responsible for keeping track of top-level details. To see what this means, look at the implementation of the default manager defined in this package:

```julia
immutable IterTolManager <: IterationManager
    tol::Float64
    maxiter::Int
    verbose::Bool
    print_skip::Int
end
typealias DefaultManager IterTolManager

IterTolManager(tol::Float64, maxiter::Int) =
    IterTolManager(tol, maxiter, true, div(maxiter, 5))
```

This manager is responsible for defining the tolerance level for convergence, the maximum number of iterations allowed, whether the iterations should give verbose output, and how many iterations to go in between printouts. Another possible manger, also implemented in this package, is based only on the number of iterations to be performed:

```julia
immutable IterManager <: IterationManager
    maxiter::Int
    verbose::Bool
    print_skip::Int
end

IterManager(maxiter::Int) = IterManager(maxiter, true, div(maxiter, 5))
```

Notice this manager does not need to keep track of the desired tolerance level anymore.

There are also some API-level functions defined for all subtypes of `IterationManager`:

```julia
verbose(m::IterationManager) = isdefined(m, :verbose) ? m.verbose : false

print_now(mgr::IterationManager, n::Int) =
    verbose(mgr) && isdefined(mgr, :print_skip) ? n % mgr.print_skip == 0 :
                                                  false
```

These functions will both return false if the manager doesn't have have a `verbose` field. The `print_now` function will return `true` if and only if there is a `verbose` equal to true and there is a `print_skip` field such that `n % print_skip ==0` (`print_skip` is a divisor of `n`).

### IterationState

Subtypes of `IterationState{T}` are responsible for keeping track of the progress of the algorithm _between_ iterations. The default iteration state type is defined as follows:

```julia
type DefaultState{T} <: IterationState{T}
    n::Int              # number of iterations
    change::Float64     # change between previous and current state
    elapsed::Float64    # total time elapsed
    prev::T             # previous value
    prev_time::Float64  # previous absolute time
end

DefaultState{T}(v::T) = DefaultState(0, Inf, 0.0, v, time())
```

Notice that the abstract `IterationState{T}` is a parametric type with one type parameter `T`. This package currently uses this only so subtypes of `IterationState{T}`, like `DefaultState{T}` above, can have specialized code generated for each type of state, but we may utilize this more in the future.

The `DefaultState` has fields that let it keep track of the number of iterations, the total elapsed computation time, as well as details about the current iteration (change from previous, value of previous, and absolute time on previous iteration).

## API: Combining Manager and State

By themselves, the `IterationManager` and `IterationState` are not very useful. However, when we combine the two, we can reduce a lot of boilerplate code that appears in many iterative algorithms.

### Example: Newton's method

Before diving into how the api works, let's consider the following example, which has a pattern quite common in many of the algorithms I have seen and written:

```julia
function newton(fp::Function, fpp::Function, init; tol::Float64=1e-12,
                 maxiter::Int=500, verbose::Bool=true, print_skip::Int=5)
    # Stage 1: Setup
    x = copy(init)
    dist = 1.
    iter = 0
    elapsed = 0.0
    old_time = time()

    while dist > tol && iter < maxiter
        # Stage 2: Iteration
        x_new = x - fpp(x) \ fp(x)

        # Stage 3: Between iteration processing
        dist = maxabs(x - x_new)
        iter += 1
        new_time = time()
        elapsed += new_time - old_time

        if verbose && iter % print_skip == 0
            println("Iteration: $iter\t dist: $(round(dist, 9))\t elapsed: $(elapsed)")
        end

        copy!(x, x_new)
        old_time = new_time
    end

    # Stage 4: post iteration processing
    if verbose
        if iter >= maxiter
            error("failed to converge in $maxiter iterations")
        else
            println("Converged successfully after $iter iterations")
        end
    end
    x
end
```


This code implements a simple version of Newton's method to compute the root of a function given the first and second derivatives of a function and an initial condition. But, what the code actually does is not important to our discussion; we just care about its structure. Notice that there are 4 main sections of the code:

1. Setup
2. Iteration
3. Between iteration processing
4. Post iteration processing

Almost all the iterative algorithms I have ever written have either this exact structure, or a subset of it (not all algorithms need a post-iteration step, for example). Given that this structure is so common, we should be able to automate it and remove some boiler-plate. Well, it turns out that we can! Consider another version of the `newton` function from above:

```julia
function newton2(fp::Function, fpp::Function, init; tol::Float64=1e-12,
                 maxiter::Int=500, verbose::Bool=true, print_skip::Int=5)
    # setup manager and state
    mgr = DefaultManager(tol, maxiter, verbose, print_skip)
    istate = DefaultState(init)

    # stages 2, 3, 4 in one shot!
    managed_iteration(mgr, istate) do x
        x - fpp(x) \ fp(x)
    end
end
```

In this function we take the same arguments and use them to construct an instance of `DefaultManager` and `DefaultState`. We then call the `managed_iteration` function, which has the following signature:


```
managed_iteration(f::Function, mgr::IterationManager, istate::IterationState; by=default_by)
```

The first argument `f` is passed along to `managed_iteration` using Julia's [do block syntax](http://julia.readthedocs.org/en/latest/manual/functions/#do-block-syntax-for-function-arguments) and represents the code needed to perform one iteration. The `managed_iteration` function will do all the same pre-mid- and post-processing that we had to do in the original version of `newton`.

I wish to point out that we could also write a one-line version of newton's method using a special keyword argument version of `managed_iteration` that constructs the manager and state automatically:

```julia
function newton3(fp::Function, fpp::Function, init; tol::Float64=1e-12,
                 maxiter::Int=500, verbose::Bool=true, print_skip::Int=5)
    # all four stages in one!
    managed_iteration(x->x-fpp(x)\fp(x), init; tol=tol, maxiter=maxiter, 
                      print_skip=print_skip, verbose=verbose)
end
```


### Example: VFI

Above we saw how we could simplify our implementation of Newton's method and focus on the algorithm itself, rather than managing state or printing messages to update the user. Now I'd like to show a more complicated example. I will just show the before and after using this package functions:


```julia
function vfi(m::GrowthModel, V::Array{Float64, 3}=V_init(m),
             R::Array{Float64, 5}=get_R(m);
             tol::Real=1e-6, howard_steps::Int=5, maxiter::Int=400)
    # Stage 1: Setup
    V_new = similar(V)
    pol_ind = similar(V_new, (Int, Int))  # policies will be indexes (ints)
    βEV = similar(V)
    dist = 1.
    iter = 0
    elapsed = 0.0
    old_time = time()

    while dist > tol && iter < maxiter
        # Stage 2: do iteration
        update_βEV!(m, V, βEV)
        max_R_βEV!(m, βEV, R, V_new, pol_ind)
        howard_improvement!(m, howard_steps, βEV, R, V_new, pol_ind)

        # Stage 3: between iteration processing
        dist = maxabs(V - V_new)
        copy!(V, V_new)
        iter += 1
        new_time = time()
        elapsed += new_time - old_time - t_old
        old_time = new_time
        print("Iteration: $iter\t dist: $(round(dist, 4))\t elapsed: $(elapsed)")
    end

    # Stage 4: post iteration processing
    if iter == maxiter
        error("pfi failed to converge in $maxiter iterations")
    else
        println("Converged successfully after $iter iterations")
    end

    return V_upd, pol_k_ind
end

# now version using manged_iteration
function vfi_managed(m::GrowthModel, V::Array{Float64, 3}=V_init(m),
             R::Array{Float64, 5}=get_R(m);
             tol::Real=1e-6, howard_steps::Int=5, maxiter::Int=400)
    # Stage 1: Setup
    V_new = similar(V)
    pol_ind = similar(V_new, (Int, Int))  # policies will be indexes (ints)
    βEV = similar(V)
    state = (V, pol_ind, βEV)  # now state is 4-tuple we will be updating

    # construct manager and state
    mgr = DefaultManager(tol, maxiter)
    istate = DefaultState(state)

    # Stages 2, 3, 4
    managed_iteration(mgr, istate; by=(x,y)->maxabs(x[1] - y[1])) do st
        # unpack state and do one iteration
        V, pol_ind, βEV = st
        V_new = similar(V)
        update_βEV!(m, V, βEV)
        max_R_βEV!(m, βEV, R, V_new, pol_ind)
        howard_improvement!(m, howard_steps, βEV, R, V_new, pol_ind)

        # returned repacked state
        (V_new, pol_ind, βEV)
    end
end
```

I will point out a few key things about this code:

- The `T` in `DefaultState{T}` is now a 4-tuple of arrays. This allows us to keep track of all moving parts from one iteration to the next and allows the compiler to generate specialized code
- I had to specify the keyword argument `by` when calling `managed_iteration`. The `by` argument is a function that computes the convergence criterion for successive iterations. In our case, we wanted to compare `V` and `V_new` using the sup-norm (max absolute difference -- also called the sup norm) which happened to be the first and second elements of our `st` tuple, respectively.
- This code will not actually run because functions called in this routine (e.g. `howard_improvement!`) are not included here. We simply wanted to see an example of using IterationManagers to tackle a more complicated problem.



### Implementation

As we saw above, the `managed_iteration` function does a lot of the heavy lifting. Studying how it is implemented will help us learn most of what we need to understand how this package works. It's actual implementation (as of 4-13-15) is

```julia
function managed_iteration(f::Function, mgr::IterationManager,
                           istate::IterationState;
                           by=default_by)
    pre_hook(mgr, istate)

    while !(finished(mgr, istate))
        v = f(istate.prev)
        update!(istate, v; by=by)
        iter_hook(mgr, istate)
    end

    post_hook(mgr, istate)
    istate
end
```


There are 3 main components:

1. A `finished(mgr::IterationManager, istate::IterationState) => Bool` function that simply takes an `IterationManager` and `IterationState` and checks if the loop should terminate after each iteration
2. The `update!{T}(istate::IterationState, v::T, by=by) => nothing` method that updates the contents of the `IterationState` **inplace** using the new value returned by the function. This routine will check for convergence using the `by` function argument passed to it (the default argument for `by` is a function named `default_by`, which is in `api.jl`)
3. Various `_hook(mgr::IterationManager, istate::IterationState)` methods that allow the user to inject arbitrary code to be run at three stages of the code:
    1. `pre_hook(...) => nothing`: Before iterations begin
    2. `iter_hook(...) => nothing`: Between iterations
    3. `post_hook(...) => nothing`: After iterations end

Implementations of each of these functions for the built-in types can be found either in `api.jl` or the file dedicated to a specific subtype (e.g. all methods above are in `api.jl` except the `update!` method, which can be found in `states/default.jl`).

## Other

More docs may be written at some point... File an issue if you have a specific request or something isn't clear
