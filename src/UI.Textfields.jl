######################################################################
# Simple text input UI element with optional background.
# TODO: Caret position & rendering.
# TODO: Subword navigation

export Textfield

struct Textfield <: AbstractUIElement
    width::Integer
    height::Integer
    label::Label
    origin::Anchor
    transform::Transform2D
    listeners::ListenersType
    
    function Textfield(width, height, label, origin, transform, listeners)
        inst = new(width, height, label, origin, transform, listeners)
        transform.customdata = inst
        hook!(curry(textfield_receivechar, inst), inst, :CharReceived)
        hook!(curry(textfield_keypress,    inst), inst, :KeyPress)
        hook!(curry(textfield_keypress,    inst), inst, :KeyRepeat)
        inst
    end
end
function Textfield(width::Integer,
                   height::Integer,
                   labelfactory::ContainerLabelFactory;
                   origin::Anchor = CenterAnchor,
                   transform::Transform2D = Transform2D{Float64}()
                  )
    lbl = labelfactory(width, height, origin)::Label
    inst = Textfield(width, height, lbl, origin, transform, ListenersType())
    parent!(lbl, inst)
    inst
end
function Textfield(backgroundfactory::BackgroundImageFactory,
                   labelfactory::ContainerLabelFactory;
                   origin::Anchor = CenterAnchor,
                   transform::Transform2D = Transform2D{Float64}()
                  )
    width, height = size(backgroundfactory.image)
    lbl = labelfactory(width, height, origin)
    inst = Textfield(width, height, lbl, origin, transform, ListenersType())
    parent!(backgroundfactory(width, height, origin), inst)
    parent!(lbl, inst)
    inst
end
    
VPECore.eventlisteners(text::Textfield) = text.listeners
uiinputconfig(::Textfield) = WantsMouseInput + WantsKeyboardInput + WantsTextInput

function textfield_receivechar(textfield::Textfield, char::Char)
    textfield.label.text *= char
    compile!(textfield.label)
end
function textfield_keypress(textfield::Textfield, scancode::Integer)
    if scancode == 14
        textfield.label.text = textfield.label.text[1:length(textfield.label.text)-1]
        compile!(textfield.label)
    end
end


##############
# Base methods

Base.show(io::IO, txt::Textfield) = (write(io, "Textfield($(txt.width)×$(txt.height), $(txt.origin), "); show(io, txt.label); write(io, ")"))
