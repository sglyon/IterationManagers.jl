function simple(itr::Function, mgr::IterationManager=DefaultManager(1e-6, 10000))
    NS = 3000
    c = zeros(NS,4)

    # construct manager and state
    istate = DefaultState(c)  # initial state is the coefficients

    # Stages 2, 3, 4
    itr(mgr, istate) do c
        c_new = similar(c)

        # unpack coefficient vector from last time
        cadj, cnonadj, c1, c2 = c[:,1], c[:,2], c[:,3], c[:,4]

        c_new[:, 1] = rand()
        c_new[:, 2] = rand()
        c_new[:, 3] = rand()
        c_new[:, 4] = rand()

        # return new coefficients
        c_new
    end
end


function by_hand(maxiter=10000, tol=1e-6, verbose=true)
    NS = 3000
    c = zeros(NS,4)
    tol = 1e-6
    dist = 1.
    iter = 0
    elapsed = 0.0
    old_time = time()

    print_skip = div(maxiter, 5)

    while dist > tol && iter < maxiter
        # Stage 2: Iteration
        c_new = similar(c)

        # unpack coefficient vector from last time
        cadj, cnonadj, c1, c2 = c[:,1], c[:,2], c[:,3], c[:,4]

        c_new[:, 1] = rand()
        c_new[:, 2] = rand()
        c_new[:, 3] = rand()
        c_new[:, 4] = rand()

        # Stage 3: Between iteration processing
        dist = maxabs(c - c_new)
        iter += 1
        new_time = time()
        elapsed += new_time - old_time

        if verbose && iter % print_skip == 0
            println("Iteration: $iter\t dist: $(round(dist, 4))\t elapsed: $(elapsed)")
        end

        c = copy(c_new)
        old_time = new_time
    end
end
