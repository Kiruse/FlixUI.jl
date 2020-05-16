push!(LOAD_PATH, @__DIR__)

using VPECore
using FlixGL
using FlixUI

wnd = Window(title="FlixUI Fiddle", width=800, height=600, fullscreen=Windowed)
use(wnd)
initwindow()
uisys = UISystem(wnd)
setinputmode!(uisys, UIInputMode)

world = World{Transform2D{Float64}}()
push!(world, uisys)

fnt  = font("./assets/fonts/NotoSans/NotoSans-Regular.ttf"; size=16)
btn1 = Button(BackgroundImageFactory(load_image(PNGImageFormat, "./assets/textures/ButtonSample1.png")),
              ContainerLabelFactory("Some Button", fnt, padding=3),
              origin=TopLeftAnchor)
translate!(btn1, (50, 50))
rotate!(btn1, deg2rad(45))
register!(uisys, btn1)
push!(world, btn1)

txt1 = Textfield(BackgroundImageFactory(load_image(PNGImageFormat, "./assets/textures/TextfieldBackground.png")),
                 ContainerLabelFactory("", fnt, padding=4, color=Black, halign=AlignLeft),
                 origin=RightAnchor)
register!(uisys, txt1)
push!(world, txt1)

hook!(txt1, :MousePress) do btn
    if btn ∈ (LeftMouseButton, RightMouseButton)
        focuselement!(uisys, txt1)
    end
end
hook!(txt1, :CharReceived) do char
    println(txt1.label.text)
end
hook!(txt1, :KeyPress) do scancode
    if scancode == 14
        println(txt1.label.text)
    end
end

cam = Camera2D()

frameloop() do dt
    tick!(world, dt)
    
    render_background(ForwardRenderPipeline)
    render(ForwardRenderPipeline, WorldRenderSpace, cam, getrenderables(AbstractEntity2D, world, UIEntity))
    flip()
    
    return !wantsclose()
end
