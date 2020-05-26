export Anchor, TopAnchor, LeftAnchor, RightAnchor, BottomAnchor, TopLeftAnchor, TopRightAnchor, BottomLeftAnchor, BottomRightAnchor, CenterAnchor
export TopAnchors, LeftAnchors, RightAnchors, BottomAnchors
export vertices, ispointover, uiinputconfig, setorigin!

@enum Anchor begin
    TopAnchor
    LeftAnchor
    RightAnchor
    BottomAnchor
    TopLeftAnchor
    TopRightAnchor
    BottomLeftAnchor
    BottomRightAnchor
    CenterAnchor
end

const TopAnchors    = (TopLeftAnchor, TopAnchor, TopRightAnchor)
const LeftAnchors   = (TopLeftAnchor, LeftAnchor, BottomLeftAnchor)
const RightAnchors  = (TopRightAnchor, RightAnchor, BottomRightAnchor)
const BottomAnchors = (BottomLeftAnchor, BottomAnchor, BottomRightAnchor)

include("./UI.Labels.jl")
include("./UI.Images.jl")
include("./UI.Buttons.jl")
include("./UI.Textfields.jl")


function VPECore.tick!(elem::AbstractUIComponent, dt::AbstractFloat) end

function getanchoredrectcoords(width::Real, height::Real, origin::Anchor)
    FlixGL.getrectcoords(width, height, anchor2offset(origin))
end
function anchor2offset(anchor::Anchor)
    if anchor == TopLeftAnchor
        (-1, 1)
    elseif anchor == TopAnchor
        (0, 1)
    elseif anchor == TopRightAnchor
        (1, 1)
    elseif anchor == LeftAnchor
        (-1, 0)
    elseif anchor == CenterAnchor
        (0, 0)
    elseif anchor == RightAnchor
        (1, 0)
    elseif anchor == BottomLeftAnchor
        (-1, -1)
    elseif anchor == BottomAnchor
        (0, -1)
    elseif anchor == BottomRightAnchor
        (1, -1)
    else
        error("Unknown anchor $anchor")
    end
end

function vertices(elem::AbstractUIComponent)
    getanchoredrectcoords(size(elem)..., elem.origin)
end

uiinputconfig(::AbstractUIComponent) = WantsNoInput

Base.size(elem::AbstractUIComponent) = (elem.width, elem.height)
onparentresized!(::AbstractUIComponent) = nothing


# Borrowed from VPECore
function VPECore.bounds(elem::AbstractUIElement)
    halfwidth, halfheight = size(elem) ./ 2
    offx, offy = anchor2offset(elem.origin) .* (halfwidth, halfheight)
    AABB(-halfwidth - offx, -halfheight - offy, halfwidth - offx, halfheight - offy)
end

function ispointover(elem::AbstractUIComponent, point)
    tf    = FlixGL.transformof(elem)
    T     = transformparam(typeof(tf))
    aabb  = bounds(elem)
    point = world2obj(tf) * Vector3{T}(point..., 1)
    point[1] > aabb.min[1] && point[1] < aabb.max[1] && point[2] > aabb.min[2] && point[2] < aabb.max[2]
end


function normalize_padding(padding)
    @assert padding !== nothing
    len = length(padding)
    if len == 1 && Base.IteratorSize(padding) == Base.HasShape{0}()
        padding, padding, padding, padding
    elseif len == 1
        pad = iterate(len)
        pad, pad, pad, pad
    elseif len == 2
        pad1, state = iterate(padding)
        pad2, state = iterate_next(padding, state)
        pad1, pad2, pad1, pad2
    elseif len == 3
        pad1, state = iterate(padding)
        pad2, state = iterate(padding, state)
        pad3, state = iterate(padding, state)
        pad1, pad2, pad3, pad4
    else
        pad1, state = iterate(padding)
        pad2, state = iterate(padding, state)
        pad3, state = iterate(padding, state)
        pad4, state = iterate(padding, state)
        pad1, pad2, pad3, pad4
    end
end


sizestring(width::Integer, height::Integer) = "$(width)×$(height)"
sizestring(width::AbstractFloat, height::AbstractFloat) = @sprintf("%.2f×%.2f", width, height)
