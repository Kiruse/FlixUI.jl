export LayoutContainer

struct LayoutContainerSlot{T} <: AbstractUIContainerSlot
    element::AbstractUIComponent
    visible::Bool
    anchor::Anchor
    offset::Measure2{T}
    transform::Entity2DTransform{T}
end

mutable struct LayoutContainer{T} <: AbstractUIContainer
    realsize::Vector2{T}
    wantsize::Measure2{T}
    origin::Anchor
    slots::Dict{Symbol, LayoutContainerSlot{T}}
    background::Optional{AbstractBackgroundMimic}
    visible::Bool
    transform::Entity2DTransform{T}
    
    function LayoutContainer{T}(size::Measure2, origin::Anchor = CenterAnchor, transform::Entity2DTransform = defaulttransform()) where T
        inst = new{T}(Vector2{T}(0, 0), size, origin, Dict(), nothing, true, transform)
        update_size!(inst)
        inst
    end
end
function LayoutContainer(size::Measure2, bgargs::Optional{AbstractBackgroundArgs}, origin::Anchor = CenterAnchor, transform::Entity2DTransform{T} = defaulttransform()) where T
    inst = LayoutContainer{T}(size, origin, transform)
    inst.background = containerbackground(inst, bgargs)
    inst
end
LayoutContainer(width::MeasureValue, height::MeasureValue, bgargs::AbstractBackgroundArgs, origin::Anchor = CenterAnchor, transform::Entity2DTransform{T} = defaulttransform()) where T = LayoutContainer(Measure2{T}(width, height), bgargs, origin, transform)
LayoutContainer(width::MeasureValue, height::MeasureValue,                                 origin::Anchor = CenterAnchor, transform::Entity2DTransform{T} = defaulttransform()) where T = LayoutContainer(Measure2{T}(width, height), nothing, origin, transform)
LayoutContainer(width::Real, height::Real, bgargs::AbstractBackgroundArgs, origin::Anchor = CenterAnchor, transform::Entity2DTransform{T} = defaulttransform()) where T = LayoutContainer(Measure2{T}(absolute(width), absolute(height)), bgargs, origin, transform)
LayoutContainer(width::Real, height::Real,                                 origin::Anchor = CenterAnchor, transform::Entity2DTransform{T} = defaulttransform()) where T = LayoutContainer(Measure2{T}(absolute(width), absolute(height)), nothing, origin, transform)

function slot!(cnt::LayoutContainer{T},
               key::Symbol,
               el::AbstractUIComponent,
               anchor::Anchor = CenterAnchor,
               offset::Measure2 = Measure2{T}(absolute(0), absolute(0)),
               transform::Entity2DTransform{T} = defaulttransform()
              ) where T
    slot = cnt.slots[key] = LayoutContainerSlot{T}(el, true, anchor, offset, transform)
    parent!(slot, cnt)
    parent!(el, slot)
    update_transform!(slot)
    cnt
end
slot!(cnt::LayoutContainer{T}, key::Symbol, el::AbstractUIComponent, anchor::Anchor, width::MeasureValue, height::MeasureValue, transform::Entity2DTransform{T} = defaulttransform()) where T = slot!(cnt, key, el, anchor, Measure2{T}(width, height), transform)
slot!(cnt::LayoutContainer{T}, key::Symbol, el::AbstractUIComponent, anchor::Anchor, width::Real, height::Real, transform::Entity2DTransform{T} = defaulttransform()) where T = slot!(cnt, key, el, anchor, Measure2{T}(absolute(width), absolute(height)), transform)
slot(cnt::LayoutContainer, key::Symbol) = cnt.slots[key].element
unslot!(cnt::LayoutContainer, key::Symbol) = delete!(cnt.slots, key)

function FlixGL.setvisibility!(cnt::LayoutContainer, visible::Bool)
    if cnt.background !== nothing
        setvisibility!(cnt, visible)
    end
    for slot ∈ slots(cnt)
        setvisibility!(slot, visible)
    end
    cnt.visible = visible
end
function FlixGL.setvisibility!(slot::LayoutContainerSlot, visible::Bool)
    setvisibility!(slot.element, visible)
    slot.visible = visible
end
function FlixGL.collectentities!(ntts::Vector{T}, cnt::LayoutContainer, cls::Type{<:EntityClass}) where {T<:AbstractEntity}
    if isa(cnt, T) && isa(FlixGL.entityclass(LayoutContainer), cls)
        push!(ntts, cnt)
        FlixGL.collectentities!(ntts, cnt.background, cls)
        for child ∈ childrenof(cnt)
            if child !== cnt.background
                FlixGL.collectentities!(ntts, child, cls)
            end
        end
    end
    
    ntts
end

Base.length(cnt::LayoutContainer) = length(cnt.slots)
Base.keys(  cnt::LayoutContainer) = keys(cnt.slots)
Base.values(cnt::LayoutContainer) = values(cnt.slots)
elements(cnt::LayoutContainer) = (slot.element for slot ∈ values(cnt.slots))

function onparentresized!(cnt::LayoutContainer)
    update_size!(cnt)
    foreach(onparentresized!, childrenof(cnt))
end
function onparentresized!(slot::LayoutContainerSlot)
    update_transform!(slot)
    onparentresized!(slot.element)
end

function update_transform!(slot::LayoutContainerSlot)
    parent = parentof(slot)
    parentsize = size(parent)
    anchoroffset = parentsize .* (anchor2offset(slot.anchor) .- anchor2offset(parent.origin)) .* 0.5
    slot.transform.location = resolvemeasure(slot.offset, parentsize) .+ anchoroffset
end
