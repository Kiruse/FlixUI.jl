import VPECore: absolute, relative

cnt = SpanContainer(relative(1), relative(1))
push!(world, cnt)

lbl = Label("Resize window to test", fnt, width=600, height=40, halign=AlignCenter, valign=AlignMiddle)
slot!(cnt, lbl)
