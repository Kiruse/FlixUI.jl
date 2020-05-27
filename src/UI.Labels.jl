######################################################################
# Integration of the FreeType abstraction layer with the Entity system.
# TODO: Anchor text to different locations

export Label, ContainerLabelMimic, ContainerLabelArguments

struct LabelVAO <: AbstractVertexArrayData
    internal::LowLevel.VertexArray
    vbo_coords::LowLevel.PrimitiveArrayBuffer{Float32}
    vbo_uvs::LowLevel.PrimitiveArrayBuffer{Float32}
end
function LabelVAO()
    internal = LowLevel.vertexarray()
    vbo_coords = LowLevel.buffer(zeros(Float32, 8),               LowLevel.BufferUsage.Dynamic, LowLevel.BufferUsage.Draw)
    vbo_uvs    = LowLevel.buffer(Float32[0, 0, 1, 0, 1, 1, 0, 1], LowLevel.BufferUsage.Dynamic, LowLevel.BufferUsage.Draw)
    bind(internal, vbo_coords, 0, 2)
    bind(internal, vbo_uvs,    1, 2)
    LabelVAO(internal, vbo_coords, vbo_uvs)
end

function FlixGL.destroy(vao::LabelVAO)
    LowLevel.destroy(vao.internal)
    LowLevel.destroy(vao.vbo_coords)
    LowLevel.destroy(vao.vbo_uvs)
end

mutable struct LabelMaterial <: AbstractMaterial
    tex::Optional{Texture2D}
    color::NormColor
end
LabelMaterial() = LabelMaterial(nothing, White)

function FlixGL.programof(::Type{LabelMaterial})
    global prog_label
    if prog_label === nothing
        prog_label = LowLevel.program(LowLevel.shader(LowLevel.VertexShader, "$dir_shaders/label-bw.vertex.glsl"), LowLevel.shader(LowLevel.FragmentShader, "$dir_shaders/label-bw.fragment.glsl"))
    end
    prog_label
end

function FlixGL.use(mat::LabelMaterial)
    LowLevel.use(FlixGL.programof(mat))
    LowLevel.use(mat.tex.internal)
    LowLevel.uniform(resolve!(unidLabelColor, mat), collect(mat.color)...)
end

mutable struct Label <: AbstractUIElement
    vao::LabelVAO
    font::Font
    text::AbstractString
    realsize::Vector2{Float64}
    imgsize::Vector2{Int64}
    wantsize::Vector2{Union{Float64, AutoSize}}
    lineheightmult::Float64
    halign::TextHorizontalAlignment
    valign::TextVerticalAlignment
    origin::Anchor
    visible::Bool
    transform::Transform2D
    material::LabelMaterial
    
    function Label(vao, font, text, realsize, imgsize, wantsize, lineheightmult, halign, valign, origin, visible, transform, material)
        inst = new(vao, font, text, realsize, imgsize, wantsize, lineheightmult, halign, valign, origin, visible, transform, material)
        transform.customdata = inst
        inst
    end
end
Label(font::Font, transform::Transform2D = Transform2D{Float64}()) = Label(LabelVAO(), font, "", Vector2(0, 0), Vector2(0, 0), Vector2(autosize, autosize), 0, AlignLeft, AlignTop, CenterAnchor, false, transform, LabelMaterial())
function Label(text::AbstractString, font::Font;
               width::Union{<:Real, AutoSize} = autosize,
               height::Union{<:Real, AutoSize} = autosize,
               lineheightmult::Real = 1.0,
               color::Color = White,
               halign::TextHorizontalAlignment = AlignLeft,
               valign::TextVerticalAlignment = AlignTop,
               origin::Anchor = CenterAnchor,
               transform::Transform2D = Transform2D{Float64}()
              )
    lbl = Label(font, transform)
    lbl.text           = text
    lbl.realsize       = Vector2(0, 0)
    lbl.imgsize        = Vector2(0, 0)
    lbl.wantsize       = Vector2(width, height)
    lbl.lineheightmult = lineheightmult
    lbl.halign         = halign
    lbl.valign         = valign
    lbl.origin         = origin
    lbl.visible        = true
    lbl.material.color = color
    update!(lbl)
end

