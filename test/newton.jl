function newton2(fp::Function, fpp::Function, init; tol::Float64=1e-12,
                 maxiter::Int=500, verbose::Bool=true, print_skip::Int=5)
    # setup manager and state
    mgr = IterationManagers.DefaultManager(tol, maxiter, verbose, print_skip)
    istate = IterationManagers.DefaultState(init)

    # stages 2, 3, 4 in one shot!
    IterationManagers.managed_iteration(mgr, istate) do x
        x - fpp(x) \ fp(x)
    end
end

# f(x) = (x - 5)^4
fp(x) = 4*(x - 5)^3
fpp(x) = 12*(x - 5)^2

@test_approx_eq newton2(fp, fpp, 2.35283735).prev 5.0

function rosenbrock_gradient(x::Vector)
    out = similar(x)
    out[1] = -2.0 * (1.0 - x[1]) - 400.0 * (x[2] - x[1]^2) * x[1]
    out[2] = 200.0 * (x[2] - x[1]^2)
    out
end

function rosenbrock_hessian(x::Vector)
    n = length(x)
    out = Array(Float64, n, n)
    out[1, 1] = 2.0 - 400.0 * x[2] + 1200.0 * x[1]^2
    out[1, 2] = -400.0 * x[1]
    out[2, 1] = -400.0 * x[1]
    out[2, 2] = 200.0
    out
end

@test_approx_eq(newton2(rosenbrock_gradient, rosenbrock_hessian,
                        [-10.0, -10.0], print_skip=2).prev,
                [1.0, 1.0])

