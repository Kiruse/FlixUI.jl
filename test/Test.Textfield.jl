bgargs  = BackgroundColorArgs(0.95White)
lblargs = ContainerLabelArgs(fnt, padding=3, halign=AlignLeft, color=Black)
txt = Textfield(600, 40, bgargs, lblargs)
push!(world, txt)
focuselement!(uisys, txt)

lbl = Label("Please start typing.", fnt, width=600, height=40, halign=AlignCenter)
push!(world, lbl)
translate!(lbl, (0, -50))
