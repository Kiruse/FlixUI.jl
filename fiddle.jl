push!(LOAD_PATH, @__DIR__)

using VPECore
using FlixGL
using FlixUI
import VPECore: absolute, relative

const get2Drenderables = curry(getrenderables, AbstractEntity2D)

wnd = Window(title="FlixUI Fiddle", width=800, height=600, fullscreen=Windowed)
use(wnd)
initwindow()
world = World{default_transform_type()}()
uisys = UISystem(wnd, world)
setinputmode!(uisys, UIInputMode)

fnt = font("./assets/fonts/NotoSans/NotoSans-Regular.ttf"; size=16)
btnbg = load_image(PNGImageFormat, "./assets/textures/ButtonSample1.png")

cam = Camera2D()

cnt = LayoutContainer(relative(1), relative(1), BackgroundColorArgs(White*0.8))
push!(world, cnt)

btnStart = Button(btnbg, ContainerLabelArgs(fnt, text="Start", padding=3))
btnLoad  = Button(btnbg, ContainerLabelArgs(fnt, text="Load Game", padding=3))
btnOpts  = Button(btnbg, ContainerLabelArgs(fnt, text="Options", padding=3))
btnQuit  = Button(btnbg, ContainerLabelArgs(fnt, text="Quit", padding=3))
slot!(cnt, :btnStart,   btnStart, LeftAnchor, Vector2(50,  200))
slot!(cnt, :btnLoad,    btnLoad,  LeftAnchor, Vector2(50,  100))
slot!(cnt, :btnOptions, btnOpts,  LeftAnchor, Vector2(50,    0))
slot!(cnt, :btnQuit,    btnQuit,  LeftAnchor, Vector2(50, -100))

hook!(btnQuit, :MousePress) do btn
    if btn == LeftMouseButton
        wantsclose(true)
    end
end

# cnt = SpanContainer(relative(1), relative(1), RightAnchor)
# push!(world, cnt)
# translate!(cnt, (400, 0))

# img = Image(Image2D([Cyan Cyan; Cyan Cyan]))
# slot!(cnt, img)

frameloop() do dt, ttotal
    tick!(world, dt)
    
    render_background(ForwardRenderPipeline)
    render(ForwardRenderPipeline, WorldRenderSpace, cam, get2Drenderables(world, UIEntity))
    flip()
    
    return !wantsclose()
end

close(uisys)
