export Button

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

Button(width::Integer, height::Integer, img) = Button(Sprite2D(width, height, texture(img)), width, height, ListenersType())
Button(img::Image2D) = ((width, height) = size(img); Button(width, height, img))

function ispointover(btn::Button, point)
    halfwidth  = btn.width  / 2
    halfheight = btn.height / 2
    tf = FlixGL.transformof(btn)
    T  = transformparam(typeof(tf))
    point = world2obj(tf) * Vector3{T}(point..., 1)
    point[1] > -halfwidth && point[1] < halfwidth && point[2] > -halfheight && point[2] < halfheight
end
