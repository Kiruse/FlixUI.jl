export Image, BackgroundImageFactory

mutable struct Image <: AbstractUIElement
    width::Integer
    height::Integer
    origin::Anchor
    sprite::Sprite2D
    listeners::ListenersType
    
    function Image(width, height, origin, sprite, listeners)
        inst = new(width, height, origin, sprite, listeners)
        transformof(sprite).customdata = inst
        inst
    end
end
FlixGL.entityclass(::Type{Image}) = UIEntity()

function Image(width::Integer, height::Integer, img, origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}())
    sprite = Sprite2D(width, height, texture(img), originoffset=anchor2offset(origin), static=false, transform=transform)
    inst = Image(width, height, origin, sprite, ListenersType())
    inst
end

# Overridden Entity Characteristics
FlixGL.wantsrender(img::Image) = FlixGL.wantsrender(img.sprite)
FlixGL.vertsof(    img::Image) = FlixGL.getanchoredrectcoords(img.width, img.height, img.origin)
FlixGL.countverts( img::Image) = FlixGL.countverts(img.sprite)
FlixGL.vaoof(      img::Image) = FlixGL.vaoof(img.sprite)
FlixGL.transformof(img::Image) = FlixGL.transformof(img.sprite)
FlixGL.materialof( img::Image) = FlixGL.materialof(img.sprite)
FlixGL.drawmodeof( img::Image) = FlixGL.drawmodeof(img.sprite)

# Overridden Entity Getters/Setters
FlixGL.setvisibility(img::Image, visible::Bool) = setvisibility(img.sprite, visible)


###########
# Factories

mutable struct BackgroundImageFactory <: AbstractUIElementFactory
    image::Image2D
end
(factory::BackgroundImageFactory)(width::Integer, height::Integer, origin::Anchor) = Image(width, height, factory.image, origin)


##############
# Base methods

Base.show(io::IO, img::Image) = write(io, "Image($(img.width)×$(img.height), $(img.origin), $(length(img.listeners)) listeners)")

#########
# Globals

prog_image = nothing
