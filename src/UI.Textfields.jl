######################################################################
# Simple text input UI element with optional background.
# TODO: Caret position & rendering.
# TODO: Subword navigation

export Textfield

mutable struct Textfield{T} <: AbstractUIElement
    width::T
    height::T
    origin::Anchor
    label::Optional{ContainerLabelMimic{T}}
    background::Optional{AbstractBackgroundMimic{T}}
    visible::Bool
    transform::Entity2DTransform{T}
    listeners::ListenersType
    
    function Textfield{T}(width::Real,
                          height::Real,
                          label::ContainerLabelArgs{T},
                          background::Optional{AbstractBackgroundArgs{T}},
                          origin::Anchor = CenterAnchor,
                          transform::Entity2DTransform{T} = defaulttransform()
                         ) where T
        inst = new{T}(width, height, origin, nothing, nothing, true, transform, ListenersType())
        inst.background = containerbackground(inst, background)
        inst.label = ContainerLabelMimic(inst, label)
        hook!(curry(textfield_receivechar, inst), inst, :CharReceived)
        hook!(curry(textfield_keypress,    inst), inst, :KeyPress)
        hook!(curry(textfield_keypress,    inst), inst, :KeyRepeat)
        inst
    end
end
function Textfield(width::Real,
                   height::Real,
                   labelargs::ContainerLabelArgs{T},
                   origin::Anchor = CenterAnchor,
                   transform::Entity2DTransform{T} = defaulttransform()
                  ) where T
    Textfield{T}(width, height, labelargs, nothing, origin, transform)
end
function Textfield(width::Real,
                   height::Real,
                   bgargs::AbstractBackgroundArgs{T},
                   labelargs::ContainerLabelArgs{T},
                   origin::Anchor = CenterAnchor,
                   transform::Entity2DTransform{T} = defaulttransform()
                  ) where T
    Textfield{T}(width, height, labelargs, bgargs, origin, transform)
end
function Textfield(bgimage::Image2D,
                   labelargs::ContainerLabelArgs{T},
                   origin::Anchor = CenterAnchor,
                   transform::Entity2DTransform{T} = defaulttransform()
                  ) where T
    Textfield(size(bgimage)..., BackgroundImageArgs{T}(bgimage), labelargs, origin, transform)
end

VPECore.eventlisteners(text::Textfield) = text.listeners
uiinputconfig(::Textfield) = WantsMouseInput + WantsKeyboardInput + WantsTextInput

function FlixGL.setvisibility!(txt::Textfield, visible::Bool)
    txt.visible = visible
    setvisibility!(txt.background, visible)
    setvisibility!(txt.label, visible)
end

function textfield_receivechar(textfield::Textfield, char::Char)
    textfield.label.text *= char
    update!(mimicked(textfield.label))
end
function textfield_keypress(textfield::Textfield, scancode::Integer)
    if scancode == 14
        textfield.label.text = textfield.label.text[1:length(textfield.label.text)-1]
        update!(mimicked(textfield.label))
    end
end


##############
# Base methods

Base.show(io::IO, txt::Textfield) = (write(io, "Textfield($(txt.width)×$(txt.height), $(txt.origin), "); show(io, txt.label); write(io, ")"))
function Base.resize!(txt::Textfield, width::Real, height::Real)
    txt.width  = width
    txt.height = height
    foreach(onparentresized!, childrenof(txt))
    txt
end
