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

fnt = font("./assets/fonts/NotoSans/NotoSans-Regular.ttf"; size=16)

img = compile(fnt, "Test 123")
width, height = size(img)
txt1 = Sprite2D(width, height, texture(img))

cam = Camera2D()
ntts = [txt1]

while !GLFW.WindowShouldClose(wnd.handle)
    pollevents()
    render(ForwardRenderPipeline, cam, ntts)
    flip(wnd)
end
