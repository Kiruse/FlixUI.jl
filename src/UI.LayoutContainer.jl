export LayoutContainer

struct LayoutContainerSlot <: AbstractUIContainerSlot
    element::AbstractUIComponent
    visible::Bool
    anchor::Anchor
    offset::Vector2{Float64}
    transform::Transform2D
    
    function LayoutContainerSlot(element, visible, anchor, offset, transform)
        inst = new(element, visible, anchor, offset, transform)
        transform.customdata = inst
        inst
    end
end

mutable struct LayoutContainer <: AbstractUIContainer
    realsize::Vector2{Float64}
    wantsize::Measure2{Float64}
    origin::Anchor
    slots::Dict{Symbol, LayoutContainerSlot}
    background::Optional{AbstractBackgroundMimic}
    visible::Bool
    transform::Transform2D
    
    function LayoutContainer(wantsize, origin, slots, background, visible, transform)
        inst = transform.customdata = new(Vector2{Float64}(0, 0), wantsize, origin, slots, background, visible, transform)
        update_size!(inst)
        inst
    end
end
function LayoutContainer(size::Measure2, bgargs::Optional{AbstractBackgroundArgs}, origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}())
    inst = LayoutContainer(size, origin, Dict(), nothing, true, transform)
    if bgargs !== nothing
        inst.background = containerbackground(inst, bgargs)
    end
    inst
end
LayoutContainer(size::Measure2, origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}()) = LayoutContainer(size, nothing, origin, transform)
LayoutContainer(width::MeasureValue, height::MeasureValue, bgargs::AbstractBackgroundArgs, origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}()) = LayoutContainer(Measure2{Float64}(width, height), bgargs, origin, transform)
LayoutContainer(width::MeasureValue, height::MeasureValue, origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}()) = LayoutContainer(Measure2{Float64}(width, height), nothing, origin, transform)
LayoutContainer(width::Real, height::Real, bgargs::AbstractBackgroundArgs, origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}()) = LayoutContainer(Measure2{Float64}(absolute(width), absolute(height)), bgargs, origin, transform)
LayoutContainer(width::Real, height::Real, origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}()) = LayoutContainer(Measure2{Float64}(absolute(width), absolute(height)), nothing, origin, transform)

function slot!(cnt::LayoutContainer, key::Symbol, el::AbstractUIComponent, anchor::Anchor = CenterAnchor, offset::Vector2 = Vector2{Float64}(0, 0), transform::Transform2D = Transform2D{Float64}())
    slot = cnt.slots[key] = LayoutContainerSlot(el, true, anchor, offset, transform)
    parent!(slot, cnt)
    parent!(el, slot)
    update_transform!(slot)
    cnt
end
slot(cnt::LayoutContainer, key::Symbol) = cnt.slots[key]

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

Base.size(  cnt::LayoutContainer) = (cnt.realsize[1], cnt.realsize[2])
Base.length(cnt::LayoutContainer) = length(cnt.slots)
Base.keys(  cnt::LayoutContainer) = keys(cnt.slots)
Base.values(cnt::LayoutContainer) = values(cnt.slots)
elements(cnt::LayoutContainer) = (slot.element for slot ∈ values(cnt.slots))

function Base.resize!(cnt::LayoutContainer, width::Real, height::Real)
    cnt.wantsize = Measure2(absolute(width), absolute(height))
    cnt.realsize = Vector2{Float64}(width, height)
    foreach(onparentresized!, childrenof(cnt))
end
function Base.resize!(cnt::LayoutContainer, width::MeasureValue, height::MeasureValue)
    cnt.wantsize = Measure2{Float64}(width, height)
    update_size!(cnt)
    foreach(onparentresized!, childrenof(cnt))
end

function onparentresized!(cnt::LayoutContainer)
    update_size!(cnt)
    foreach(onparentresized!, childrenof(cnt))
end
function onparentresized!(slot::LayoutContainerSlot)
    update_transform!(slot)
    onparentresized!(slot.element)
end

function update_size!(cnt::LayoutContainer)
    parent = parentof(cnt)
    if parent !== nothing
        parentsize = size(parent)
    else
        parentsize = size(activewindow())
    end
    println(parentsize)
    
    cnt.realsize = Vector2{Float64}(resolvemeasure(cnt.wantsize, parentsize)...)
end

function update_transform!(slot::LayoutContainerSlot)
    parent = parentof(slot)
    parentw, parenth = size(parent)
    anchoroffset = (parentw, parenth) .* (anchor2offset(slot.anchor) .- anchor2offset(parent.origin)) .* 0.5
    slot.transform.location = slot.offset .+ anchoroffset
end

FlixGL.entityclass(::Type{LayoutContainerSlot}) = UIEntity()
FlixGL.entityclass(::Type{LayoutContainer}) = UIEntity()
