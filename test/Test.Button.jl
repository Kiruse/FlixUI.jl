mutable struct TextResetter
    lbl::Label
    interval::Float64
    ttotal::Float64
    triggered::Bool
end
TextResetter(lbl::Label, interval::Real) = TextResetter(lbl, interval, 0, false)

function VPECore.tick!(ticker::TextResetter, dt::AbstractFloat)
    ticker.ttotal += dt
    if !ticker.triggered && ticker.ttotal >= ticker.interval
        ticker.triggered = true
        lbl.text = ""
        update!(lbl)
    end
end
function reset!(ticker::TextResetter)
    ticker.triggered = false
    ticker.ttotal = 0
end

bgargs  = BackgroundImageArgs(load_image(PNGImageFormat, "./assets/textures/ButtonSample1.png"))
lblargs = ContainerLabelArgs(fnt, text="Press me!", padding=3)
btn = Button(200, 60, bgargs, lblargs)
push!(world, btn)

lbl = Label("", fnt, width=600, height=40, halign=AlignCenter, valign=AlignMiddle)
push!(world, lbl)

translate!(lbl, (0, -70))

resetter = TextResetter(lbl, 1)
push!(world, resetter)

hook!(btn, :MousePress) do btn
    lbl.text = "Button pressed with $btn"
    update!(lbl)
    reset!(resetter)
end
