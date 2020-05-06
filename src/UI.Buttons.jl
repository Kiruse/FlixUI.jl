export Button

struct Button <: AbstractUIElement
    sprite::Sprite2D
    width::Integer
    height::Integer
end
@proxyentity Button sprite

Button(width::Integer, height::Integer, img) = Button(Sprite2D(width, height, texture(img)), width, height)

function tick!(btn::Button, delta::Real)
    error("Not implemented")
end
