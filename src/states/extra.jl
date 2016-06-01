"""
```julia
ExtraState{T,U} <: IterationState{T}
```

Extends `DefaultState` to track extra information each iteration. The field
`other` can be of any type and is simply a storage facility for other data we
want to preserve between iterations. It is not used to check convergence or in
any other place inside IterationManagers.jl. It is simply a convenience for
users who want to keep track of more than just explicit state on each iteration
"""
type ExtraState{T,U} <: IterationState{T}
    default::DefaultState{T}
    other::U
end

ExtraState{T,U}(v::T, other::U) = ExtraState(DefaultState(v), other)


# just forward these methods on to the underlying default state
function Base.show{T,U}(io::IO, es::ExtraState{T,U})
    print(io,
    """
    ExtraState{$T,$U}:
        - default: $(stringmime(MIME"text/plain"(), es.default))
        - other  : $(stringmime(MIME"text/plain"(), es.other))
    """)
end
display_iter(io::IO, es::ExtraState, prefix) =
    display_iter(io, es.default, prefix)
num_iter(es::ExtraState) = num_iter(es.default)
Base.norm(es::ExtraState) = norm(es.default)

# this method calls the default's update! and update the `other` field
function update!{T,U}(es::ExtraState{T,U}, v::T, new_other::U;
                      by::Function=default_by)
    update!(es.default, v)
    es.other = new_other
    nothing
end

# need a special version of managed_iteration!? for this state to handle other
function managed_iteration!{T<:AbstractArray}(f!::Base.Callable,
                                              mgr::IterationManager,
                                              dest::T,
                                              es::ExtraState{T};
                                              by::Base.Callable=default_by)
    pre_hook(mgr, es)

    while !(finished(mgr, es))
        # this function updates dest in place and returns other
        other = f!(dest, es.prev)
        update!(es, dest, other; by=by)
        iter_hook(mgr, es)
    end

    post_hook(mgr, es)
    es
end

function managed_iteration{T}(f::Base.Callable, mgr::IterationManager,
                              es::ExtraState{T};
                              by=default_by)
    pre_hook(mgr, es)

    while !(finished(mgr, es))
        v, other = f(es.default.prev)
        v::T
        update!(es, v, other; by=by)
        iter_hook(mgr, es)
    end

    post_hook(mgr, es)
    es
end
