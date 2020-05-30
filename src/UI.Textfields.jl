######################################################################
# Simple text input UI element with optional background.
# TODO: Caret position & rendering.
# TODO: Subword navigation

export Textfield

mutable struct Textfield <: AbstractUIElement
    width::Float64
    height::Float64
    origin::Anchor
    label::Optional{ContainerLabelMimic}
    background::Optional{AbstractBackgroundMimic}
    visible::Bool
    transform::Transform2D
    listeners::ListenersType
    
    function Textfield(width, height, origin, label, background, visible, transform, listeners)
        inst = new(width, height, origin, label, background, visible, transform, listeners)
        transform.customdata = inst
        hook!(curry(textfield_receivechar, inst), inst, :CharReceived)
        hook!(curry(textfield_keypress,    inst), inst, :KeyPress)
        hook!(curry(textfield_keypress,    inst), inst, :KeyRepeat)
        inst
    end
end
function Textfield(width::Real,
                   height::Real,
                   labelargs::ContainerLabelArgs;
                   origin::Anchor = CenterAnchor,
                   transform::Transform2D = Transform2D{Float64}()
                  )
    inst = Textfield(width, height, origin, nothing, nothing, true, transform, ListenersType())
    inst.label = ContainerLabelMimic(inst, labelargs)
    inst
end
function Textfield(width::Real,
                   height::Real,
                   bgargs::AbstractBackgroundArgs,
                   labelargs::ContainerLabelArgs,
                   origin::Anchor = CenterAnchor,
                   transform::Transform2D = Transform2D{Float64}()
                  )
    inst = Textfield(width, height, origin, nothing, nothing, true, transform, ListenersType())
    inst.background = containerbackground(inst, bgargs)
    inst.label = ContainerLabelMimic(inst, labelargs)
    inst
end
function Textfield(bgimage::Image2D,
                   labelargs::ContainerLabelArgs,
                   origin::Anchor = CenterAnchor,
                   transform::Transform2D = Transform2D{Float64}()
                  )
    Textfield(size(bgimage)..., BackgroundImageArgs(bgimage), labelargs, origin, anchor, transform)
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
