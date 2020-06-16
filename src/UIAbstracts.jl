export AbstractUIComponent, AbstractUIElement, AbstractUIContainer, AbstractUIContainerSlot, AbstractUIMimic, UIEntity
export mimickedtype, mimicked

abstract type AbstractUIComponent <: AbstractEntity2D end
abstract type AbstractUIElement   <: AbstractUIComponent end
abstract type AbstractUIContainer <: AbstractUIElement end
abstract type AbstractUIMimic{T<:AbstractUIElement} <: AbstractUIComponent end
abstract type AbstractUIContainerSlot <: AbstractUIComponent end

const Mimicks{T<:AbstractUIElement} = Union{T, AbstractUIMimic{T}}

struct AutoSize end
const autosize = AutoSize()
Base.convert(::Type{Union{T, AutoSize}}, ::AutoSize) where T = AutoSize
Base.convert(::Type{Union{T, AutoSize}}, x) where T = T(x)

# Additional Entity Class to filter out UI Entities separately.
struct UIEntity <: EntityClass end
FlixGL.entityclass(::Type{<:AbstractUIComponent}) = UIEntity()

mimickedtype(::Type{T}) where {T<:AbstractUIComponent} = T
mimickedtype(::Type{<:AbstractUIMimic{T}}) where T = T
mimicked(comp::AbstractUIComponent) = comp
mimicked(mimic::AbstractUIMimic) = mimic.mimicked
