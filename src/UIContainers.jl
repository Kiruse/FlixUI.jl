export slot!, slot, elements

include("./UI.LayoutContainer.jl")

Base.length(::AbstractUIContainer) = 1

VPECore.bounds(::AbstractUIContainerSlot) = AABB(0, 0, 0, 0)
