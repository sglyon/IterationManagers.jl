using IterationManagers
using PlotlyJS

import IterationManagers: update!, finished, pre_hook, iter_hook, post_hook

type PlottingMgr <: IterationManager
    nupdates::Int
    p::PlotlyJS.SyncPlot
end

PlottingMgr(nupdates::Int, x::Vector) = PlottingMgr(nupdates, plot(scatter(;y=x)))

type PlottingState{T} <: IterationState{T}
    nupd::Int
    npts::Int
    prev::T
end

function update!(istate::PlottingState, v; by=nothing)

    # Update number of times we've updated the plot
    istate.nupd += 1

    # Update Points
    istate.prev = copy(v)

    # Update trace
    restyle!(mgr.p, y=Vector[v])
end

finished{T}(mgr::PlottingMgr, istate::PlottingState{T}) = istate.nupd > mgr.nupdates? true : false


function plot_update{T<:AbstractVector}(v::T)

    # Replace oldest point with random number
    vnew = Array(eltype(v), size(v))
    vnew[1:end-1] = v[2:end]
    vnew[end] = randn()

    return vnew
end

function pre_hook{T}(mgr::PlottingMgr, istate::PlottingState{T})
    istate.prev = mgr.p.plot.data[1][:y]
    display(mgr.p)
    nothing
end
iter_hook{T}(mgr::PlottingMgr, istate::PlottingState{T}) = println("Hi, drew $(istate.prev[end])")
post_hook{T}(mgr::PlottingMgr, istate::PlottingState{T}) = println("Hi, I'm done.")


npts = 100
nupdates = 500
mgr = PlottingMgr(nupdates, randn(npts))
istate = PlottingState(0, npts, Array(Float64, npts))
managed_iteration(plot_update, mgr, istate; by=nothing)

