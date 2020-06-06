export Image
export AbstractBackgroundMimic, AbstractBackgroundArgs
export BackgroundImageMimic, BackgroundImageArgs
export BackgroundColorMimic, BackgroundColorArgs
export containerbackground

mutable struct Image{T} <: AbstractUIElement
    width::T
    height::T
    origin::Anchor
    sprite::Sprite2D{T}
    listeners::ListenersType
end
FlixGL.entityclass(::Type{Image}) = UIEntity()

function Image(width::Real, height::Real, img, origin::Anchor = CenterAnchor, transform::Entity2DTransform{T} = defaulttransform()) where T
    sprite = Sprite2D(floor(Int, width), floor(Int, height), texture(img), originoffset=anchor2offset(origin), static=false, transform=transform)
    inst = Image{T}(width, height, origin, sprite, ListenersType())
    inst
end
Image(img, origin::Anchor = CenterAnchor, transform::Entity2DTransform = defaulttransform()) = Image(size(img)..., img, origin, transform)

# Overridden Entity Characteristics
FlixGL.wantsrender( img::Image) = FlixGL.wantsrender(img.sprite)
FlixGL.vertsof(     img::Image) = FlixGL.getanchoredrectcoords(img.width, img.height, img.origin)
FlixGL.countverts(  img::Image) = FlixGL.countverts(img.sprite)
FlixGL.vaoof(       img::Image) = FlixGL.vaoof(img.sprite)
FlixGL.materialof(  img::Image) = FlixGL.materialof(img.sprite)
FlixGL.drawmodeof(  img::Image) = FlixGL.drawmodeof(img.sprite)
VPECore.transformof(img::Image) = VPECore.transformof(img.sprite)

# Overridden Entity Getters/Setters
FlixGL.isvisible(img::Image) = isvisible(img.sprite)
FlixGL.setvisibility!(img::Image, visible::Bool) = setvisibility!(img.sprite, visible)

setuvs!(img::Mimicks, uvs::Rect{Float32}) = FlixGL.change_sprite_uvs(mimicked(img).sprite, uvs)

function Base.resize!(img::Image, width::Real, height::Real)
    img.width  = width
    img.height = height
    FlixGL.change_sprite_coords(img.sprite, (width, height), anchor2offset(img.origin))
    foreach(onparentresized!, childrenof(img))
    img
end

@generate_properties Image begin
    @set origin = (self.origin = value; resize!(self, size(self)...); value)
end


########
# Mimics

abstract type AbstractBackgroundMimic{T} <: AbstractUIMimic{Image} end
abstract type AbstractBackgroundArgs{T} end

mutable struct BackgroundImageArgs{T} <: AbstractBackgroundArgs{T}
    image::Image2D
end
BackgroundImageArgs(img::Image2D) = BackgroundImageArgs{transformparam(default_transform_type())}(img)
mutable struct BackgroundColorArgs{T} <: AbstractBackgroundArgs{T}
    color::AbstractColor
end
BackgroundColorArgs(color::AbstractColor) = BackgroundColorArgs{transformparam(default_transform_type())}(color)

mutable struct BackgroundImageMimic{T} <: AbstractBackgroundMimic{T}
    mimicked::Image{T}
    
    function BackgroundImageMimic{T}(parent::AbstractUIElement, image::Image2D) where T
        inst = new{T}(Image(size(parent)..., image))
        parent!(inst, parent)
        update_bgimg_transform!(inst)
        inst
    end
end
BackgroundImageMimic{T}(parent::AbstractUIElement, args::BackgroundImageArgs{T}) where T = BackgroundImageMimic{T}(parent, args.image)
BackgroundImageMimic(   parent::AbstractUIElement, args::BackgroundImageArgs{T}) where T = BackgroundImageMimic{T}(parent, args.image)

mutable struct BackgroundColorMimic{T} <: AbstractBackgroundMimic{T}
    mimicked::Image{T}
    
    function BackgroundColorMimic{T}(parent::AbstractUIElement, color::AbstractColor) where T
        color = convert(NormColor, color)
        img   = Image2D(fill(color, 2, 2))
        width, height = size(parent)
        inst = new{T}(Image(width, height, img))
        parent!(inst, parent)
        update_bgimg_transform!(inst)
        inst
    end
end
BackgroundColorMimic{T}(parent::AbstractUIElement, args::BackgroundColorArgs{T}) where T = BackgroundColorMimic{T}(parent, args.color)
BackgroundColorMimic(   parent::AbstractUIElement, args::BackgroundColorArgs{T}) where T = BackgroundColorMimic{T}(parent, args.image)

VPECore.parent!(::AbstractBackgroundMimic, ::AbstractEntity) = error("Cannot parent a background image mimic to a non-UI entity")
VPECore.parent!(bgimg::AbstractBackgroundMimic, parent::AbstractUIElement) = VPECore.do_parent!(bgimg, parent)
VPECore.deparent!(::AbstractBackgroundMimic) = error("Cannot deparent a background image mimic")
VPECore.eventlisteners(mimic::AbstractBackgroundMimic) = mimic.mimicked.listeners

# Simplified RelativeMimic which always spans the full size of and centers the image within the parent.
function onparentresized!(mimic::AbstractBackgroundMimic)
    img = mimicked(mimic)
    width, height = size(parentof(mimic))
    resize!(img, width, height)
    update_bgimg_transform!(mimic)
    foreach(onparentresized!, childrenof(mimic))
end

function update_bgimg_transform!(mimic::AbstractBackgroundMimic)
    aabb = bounds(parentof(mimic))
    transformof(mimic).location = Vector2(aabb.max[1] + aabb.min[1], aabb.max[2] + aabb.min[2]) ./ 2
    mimic
end

backgroundimage_centerlocation(parent::AbstractUIElement) = (aabb = bounds(parent); Vector2(aabb.max[1] - aabb.min[1], aabb.max[2] - aabb.min[2]))

containerbackground(::Type{T}, parent::AbstractUIElement, args::BackgroundImageArgs) where T = BackgroundImageMimic{T}(parent, args)
containerbackground(::Type{T}, parent::AbstractUIElement, args::BackgroundColorArgs) where T = BackgroundColorMimic{T}(parent, args)
containerbackground(::Type{T}, ::AbstractUIElement, ::Nothing) where T = nothing
containerbackground(parent::AbstractUIElement, args::AbstractBackgroundArgs{T}) where T = containerbackground(T, parent, args)


##############
# Base methods

Base.show(io::IO, img::Image) = write(io, "Image($(img.width)×$(img.height), $(img.origin), $(length(img.listeners)) listeners)")

#########
# Globals

prog_image = nothing
