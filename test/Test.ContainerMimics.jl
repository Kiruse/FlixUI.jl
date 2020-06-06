###
# Test depends on Button class for simplicity. If this text does not succeed, ensure Button test works first.
###

mutable struct ButtonResizeTicker
    btn::Button
    flopsize::NTuple{2, Int64}
    interval::Float64
    t_curr::Float64
end
ButtonResizeTicker(btn::Button, flopsize, interval::Real) = ButtonResizeTicker(btn, (flopsize[1], flopsize[2]), interval, 0)
function VPECore.tick!(ticker::ButtonResizeTicker, dt::AbstractFloat)
    ticker.t_curr += dt
    if ticker.t_curr >= ticker.interval
        ticker.t_curr -= ticker.interval
        flopsize = ticker.flopsize
        ticker.flopsize = size(ticker.btn)
        resize!(ticker.btn, flopsize...)
    end
end

bgargs1  = BackgroundImageArgs(load_image(PNGImageFormat, "./assets/textures/ButtonSample1.png"))
lblargs1 = ContainerLabelArgs(fnt, text="Button 1", padding=3, halign=AlignLeft)
btn1 = Button(200, 60, bgargs1, lblargs1)
push!(world, btn1)
push!(world, ButtonResizeTicker(btn1, (100, 30), 2))
translate!(btn1, (-150, 0))

bgargs2  = BackgroundColorArgs(ByteColor3(0x6a0dad))
lblargs2 = ContainerLabelArgs(fnt, text="Button 2", padding=3, halign=AlignRight)
btn2 = Button(200, 60, bgargs2, lblargs2)
push!(world, btn2)
push!(world, ButtonResizeTicker(btn2, (300, 90), 2.5))
translate!(btn2, (150, 0))
