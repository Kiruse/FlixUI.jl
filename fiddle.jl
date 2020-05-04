push!(LOAD_PATH, @__DIR__)

using FlixGL
using FlixUI
using GLFW

wndargs = WindowCreationArgs()
wndargs.title = "FlixUI Fiddle"
wndargs.fullscreen = Windowed
wndargs.width  = 800
wndargs.height = 600
wnd = Window(wndargs)
use(wnd)
initwindow()

fnt  = font("./assets/fonts/NotoSans/NotoSans-Regular.ttf"; size=16)
txt1 = Label("Test 123\n456", fnt, align=AlignCenter)

cam = Camera2D()
ntts = [txt1]

while !wantsclose()
    pollevents()
    render(ForwardRenderPipeline, cam, ntts)
    flip()
end
