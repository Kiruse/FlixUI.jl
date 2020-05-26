export Image, BackgroundImageFactory

mutable struct Image <: AbstractUIElement
    width::Float64
    height::Float64
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

function Image(width::Real, height::Real, img, origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}())
    sprite = Sprite2D(floor(Int, width), floor(Int, height), texture(img), originoffset=anchor2offset(origin), static=false, transform=transform)
    inst = Image(width, height, origin, sprite, ListenersType())
    inst
end
function Image(img, origin::Anchor = CenterAnchor, transform::Transform2D = Transform2D{Float64}())
    width, height = size(img)
    Image(width, height, img, origin, transform)
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

mutable struct BackgroundImageMimic <: AbstractUIMimic{Image}
    mimicked::Image
    
    function BackgroundImageMimic(parent::AbstractUIElement, image::Image2D)
        inst = new(Image(size(parent)..., image))
        transformof(inst).customdata = inst
        parent!(inst, parent)
        update_transform!(inst)
        inst
    end
end

FlixGL.parent!(::BackgroundImageMimic, ::AbstractEntity) = error("Cannot parent a BackgroundImageMimic to a non-UI entity")
FlixGL.parent!(bgimg::BackgroundImageMimic, parent::AbstractUIElement) = parent!(transformof(bgimg), transformof(parent))
FlixGL.deparent!(::BackgroundImageMimic) = error("Cannot deparent a BackgroundImageMimic")
VPECore.eventlisteners(mimic::BackgroundImageMimic) = mimic.mimicked.listeners

# Simplified RelativeMimic which always spans the full size of and centers the image within the parent.
function onparentresized!(mimic::BackgroundImageMimic)
    img = mimicked(mimic)
    width, height = size(parentof(mimic))
    resize!(img, width, height)
    update_transform!(mimic)
    foreach(onparentresized!, childrenof(mimic))
end

function update_transform!(mimic::BackgroundImageMimic)
    aabb = bounds(parentof(mimic))
    transformof(mimic).location = Vector2(aabb.max[1] + aabb.min[1], aabb.max[2] + aabb.min[2]) ./ 2
    mimic
end

backgroundimage_centerlocation(parent::AbstractUIElement) = (aabb = bounds(parent); Vector2(aabb.max[1] - aabb.min[1], aabb.max[2] - aabb.min[2]))


##############
# Base methods

Base.show(io::IO, img::Image) = write(io, "Image($(img.width)×$(img.height), $(img.origin), $(length(img.listeners)) listeners)")
Base.size(mimic::BackgroundImageMimic) = size(mimic.mimicked)

#########
# Globals

prog_image = nothing
