export Button

mutable struct Button <: AbstractUIElement
    width::Float64
    height::Float64
    origin::Anchor
    label::Optional{ContainerLabelMimic}
    background::Optional{BackgroundImageMimic}
    visible::Bool
    transform::Transform2D
    listeners::ListenersType
    
    function Button(width, height, origin, label, background, visible, transform, listeners)
        inst = new(width, height, origin, label, background, visible, transform, listeners)
        transform.customdata = inst
        inst
    end
end
function Button(width::Real, height::Real, img::Image2D, labelargs::ContainerLabelArguments; transform::Transform2D = Transform2D{Float64}(), origin::Anchor = CenterAnchor)
    btn = Button(width, height, origin, nothing, nothing, true, transform, ListenersType())
    btn.background = BackgroundImageMimic(btn, img)
    btn.label = ContainerLabelMimic(btn, labelargs)
    btn
end
function Button(width::Real, height::Real, img::Image2D; transform::Transform2D = Transform2D{Float64}(), origin::Anchor = CenterAnchor)
    btn = Button(width, height, origin, nothing, nothing, visible, transform, ListenersType())
    btn.background = BackgroundImageMimic(btn, img)
    btn
end
Button(img::Image2D, label::ContainerLabelArguments; transform::Transform2D = Transform2D{Float64}(), origin::Anchor = CenterAnchor) = Button(size(img.image)..., img, label, transform=transform, origin=origin)
Button(img::Image2D; transform::Transform2D = Transform2D{Float64}(), origin::Anchor = CenterAnchor) = Button(size(img.image)..., img, transform=transform, origin=origin)

VPECore.eventlisteners(btn::Button) = btn.listeners
uiinputconfig(::Button) = WantsMouseInput

function FlixGL.setvisibility!(btn::Button, visible::Bool)
    btn.visible = visible
    setvisibility!(btn.label, visible)
    setvisibility!(btn.background, visible)
end


##############
# Base methods

Base.show(io::IO, btn::Button) = write(io, "Button($(btn.width)×$(btn.height), $(btn.origin))")
function Base.resize!(btn::Button, width::Real, height::Real)
    btn.width  = width
    btn.height = height
    foreach(onparentresized!, childrenof(btn))
    btn
end