FlixGL.wantsrender(lbl::Label) = lbl.visible
FlixGL.countverts(::Label) = 4
FlixGL.drawmodeof(::Label) = LowLevel.TriangleFanDrawMode

function update!(lbl::Label)
    update_texture!(lbl)
    update_verts!(lbl)
    update_uvs!(lbl)
end

function update_texture!(lbl::Label)
    img = compile(lbl.font, lbl.text, lineheightmult=lbl.lineheightmult, align=lbl.halign)
    imgw, imgh  = size(img)
    lbl.imgsize = Vector2(imgw, imgh)
    
    realwidth  = lbl.wantsize[1] == autosize ? imgw : lbl.wantsize[1]
    realheight = lbl.wantsize[2] == autosize ? imgh : lbl.wantsize[2]
    lbl.realsize = Vector2(realwidth, realheight)
    
    # Update texture
    if lbl.material.tex !== nothing
        FlixGL.destroy(lbl.material.tex)
    end
    lbl.material.tex = wrapping!(texture(img), ClampToBorderWrap, ClampToBorderWrap, border=Black)
    lbl
end

function update_verts!(lbl::Label)
    LowLevel.buffer_update(lbl.vao.vbo_coords, getlabelverts(lbl))
    lbl
end

function update_uvs!(lbl::Label)
    imgw, imgh = lbl.imgsize
    LowLevel.buffer_update(lbl.vao.vbo_uvs, getlabeluvs(lbl, imgw, imgh))
    lbl
end

function getlabelverts(lbl::Label)
    width, height = lbl.wantsize
    
    if width == autosize && height == autosize
        width, height = measure(lbl.font, lbl.text, lineheightmult=lbl.lineheightmult)
    elseif width == autosize
        lines  = normlines(lbl.text)
        height = measure_textheight(lbl.font, length(lines); lineheightmult=lbl.lineheightmult)
    elseif height == autosize
        lines  = normlines(lbl.text)
        width  = measure_textwidth(lbl.font, lines)
    end
    getanchoredrectcoords(width, height, lbl.origin)
end

function getlabeluvs(lbl::Label, textwidth::Real, textheight::Real)
    uvs = Float32[
        0, 0,
        1, 0,
        1, 1,
        0, 1
    ]
    
    if lbl.wantsize[1] !== autosize
        ratio = lbl.wantsize[1] / textwidth
        
        if lbl.halign == AlignLeft
            uvs[3] = uvs[5] = ratio
        elseif lbl.halign == AlignCenter
            uvs[1] = uvs[7] = 0.5-ratio/2
            uvs[3] = uvs[5] = 0.5+ratio/2
        elseif lbl.halign == AlignRight
            uvs[1] = uvs[7] = 1-ratio
        end
    end
    
    if lbl.wantsize[2] !== autosize
        ratio = lbl.wantsize[2] / textheight
        
        if lbl.valign == AlignTop
            uvs[2] = uvs[4] = 1-ratio
        elseif lbl.valign == AlignMiddle
            uvs[2] = uvs[4] = 0.5-ratio/2
            uvs[6] = uvs[8] = 0.5+ratio/2
        elseif lbl.valign == AlignBottom
            uvs[6] = uvs[8] = ratio
        end
    end
    
    uvs
end


@generate_properties Label begin
    @get color = self.material.color
    @set color = self.material.color = value
end


########
# Mimics

mutable struct ContainerLabelArguments
    text::AbstractString
    font::Font
    padding::NTuple{4, Int64}
    color::Color
    lineheightmult::Float64
    halign::TextHorizontalAlignment
    valign::TextVerticalAlignment
    
    function ContainerLabelArguments(label::AbstractString, font::Font, padding, color::Color, lineheightmult::Real, halign::TextHorizontalAlignment, valign::TextVerticalAlignment)
        new(label, font, normalize_padding(padding), color, lineheightmult, halign, valign)
    end
end
function ContainerLabelArguments(font::Font;
                                 text::AbstractString = "",
                                 padding = 0,
                                 color::Color = White,
                                 lineheightmult::Real = 1,
                                 halign::TextHorizontalAlignment = AlignCenter,
                                 valign::TextVerticalAlignment = AlignMiddle,
                                )
    ContainerLabelArguments(text, font, padding, color, lineheightmult, halign, valign)
