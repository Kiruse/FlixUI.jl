export Anchor, TopAnchor, LeftAnchor, RightAnchor, BottomAnchor, TopLeftAnchor, TopRightAnchor, BottomLeftAnchor, BottomRightAnchor, CenterAnchor
export vertices, ispointover

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

include("./UI.Labels.jl")
include("./UI.Images.jl")
include("./UI.Buttons.jl")


function VPECore.tick!(elem::AbstractUIElement, dt::AbstractFloat) end

function getanchoredrectcoords(width::Integer, height::Integer, origin::Anchor)
    FlixGL.getrectcoords(width, height, anchor2offset(origin))
end
function getanchoredpadoffset(anchor::Anchor, pad_top::Real, pad_left::Real, pad_right::Real, pad_bottom::Real)
    xoffset = yoffset = 0
    if anchor ∈ (TopLeftAnchor, TopAnchor, TopRightAnchor)
        yoffset = -pad_top
    elseif anchor ∈ (BottomLeftAnchor, BottomAnchor, BottomRightAnchor)
        yoffset = pad_bottom
    end
    if anchor ∈ (TopLeftAnchor, LeftAnchor, BottomLeftAnchor)
        xoffset = pad_right
    elseif anchor ∈ (TopRightAnchor, RightAnchor, BottomRightAnchor)
        xoffset = -pad_left
    end
    return xoffset, yoffset
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

function vertices(elem::AbstractUIElement)
    getanchoredrectcoords(size(elem)..., elem.origin)
end

# Borrowed from Bounds.jl
function bounds(elem::AbstractUIElement)
    halfwidth  = elem.width  / 2
    halfheight = elem.height / 2
    offx, offy = anchor2offset(elem.origin) .* (halfwidth, halfheight)
    AABB(-halfwidth - offx, -halfheight - offy, halfwidth - offx, halfheight - offy)
end

function ispointover(elem::AbstractUIElement, point)
    tf    = FlixGL.transformof(elem)
    T     = transformparam(typeof(tf))
    aabb  = bounds(elem)
    point = world2obj(tf) * Vector3{T}(point..., 1)
    point[1] > aabb.min[1] && point[1] < aabb.max[1] && point[2] > aabb.min[2] && point[2] < aabb.max[2]
end
