push!(LOAD_PATH, @__DIR__)

using FlixGL
using FlixUI

wnd = Window(title="FlixUI Fiddle", width=800, height=600, fullscreen=Windowed)
use(wnd)
initwindow()
uisys = UISystem(wnd)

world = World{Transform2D{Float64}}()

fnt  = font("./assets/fonts/NotoSans/NotoSans-Regular.ttf"; size=16)
btn1 = Button(load_image(PNGImageFormat, "./assets/textures/ButtonSample1.png"))
register!(uisys, btn1)
push!(world, btn1)
translate!(btn1, Vector2(50, 50))
rotate!(btn1, deg2rad(45))

hook!(btn1, :MouseEnter) do
    println("Mouse entered button")
end
hook!(btn1, :MouseLeave) do
    println("Mouse left button")
end

cam = Camera2D()
ntts = [btn1]

t0 = time()
while !wantsclose()
    global t0
    t1 = time()
    dt = t1 - t0
    t0 = t1
    
    tick!(uisys, dt)
    update(world)
    
    render_background(ForwardRenderPipeline)
    render(ForwardRenderPipeline, WorldRenderSpace, cam, ntts)
    flip()
end