end

@generate_properties ContainerLabelArguments begin
    @set padding = normalize_padding(value)
end


"""A mimic labelling a container with various settings concerning its relative size."""
mutable struct ContainerLabelMimic <: AbstractUIMimic{Label}
    mimicked::Label
    padding::NTuple{4, Int64}
    
    function ContainerLabelMimic(parent::AbstractUIElement, args::ContainerLabelArguments)
        width, height = compute_size(parent, args.padding)
        lbl = Label(args.font)
        lbl.text = args.text
        lbl.wantsize = Vector2{Union{Float64, AutoSize}}(width == autosize ? autosize : Float64(width), height == autosize ? autosize : Float64(height))
        lbl.lineheightmult = args.lineheightmult
        lbl.material.color = args.color
        lbl.lineheightmult = args.lineheightmult
        lbl.halign = args.halign
        lbl.valign = args.valign
        lbl.visible = true
        
        inst = new(lbl, normalize_padding(args.padding))
        parent!(inst, parent)
        update_transform!(inst)
        transformof(inst).customdata = inst
        update!(lbl)
        inst
    end
end

FlixGL.parent!(::ContainerLabelMimic, ::AbstractEntity) = error("Cannot parent a ContainerLabelMimic to a non-UI entity")
FlixGL.parent!(mimic::ContainerLabelMimic, parent::AbstractUIComponent) = parent!(transformof(mimic), transformof(parent))
FlixGL.deparent!(::ContainerLabelMimic) = error("Cannot deparent a ContainerLabelMimic")


function onparentresized!(mimic::ContainerLabelMimic)
    update_size!(mimic)
    foreach(onparentresized!, childrenof(mimic))
end

function update_size!(mimic::ContainerLabelMimic)
    lbl = mimic.mimicked
    width, height = compute_size(parentof(lbl), mimic.padding)
    lbl.wantsize  = Vector2{Union{Float64, AutoSize}}(width, height)
    update!(lbl)
    update_transform!(mimic)
    mimic
end

function update_transform!(mimic::ContainerLabelMimic)
    aabb = bounds(parentof(mimic))
    offsetx = (aabb.max[1] + aabb.min[1]) / 2
    offsety = (aabb.max[2] + aabb.min[2]) / 2
    transformof(mimic).location = Vector2(offsetx, offsety)
    mimic
end

function compute_size(parent::AbstractUIComponent, padding)
    parentw, parenth = size(parent)
    width  = parentw - padding[1] - padding[4]
    height = parenth - padding[2] - padding[3]
    width, height
end

@generate_properties ContainerLabelMimic begin
    @set padding = normalize_padding(value)
    
    @set color = self.mimicked.material.color = value
    @get color = self.mimicked.material.color
    
    @get font = self.mimicked.font
    @set font = self.mimicked.font = value
    
    @get text = self.mimicked.text
    @set text = self.mimicked.text = value
    
    @get realsize = self.mimicked.realsize
    
    @get halign = self.mimicked.halign
    @set halign = self.mimicked.halign = value
    
    @get valign = self.mimicked.valign
    @set valign = self.mimicked.valign = value
    
    @get lineheightmult = self.mimicked.lineheightmult
    @set lingheightmult = self.mimicked.lineheightmult = value
end


##############
# Base methods

Base.size(lbl::Label) = (lbl.realsize[1], lbl.realsize[2])
function Base.resize!(lbl::Label, width::Real, height::Real)
    lbl.wantsize = Vector2{Union{Float64, AutoSize}}(width, height)
    update_verts!(lbl)
    update_uvs!(lbl)
    foreach(onparentresized!, childrenof(lbl))
    lbl
end

# TODO: Get font name?
Base.show(io::IO, lbl::Label) = write(io, "Label(<some font>, $(sizestring(lbl.realsize[1], lbl.realsize[2])), $(lbl.lineheightmult)× line height, $(lbl.halign), $(lbl.valign), $(lbl.origin), $(lblvisibilitystr(lbl)))")

function lblvisibilitystr(lbl::Label)
    if lbl.visible
        "visible"
    else
        "hidden"
    end
end

#########
# Globals

prog_label = nothing

# Constants

const unidLabelColor = UniformIdentifier("uniColor")
