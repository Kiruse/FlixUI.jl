export Anchor, TopAnchor, LeftAnchor, RightAnchor, BottomAnchor, TopLeftAnchor, TopRightAnchor, BottomLeftAnchor, BottomRightAnchor, CenterAnchor
export ispointover

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
include("./UI.Buttons.jl")

anchor!(elem::AbstractUIElement, anchor::Anchor) = elem.anchor = anchor

function getanchoredorigin(width::Integer, height::Integer, origin::Anchor)
    halfwidth, halfheight = (width, height) ./ 2
    
    verts = Float32[
        -halfwidth, -halfheight,
         halfwidth, -halfheight,
         halfwidth,  halfheight,
        -halfwidth,  halfheight
    ]
    
    if origin == TopAnchor
        verts[2:2:8] .-= halfheight
    elseif origin == LeftAnchor
        verts[1:2:8] .+= halfwidth
    elseif origin == RightAnchor
        verts[1:2:8] .-= halfwidth
    elseif origin == BottomAnchor
        verts[2:2:8] .+= halfheight
    elseif origin == TopLeftAnchor
        verts[2:2:8] .-= halfheight
        verts[1:2:8] .+= halfwidth
    elseif origin == TopRightAnchor
        verts[2:2:8] .-= halfheight
        verts[1:2:8] .-= halfwidth
    elseif origin == BottomLeftAnchor
        verts[2:2:8] .+= halfheight
        verts[1:2:8] .+= halfwidth
    elseif origin == BottomRightAnchor
        verts[2:2:8] .+= halfheight
        verts[1:2:8] .-= halfwidth
    end
    
    verts
end


function tick!(elem::AbstractUIElement, delta::Real) end

function ispointover(elem::AbstractUIElement, point)
    tf    = FlixGL.transformof(elem)
    T     = transformparam(typeof(tf))
    aabb  = bounds(elem)
    point = world2obj(tf) * Vector3{T}(point..., 1)
    point[1] > aabb.min[1] && point[1] < aabb.max[1] && point[2] > aabb.min[2] && point[2] < aabb.max[2]
end
