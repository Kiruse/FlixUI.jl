@assert length(ARGS) > 0 "CMD argument: path to test required"

push!(LOAD_PATH, @__DIR__)

using VPECore
using FlixGL
using FlixUI
import VPECore: absolute, relative

const get2Drenderables = curry(getrenderables, AbstractEntity2D)

wnd = Window(title="FlixUI Test", width=800, height=600, fullscreen=Windowed)
use(wnd)
initwindow()
world = World{AbstractEntity2D}()
uisys = UISystem(wnd, world)
setinputmode!(uisys, UIInputMode)

fnt = font("./assets/fonts/NotoSans/NotoSans-Regular.ttf"; size=16)
cam = Camera2D()

include(ARGS[1])

frameloop() do dt, _
    tick!(world, dt)
    
    render_background(ForwardRenderPipeline)
    render(ForwardRenderPipeline, WorldRenderSpace, cam, get2Drenderables(world, UIEntity))
    flip()
    
    return !wantsclose()
end

close(uisys)
