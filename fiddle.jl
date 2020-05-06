push!(LOAD_PATH, @__DIR__)

using FlixGL
using FlixUI

wndargs = WindowCreationArgs()
wndargs.title = "FlixUI Fiddle"
wndargs.fullscreen = Windowed
wndargs.width  = 800
wndargs.height = 600
wnd = Window(wndargs)
use(wnd)
initwindow()
uisys = UISystem(wnd)

fnt  = font("./assets/fonts/NotoSans/NotoSans-Regular.ttf"; size=16)
txt1 = Label("Test 123\n456", fnt, width=200, height=60, halign=AlignRight, valign=AlignBottom, origin=TopLeftAnchor)

cam = Camera2D()
ntts = [txt1]

t0 = time()
while !wantsclose()
    global t0
    t1 = time()
    dt = t1 - t0
    t0 = t1
    tick!(uisys, dt)
    render(ForwardRenderPipeline, cam, ntts)
    flip()
end
