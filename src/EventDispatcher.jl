export EventDispatcher

struct EventDispatcher
    listeners::Dict{Symbol, AbstractVector}
end
EventDispatcher() = EventDispatcher(Dict())

function hook!(listener, disp::EventDispatcher, sym::Symbol)
    if !haskey(disp.listeners, sym)
        disp.listeners[sym] = Any[]
    end
    push!(disp.listeners[sym], listener)
    listener
end

function hookonce!(listener, disp::EventDispatcher, sym::Symbol)
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
function unhook!(disp::EventDispatcher, sym::Symbol, listener)
    if haskey(disp.listeners, sym)
        idx = findfirst(curr->curr == listener, disp.listeners[sym])
        if idx != nothing
            deleteat!(disp.listeners[sym], idx)
        end
    end
    listener
end
