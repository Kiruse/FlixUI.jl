import VPECore: absolute, relative

cnt = LayoutContainer(relative(1), relative(1), BackgroundColorArgs(ByteColor3(0x350557)))
push!(world, cnt)

img = load_image(PNGImageFormat, "./assets/textures/ButtonSample1.png")

btnStart   = Button(img, ContainerLabelArgs(fnt, text="Start",   color=White))
btnLoad    = Button(img, ContainerLabelArgs(fnt, text="Load",    color=White))
btnOptions = Button(img, ContainerLabelArgs(fnt, text="Options", color=White))
btnQuit    = Button(img, ContainerLabelArgs(fnt, text="Quit",    color=White))
slot!(cnt, :btnstart,   btnStart,   LeftAnchor, relative(0.2), absolute( 140))
slot!(cnt, :btnload,    btnLoad,    LeftAnchor, relative(0.2), absolute(  70))
slot!(cnt, :btnoptions, btnOptions, LeftAnchor, relative(0.2), absolute(   0))
slot!(cnt, :btnquot,    btnQuit,    LeftAnchor, relative(0.2), absolute( -70))
