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

txtsize = (200, 60)
lblargs = ContainerLabelArguments(fnt, text="", color=Black, padding=3)
txt = Textfield(txtsize..., BackgroundColorArguments(0.9White3), lblargs)
push!(world, txt)
register!(uisys, txt)

hook!(txt, :MousePress) do btn
    if btn == LeftMouseButton
        focuselement!(uisys, txt)
    end
end

frameloop() do dt, ttotal
    resize!(txt, (txtsize .+ txtsize .* 0.5sin(ttotal))...)
    
    tick!(world, dt)
    
    render_background(ForwardRenderPipeline)
    render(ForwardRenderPipeline, WorldRenderSpace, cam, get2Drenderables(world, UIEntity))
    flip()
    
    return !wantsclose()
end
