export Button, ButtonLabel

struct Button <: AbstractUIElement
    width::Integer
    height::Integer
    transform::Transform2D
    listeners::ListenersType
    
    function Button(width, height, transform, listeners)
        inst = new(width, height, transform, listeners)
        transform.customdata = inst
        inst
    end
end
entityclass(Button) = EmptyEntity()
eventlisteners(btn::Button) = btn.listeners
eventdispatcherness(::Type{Button}) = IsEventDispatcher()

struct ButtonLabel
    label::AbstractString
    font::Font
    hpadding::Integer
    vpadding::Integer
    color::Color
    halign::TextHorizontalAlignment
    valign::TextVerticalAlignment
    
    function ButtonLabel(label, font; padding = 0, hpadding = 0, vpadding = 0, color = White, halign = AlignCenter, valign = AlignMiddle)
        if padding != 0 && hpadding == 0 && vpadding == 0
            hpadding = vpadding = padding
        end
        new(label, font, hpadding, vpadding, color, halign, valign)
    end
end
function (maker::ButtonLabel)(width, height)
    Label(maker.label, maker.font, width=width-maker.hpadding*2, height=height-maker.vpadding*2, color=maker.color, halign=maker.halign, valign=maker.valign)
end

function Button(width::Integer, height::Integer, img, label::ButtonLabel, transform::Transform2D = Transform2D{Float64}())
    btn = Button(width, height, img, transform)
    parent!(label(width, height)::Label, btn)
    btn
end
function Button(width::Integer, height::Integer, img, transform::Transform2D = Transform2D{Float64}())
    btn = Button(width, height, transform, ListenersType())
    parent!(Sprite2D(width, height, texture(img)), btn)
    btn
end
Button(img::Image2D, label::ButtonLabel) = Button(size(img)..., img, label)
Button(img::Image2D) = Button(size(img)..., img)

function ispointover(btn::Button, point)
    halfwidth  = btn.width  / 2
    halfheight = btn.height / 2
    tf = FlixGL.transformof(btn)
    T  = transformparam(typeof(tf))
    point = world2obj(tf) * Vector3{T}(point..., 1)
    point[1] > -halfwidth && point[1] < halfwidth && point[2] > -halfheight && point[2] < halfheight
end
