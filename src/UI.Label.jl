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
    vbo_coords = LowLevel.buffer(zeros(Float32, 8), LowLevel.BufferUsage.Dynamic, LowLevel.BufferUsage.Draw)
    vbo_uvs    = LowLevel.buffer(Float32[0, 0, 1, 0, 1, 1, 0, 1], LowLevel.BufferUsage.Static, LowLevel.BufferUsage.Draw)
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
    lineheightmult::Real
    align::TextAlignment
    transform::Transform2D
    material::LabelMaterial
end
Label(font::Font) = Label(LabelVAO(), font, "", nothing, 0, AlignLeft, Transform2D(), LabelMaterial())
function Label(text::AbstractString, font::Font; width::Optional{<:Integer} = nothing, lineheightmult::Real = 1.0, color::Color = White, align::TextAlignment = AlignLeft)
    lbl = Label(font)
    lbl.text           = text
    lbl.width          = width
    lbl.lineheightmult = lineheightmult
    lbl.align          = align
    lbl.material.color = color
    compile!(lbl)
end

FlixGL.countverts(::Label) = 4
FlixGL.drawmodeof(::Label) = LowLevel.TriangleFanDrawMode

function compile!(lbl::Label)
    # Update vertex coordinates
    width, height = measure(lbl.font, lbl.text, lineheightmult=lbl.lineheightmult)
    halfwidth, halfheight = (width, height) ./ 2
    verts = Float32[
        -halfwidth, -halfheight,
         halfwidth, -halfheight,
         halfwidth,  halfheight,
        -halfwidth,  halfheight
    ]
    LowLevel.buffer_update(lbl.vao.vbo_coords, verts)
    
    # Update texture
    if lbl.material.tex != nothing
        destroy(lbl.material.tex)
    end
    lbl.material.tex = texture(compile(lbl.font, lbl.text, linewidth=lbl.width, lineheightmult=lbl.lineheightmult, align=lbl.align))
    lbl
end


# Globals

prog_label = nothing

# Constants

const unidLabelColor = UniformIdentifier("uniColor")
