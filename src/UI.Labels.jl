######################################################################
# Integration of the FreeType abstraction layer with the Entity system.
# TODO: Anchor text to different locations

export Label

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
    if prog_label == nothing
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
    width::Optional{<:Integer}
    height::Optional{<:Integer}
    lineheightmult::Real
    halign::TextHorizontalAlignment
    valign::TextVerticalAlignment
    origin::Anchor
    transform::Transform2D
    material::LabelMaterial
    
    function Label(vao, font, text, width, height, lineheightmult, halign, valign, origin, transform, material)
        inst = new(vao, font, text, width, height, lineheightmult, halign, valign, origin, transform, material)
        transform.customdata = inst
        inst
    end
end
Label(font::Font, transform::Transform2D = Transform2D{Float64}()) = Label(LabelVAO(), font, "", nothing, nothing, 0, AlignLeft, AlignTop, CenterAnchor, transform, LabelMaterial())
function Label(text::AbstractString, font::Font;
               width::Optional{<:Integer} = nothing,
               height::Optional{<:Integer},
               lineheightmult::Real = 1.0,
               color::Color = White,
               halign::TextHorizontalAlignment = AlignLeft,
               valign::TextVerticalAlignment = AlignTop,
               origin::Anchor = CenterAnchor,
               transform::Transform2D = Transform2D{Float64}()
              )
    lbl = Label(font, transform)
    lbl.text           = text
    lbl.width          = width
    lbl.height         = height
    lbl.lineheightmult = lineheightmult
    lbl.halign         = halign
    lbl.valign         = valign
    lbl.origin         = origin
    lbl.material.color = color
    compile!(lbl)
end

FlixGL.countverts(::Label) = 4
FlixGL.drawmodeof(::Label) = LowLevel.TriangleFanDrawMode

function compile!(lbl::Label)
    img = compile(lbl.font, lbl.text, linewidth=lbl.width, lineheightmult=lbl.lineheightmult, align=lbl.halign)
    imgw, imgh = size(img)
    
    # Update vertex coordinates
    LowLevel.buffer_update(lbl.vao.vbo_coords, getlabelverts(lbl))
    LowLevel.buffer_update(lbl.vao.vbo_uvs,    getlabeluvs(lbl, imgw, imgh))
    
    # Update texture
    if lbl.material.tex != nothing
        destroy(lbl.material.tex)
    end
    lbl.material.tex = wrapping!(texture(img), ClampToBorderWrap, ClampToBorderWrap, border=Black)
    lbl
end

function getlabelverts(lbl::Label)
    if lbl.width != nothing && lbl.height != nothing
        width  = lbl.width
        height = lbl.height
    elseif lbl.width != nothing
        lines  = normlines(lbl.text)
        width  = lbl.width
        height = measure_textheight(lbl.font, length(lines); lineheightmult=lbl.lineheightmult)
    elseif lbl.height != nothing
        lines  = normlines(lbl.text)
        width  = measure_textwidth(lbl.font, lines)
        height = lbl.height
    else
        width, height = measure(lbl.font, lbl.text, lineheightmult=lbl.lineheightmult)
    end
    getanchoredorigin(width, height, lbl.origin)
end

function getlabeluvs(lbl::Label, textwidth::Real, textheight::Real)
    uvs = Float32[
        0, 0,
        1, 0,
        1, 1,
        0, 1
    ]
    
    if lbl.width != nothing
        ratio = lbl.width / textwidth
        
        if lbl.halign == AlignLeft
            uvs[3] = uvs[5] = ratio
        elseif lbl.halign == AlignCenter
            uvs[1] = uvs[7] = 0.5-ratio/2
            uvs[3] = uvs[5] = 0.5+ratio/2
        elseif lbl.halign == AlignRight
            uvs[1] = uvs[7] = 1-ratio
        end
    end
    
    if lbl.height != nothing
        ratio = lbl.height / textheight
        
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


# Globals

prog_label = nothing

# Constants

const unidLabelColor = UniformIdentifier("uniColor")
