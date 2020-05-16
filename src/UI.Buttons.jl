export Button

struct Button <: AbstractUIElement
    width::Integer
    height::Integer
    origin::Anchor
    transform::Transform2D
    listeners::ListenersType
    
    function Button(width, height, origin, transform, listeners)
        inst = new(width, height, origin, transform, listeners)
        transform.customdata = inst
        inst
    end
end
FlixGL.entityclass(::Type{Button}) = UIEntity()
eventdispatcherness(::Type{Button}) = IsEventDispatcher()
eventlisteners(btn::Button) = btn.listeners

function Button(width::Integer, height::Integer, img::BackgroundImageFactory, label::ContainerLabelFactory; transform::Transform2D = Transform2D{Float64}(), origin::Anchor = CenterAnchor)
    btn = Button(width, height, img, transform=transform, origin=origin)
    parent!(label(width, height, origin)::Label, btn)
    btn
end
function Button(width::Integer, height::Integer, img::BackgroundImageFactory; transform::Transform2D = Transform2D{Float64}(), origin::Anchor = CenterAnchor)
    btn = Button(width, height, origin, transform, ListenersType())
    parent!(img(width, height, origin)::Image, btn)
    btn
end
Button(img::BackgroundImageFactory, label::ContainerLabelFactory; transform::Transform2D = Transform2D{Float64}(), origin::Anchor = CenterAnchor) = Button(size(img.image)..., img, label, transform=transform, origin=origin)
Button(img::BackgroundImageFactory; transform::Transform2D = Transform2D{Float64}(), origin::Anchor = CenterAnchor) = Button(size(img.image)..., img, transform=transform, origin=origin)
