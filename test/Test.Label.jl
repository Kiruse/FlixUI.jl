lbl1 = Label("Some Label!", fnt, width=200, height=60, halign=AlignCenter, valign=AlignMiddle)
lbl2 = Label("Some Label!", fnt, width=200, height=60, halign=AlignLeft,   valign=AlignMiddle)
lbl3 = Label("Some Label!", fnt, width=200, height=60, halign=AlignRight,  valign=AlignMiddle)
lbl4 = Label("Some Label!", fnt, width=200, height=60, halign=AlignCenter, valign=AlignBottom)
lbl5 = Label("Some Label!", fnt, width=200, height=60, halign=AlignLeft,   valign=AlignTop)
lbl6 = Label("Some Label!", fnt, width=200, height=60, halign=AlignRight,  valign=AlignBottom)

translate!(lbl1, (-100,    0))
translate!(lbl2, (-100,  100))
translate!(lbl3, (-100, -100))
translate!(lbl4, ( 100,    0))
translate!(lbl5, ( 100,  100))
translate!(lbl6, ( 100, -100))

push!(world, lbl1)
push!(world, lbl2)
push!(world, lbl3)
push!(world, lbl4)
push!(world, lbl5)
push!(world, lbl6)
