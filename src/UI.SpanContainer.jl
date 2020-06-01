export SpanContainer

"""
A special container which assumes the slotted element implements Base.resize(::AbstractUIComponent, ::Real, ::Real).
Upon resizing the container, either directly or indirectly as a consequence of the parent resizing, it automatically
resizes the slotted element as well.

This ignores whether the slotted element integrates with the Measure type or any other form of automatic dynamic
resizing and will always override this behavior manually. The slotted element will always span the full size of the
container. As such, the container is meant to add spanning features to any resizeable element. This behavior is
essentially identical to that of `BackgroundImageMimic`s and `BackgroundColorMimic`s.
"""
mutable struct SpanContainer <: AbstractUIContainer
    realsize::Vector2{Float64}
    wantsize::Measure2{Float64}
    origin::Anchor
    element::Optional{AbstractUIComponent}
    background::Optional{AbstractBackgroundMimic}
    visible::Bool
    transform::Transform2D
    
    function SpanContainer(wantsize::Measure2, origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}())
        inst = transform.customdata = new(Vector2{Float64}(0, 0), wantsize, origin, nothing, nothing, true, transform)
        update_size!(inst)
        inst
    end
end
function SpanContainer(size::Measure2, bgargs::Optional{AbstractBackgroundArgs}, origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}())
    cnt = SpanContainer(size, origin, transform)
    cnt.background = containerbackground(cnt, bgargs)
    cnt
end
SpanContainer(width::MeasureValue, height::MeasureValue, bgargs::AbstractBackgroundArgs, origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}()) = SpanContainer(Measure2(width, height), bgargs, origin, transform)
SpanContainer(width::MeasureValue, height::MeasureValue,                                 origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}()) = SpanContainer(Measure2(width, height), origin, transform)
SpanContainer(width::Real, height::Real, bgargs::AbstractBackgroundArgs, origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}()) = SpanContainer(Measure2(absolute(width), absolute(height)), bgargs, origin, transform)
SpanContainer(width::Real, height::Real,                                 origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}()) = SpanContainer(Measure2(absolute(width), absolute(height)), origin, transform)

function slot!(cnt::SpanContainer, el::AbstractUIComponent)
    cnt.element = el
    parent!(el, cnt)
    resize_slotted(cnt)
    update_slotted_transform!(cnt)
end
slot(cnt::SpanContainer) = cnt.element
unslot(cnt::SpanContainer) = cnt.element = nothing

function FlixGL.setvisibility!(cnt::SpanContainer, visible::Bool)
    if cnt.element !== nothing
        setvisibility!(cnt.element, visible)
    end
    cnt.visible = visible
end
elements(cnt::SpanContainer) = (cnt.element,)

function Base.resize!(cnt::SpanContainer, width::Real, height::Real)
    cnt.wantsize = Measure2{Float64}(absolute(width), absolute(height))
    cnt.realsize = Vector2{Float64}(width, height)
    resize_slotted(cnt)
    update_slotted_transform!(cnt)
    foreach(onparentresized!, childrenof(cnt))
end
function Base.resize!(cnt::SpanContainer, width::MeasureValue, height::MeasureValue)
    cnt.wantsize = Measure2{Float64}(width, height)
    update_size!(cnt)
    resize_slotted(cnt)
    update_slotted_transform!(cnt)
    foreach(onparentresized!, childrenof(cnt))
end

function resize_slotted(cnt::SpanContainer)
    if cnt.element !== nothing
        cnt.element.origin = CenterAnchor
        resize!(cnt.element, size(cnt)...)
    end
end
function update_slotted_transform!(cnt::SpanContainer)
    if cnt.element !== nothing
        transform = transformof(cnt.element)
        transform.location = Vector2((size(cnt) .* anchor2offset(cnt.origin) .* -0.5)...)
        transform.rotation = 0
        transform.scale = Vector2(1, 1)
    end
    nothing
end

function onparentresized!(cnt::SpanContainer)
    update_size!(cnt)
    resize_slotted(cnt)
    foreach(onparentresized!, childrenof(cnt))
end
