export EventDispatcher
export hook!, hookonce!, unhook!, emit

struct EventDispatcher
    listeners::Dict{Symbol, Vector}
end
EventDispatcher() = EventDispatcher(Dict())

eventlisteners(disp) = disp.listeners

"""
Hook the specified listener. Whether the same listener may be hooked (and called) more than once depends on the
implementation.
"""
function hook!(listener, disp, sym::Symbol)
    listeners = eventlisteners(disp)
    if !haskey(listeners, sym)
        listeners[sym] = Any[]
    end
    push!(listeners[sym], listener)
    disp
end

"""
Hook the specified listener for a single call. Afterwards, automaticaly `unhook!`.
"""
function hookonce!(listener, disp, sym::Symbol)
    wrapper = (args...; kwargs...) -> begin
        unhook!(disp, sym, wrapper)
        listener(args..., kwargs...)
    end
    hook!(wrapper, disp, sym)
end

"""
Remove a previously registered hooked event listener.
As anonymous functions are unique `unhook` cannot be used with the `unhook!(<...>) do <...>` syntax.
"""
function unhook!(disp, sym::Symbol, listener)
    listeners = eventlisteners(disp)
    if haskey(listeners, sym)
        idx = findfirst(curr->curr == listener, listeners[sym])
        if idx != nothing
            deleteat!(listeners[sym], idx)
        end
    end
    disp
end

"""
Emit an event on the given dispatcher with provided args and keyword args.
"""
function emit(disp, sym::Symbol, args...; kwargs...)
    listeners = eventlisteners(disp)
    results = Vector(undef, length(listeners))
    if haskey(listeners, sym)
        for listener ∈ listeners[sym]
            push!(results, listener(args...; kwargs...))
        end
    end
    results
end
