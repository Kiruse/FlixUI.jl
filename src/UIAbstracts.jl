export AbstractUIElement, AbstractUIContainer, AbstractUIMimic, AbstractUIElementFactory, UIEntity
export mimickedtype, mimicked

abstract type AbstractUIComponent <: AbstractEntity2D end
abstract type AbstractUIElement   <: AbstractUIComponent end
abstract type AbstractUIContainer <: AbstractUIElement end
abstract type AbstractUIMimic{T<:AbstractUIElement} <: AbstractUIComponent end
abstract type AbstractUIElementFactory end

const Mimicks{T<:AbstractUIElement} = Union{T, AbstractUIMimic{T}}

struct AutoSize end
const autosize = AutoSize()

# Additional Entity Class to filter out UI Entities separately.
struct UIEntity <: EntityClass end
FlixGL.entityclass(::Type{<:AbstractUIComponent}) = UIEntity()

mimickedtype(::Type{T}) where {T<:AbstractUIComponent} = T
mimickedtype(::Type{<:AbstractUIMimic{T}}) where T = T
mimicked(comp::AbstractUIComponent) = comp
mimicked(mimic::AbstractUIMimic) = mimic.mimicked
