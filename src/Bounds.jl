export AABB
export bounds

struct AABB{T<:Real}
    min::Vector2{T}
    max::Vector2{T}
end

function bounds(T::Type{<:Real}, elem::AbstractUIElement)
    verts = vertsof(elem)
    if isempty(verst) return nothing end
    
    min = Vector2{T}(typemax(T), typemax(T))
    max = Vector2{T}(typemin(T), typemin(T))
    for vert ∈ verts
        min[1] = min(min[1], vert[1])
        min[2] = min(min[2], vert[2])
        max[1] = max(max[1], vert[1])
        max[2] = max(max[2], vert[2])
    end
    AABB(min, max)
end
bounds(elem::AbstractUIElement) = bounds(Float64, elem)
