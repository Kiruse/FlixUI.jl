export AbstractUIElement, AbstractUIElementFactory, UIEntity

abstract type AbstractUIElement <: AbstractEntity2D end
abstract type AbstractUIElementFactory end

# Additional Entity Class to filter out UI Entities separately.
struct UIEntity <: EntityClass end
FlixGL.entityclass(::Type{<:AbstractUIElement}) = UIEntity()
