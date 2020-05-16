push!(LOAD_PATH, @__DIR__)

using VPECore
using FlixGL
using FlixUI

wnd = Window(title="FlixUI Fiddle", width=800, height=600, fullscreen=Windowed)
use(wnd)
initwindow()
uisys = UISystem(wnd)

world = World{Transform2D{Float64}}()
push!(world, uisys)

fnt  = font("./assets/fonts/NotoSans/NotoSans-Regular.ttf"; size=16)
btn1 = Button(BackgroundImageFactory(load_image(PNGImageFormat, "./assets/textures/ButtonSample1.png")), ContainerLabelFactory("Some Button", fnt, padding=3), origin=TopLeftAnchor)
translate!(btn1, (50, 50))
rotate!(btn1, deg2rad(45))
register!(uisys, btn1)
push!(world, btn1)

hook!(btn1, :MouseEnter) do
    println("Mouse entered button")
end
hook!(btn1, :MouseLeave) do
    println("Mouse left button")
end

cam = Camera2D()

frameloop() do dt
    tick!(world, dt)
    
    render_background(ForwardRenderPipeline)
    render(ForwardRenderPipeline, WorldRenderSpace, cam, getrenderables(AbstractEntity2D, world, UIEntity))
    flip()
    
    return !wantsclose()
end
