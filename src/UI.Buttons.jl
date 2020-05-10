export Button, ButtonLabel

struct Button <: AbstractUIElement
    sprite::Sprite2D
    width::Integer
    height::Integer
    listeners::ListenersType
    
    function Button(sprite, width, height, listeners)
        inst = new(sprite, width, height, listeners)
        sprite.transform.customdata = inst
        inst
    end
end
@proxyentity Button sprite
eventlisteners(btn::Button) = btn.listeners
eventdispatcherness(::Type{Button}) = IsEventDispatcher()

function ButtonLabel(label::AbstractString, font::Font;
                     padding::Integer = 0,
                     hpadding::Integer = 0,
                     vpadding::Integer = 0,
                     color::Color = White,
                     halign::TextHorizontalAlignment = AlignCenter,
                     valign::TextVerticalAlignment = AlignMiddle
                    )
    if padding != 0 && hpadding == 0 && vpadding == 0
        hpadding = vpadding = padding
    end
    (width, height) -> Label(label, font, width=width-hpadding*2, height=height-vpadding*2, color=color, halign=halign, valign=valign)
end

function Button(width::Integer, height::Integer, img, labelmaker)
    btn = Button(width, height, img)
    parent!(labelmaker(width, height)::Label, btn)
    btn
end
Button(width::Integer, height::Integer, img) = Button(Sprite2D(width, height, texture(img)), width, height, ListenersType())
Button(img::Image2D, labelmaker) = ((width, height) = size(img); Button(width, height, img, labelmaker))
Button(img::Image2D) = ((width, height) = size(img); Button(width, height, img))

function ispointover(btn::Button, point)
    halfwidth  = btn.width  / 2
    halfheight = btn.height / 2
    tf = FlixGL.transformof(btn)
    T  = transformparam(typeof(tf))
    point = world2obj(tf) * Vector3{T}(point..., 1)
    point[1] > -halfwidth && point[1] < halfwidth && point[2] > -halfheight && point[2] < halfheight
end
