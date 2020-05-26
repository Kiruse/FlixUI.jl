push!(LOAD_PATH, @__DIR__)

using VPECore
using FlixGL
using FlixUI

const get2Drenderables = curry(getrenderables, AbstractEntity2D)

wnd = Window(title="FlixUI Fiddle", width=800, height=600, fullscreen=Windowed)
use(wnd)
initwindow()
uisys = UISystem(wnd)
setinputmode!(uisys, UIInputMode)

fnt  = font("./assets/fonts/NotoSans/NotoSans-Regular.ttf"; size=16)

world = World{Transform2D{Float64}}()
push!(world, uisys)

cam = Camera2D()

txtimg  = load_image(PNGImageFormat, "./assets/textures/TextfieldBackground.png")
txtsize = size(txtimg)
lblargs = ContainerLabelArguments(fnt, text="", color=Black, padding=3)
txt = Textfield(txtsize..., txtimg, lblargs)
push!(world, txt)
register!(uisys, txt)

hook!(txt, :MousePress) do btn
    if btn == LeftMouseButton
        focuselement!(uisys, txt)
    end
end

ttotal = 0.0
frameloop() do dt
    global ttotal
    ttotal += dt
    
    resize!(txt, (txtsize .+ txtsize .* 0.5sin(ttotal))...)
    
    tick!(world, dt)
    
    render_background(ForwardRenderPipeline)
    render(ForwardRenderPipeline, WorldRenderSpace, cam, get2Drenderables(world, UIEntity))
    flip()
    
    return !wantsclose()
end
