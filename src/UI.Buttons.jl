export Button

mutable struct Button <: AbstractUIElement
    width::Float64
    height::Float64
    origin::Anchor
    label::Optional{ContainerLabelMimic}
    background::Optional{AbstractBackgroundMimic}
    visible::Bool
    transform::Transform2D
    listeners::ListenersType
end
function Button(width::Real, height::Real, imgargs::AbstractBackgroundArgs, labelargs::ContainerLabelArgs; transform::Entity2DTransform = defaulttransform(), origin::Anchor = CenterAnchor)
    btn = Button(width, height, origin, nothing, nothing, true, transform, ListenersType())
    btn.background = containerbackground(btn, imgargs)
    btn.label = ContainerLabelMimic(btn, labelargs)
    btn
end
function Button(width::Real, height::Real, imgargs::AbstractBackgroundArgs; transform::Entity2DTransform = defaulttransform(), origin::Anchor = CenterAnchor)
    btn = Button(width, height, origin, nothing, nothing, true, transform, ListenersType())
    btn.background = containerbackground(btn, imgargs)
    btn
end
Button(img::Image2D, label::ContainerLabelArgs; transform::Entity2DTransform = defaulttransform(), origin::Anchor = CenterAnchor) = Button(size(img)..., BackgroundImageArgs(img), label, transform=transform, origin=origin)
Button(img::Image2D; transform::Entity2DTransform = defaulttransform(), origin::Anchor = CenterAnchor) = Button(size(img)..., BackgroundImageArgs(img), transform=transform, origin=origin)

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
