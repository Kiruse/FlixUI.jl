export slot!, slot, unslot!, elements

include("./UI.LayoutContainers.jl")
include("./UI.SpanContainers.jl")

function Base.resize!(cnt::AbstractUIContainer, width::Real, height::Real)
    cnt.wantsize = Measure2(absolute(width), absolute(height))
    cnt.realsize = Vector2{Float64}(width, height)
    foreach(onparentresized!, childrenof(cnt))
end
function Base.resize!(cnt::AbstractUIContainer, width::MeasureValue, height::MeasureValue)
    cnt.wantsize = Measure2{Float64}(width, height)
    update_size!(cnt)
    foreach(onparentresized!, childrenof(cnt))
end
Base.size(cnt::AbstractUIContainer) = (cnt.realsize[1], cnt.realsize[2])
Base.length(::AbstractUIContainer) = 1

VPECore.bounds(::AbstractUIContainerSlot) = AABB(0, 0, 0, 0)

function update_size!(cnt::AbstractUIContainer)
    parent = parentof(cnt)
    if parent !== nothing
        parentsize = size(parent)
    else
        parentsize = size(activewindow())
    end
    cnt.realsize = Vector2{Float64}(resolvemeasure(cnt.wantsize, parentsize)...)
end
