export AbstractUIElement
export Anchor, TopAnchor, LeftAnchor, RightAnchor, BottomAnchor, TopLeftAnchor, TopRightAnchor, BottomLeftAnchor, BottomRightAnchor, CenterAnchor

abstract type AbstractUIElement <: AbstractEntity2D end

@enum(Anchor,
    TopAnchor,
    LeftAnchor,
    RightAnchor,
    BottomAnchor,
    TopLeftAnchor,
    TopRightAnchor,
    BottomLeftAnchor,
    BottomRightAnchor,
    CenterAnchor
)

include("./UI.Label.jl")

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
