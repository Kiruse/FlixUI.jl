export Button

mutable struct Button <: AbstractUIElement
    width::Integer
    height::Integer
    origin::Anchor
    label::Optional{Label}
    background::Image
    visible::Bool
    transform::Transform2D
    listeners::ListenersType
    
    function Button(width, height, origin, label, background, visible, transform, listeners)
        inst = new(width, height, origin, label, background, visible, transform, listeners)
        transform.customdata = inst
        inst
    end
end
function Button(width::Integer, height::Integer, img::BackgroundImageFactory, label::ContainerLabelFactory; transform::Transform2D = Transform2D{Float64}(), origin::Anchor = CenterAnchor)
    lbl = label(width, height, origin)::Label
    bg  = img(  width, height, origin)::Image
    btn = Button(width, height, origin, lbl, bg, true, transform, ListenersType())
    parent!(bg,  btn)
    parent!(lbl, btn)
    btn
end
function Button(width::Integer, height::Integer, img::BackgroundImageFactory; transform::Transform2D = Transform2D{Float64}(), origin::Anchor = CenterAnchor)
    bg  = img(width, height, origin)::Image
    btn = Button(width, height, origin, nothing, bg, visible, transform, ListenersType())
    parent!(img(width, height, origin)::Image, btn)
    btn
end
Button(img::BackgroundImageFactory, label::ContainerLabelFactory; transform::Transform2D = Transform2D{Float64}(), origin::Anchor = CenterAnchor) = Button(size(img.image)..., img, label, transform=transform, origin=origin)
Button(img::BackgroundImageFactory; transform::Transform2D = Transform2D{Float64}(), origin::Anchor = CenterAnchor) = Button(size(img.image)..., img, transform=transform, origin=origin)

VPECore.eventlisteners(btn::Button) = btn.listeners
uiinputconfig(::Button) = WantsMouseInput

function FlixGL.setvisibility(btn::Button, visible::Bool)
    btn.visible = visible
    setvisibility(btn.label, visible)
    setvisibility(btn.background, visible)
end


##############
# Base methods

Base.show(io::IO, btn::Button) = write(io, "Button($(btn.width)×$(btn.height), $(btn.origin))")
