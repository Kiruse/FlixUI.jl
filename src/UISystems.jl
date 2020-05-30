######################################################################
# UI System associated with a single window.
# Inspired by HTML/ECMAScript DOM structure & event bubbling.
# TODO: Determine hovered elements (sorted by z-index) and bubble events until either the end was reached or propagation stopped.
# TODO: Support gamepads.

export UISystem, uisystem
export InputMode, GameInputMode, UIInputMode
export PressState, Pressed, Released, Repeated
export CursorMode, NormalCursor, HiddenCursor, CapturedCursor
export MouseButton, LeftMouseButton, RightMouseButton, MiddleMouseButton, ForwardMouseButton, BackwardMouseButton, MouseButton6, MouseButton7, MouseButton8
export register!, remove!, focusedelement, focuselement!, setinputmode!, getinputmode
export cursorvisibility, showcursor, hidecursor, capturecursor
export getmousebutton
export postvanityevent
export keyname, getscancode

@enum InputMode GameInputMode UIInputMode
@enum PressState Pressed Released Repeated
@enum CursorMode NormalCursor HiddenCursor CapturedCursor
@enum MouseButton begin
    LeftMouseButton
    RightMouseButton
    MiddleMouseButton
    ForwardMouseButton
    BackwardMouseButton
    MouseButton6
    MouseButton7
    MouseButton8
end

"""
An input system to handle and broadcast input events. Implements `EventDispatcher`.

The following events exist:
 - :KeyPress, :KeyRepeat, :KeyRelease
 - :CharReceived
 - :MouseMove
 - :MouseEnter, :MouseLeave
 - :MousePress, :MouseRelease
 - :Scroll, :ScrollX, :ScrollY
 - :Focus, :Defocus

The :MouseMove, :MousePress, :MouseRelease, :MouseEnter, and :MouseLeave events propagate to elements underneath the cursor.

The :Focus and :Defocus events are only emitted on a UIElement, not on the UISystem/Window itself. It is tirggered when a
new item is set to be focused by the UISystem. Whereby :Focus is emitted on the newly focused element and :Defocus is emitted
on the element that was previously focused.

Note: When the mouse cursor is being captured, the mouse position is virtualized. In order to determine the offset, the
delta between current and last virtual mouse position must be calculated.
 """
mutable struct UISystem
    window::Window
    world::World
    inputmode::InputMode
    focuselement::Optional{AbstractUIComponent}
    elements::Vector{AbstractUIComponent}
    hoveredelements::Set{AbstractUIComponent}
    listeners::ListenersType
    ismouseover::Bool
    scroll::Vector2{Float64}
    
    function UISystem(wnd, world, inputmode, focuselement, elements, hoveredelements, listeners, ismouseover, scroll)
        inst = new(wnd, world, inputmode, focuselement, elements, hoveredelements, listeners, ismouseover, scroll)
        GLFW.SetCursorPosCallback(  wnd.handle, curry(UISystemEvents.onmousemoveinput, inst))
        GLFW.SetCursorEnterCallback(wnd.handle, curry(UISystemEvents.onmouseover,      inst))
        GLFW.SetKeyCallback(        wnd.handle, curry(UISystemEvents.onkeyinput,       inst))
        GLFW.SetCharCallback(       wnd.handle, curry(UISystemEvents.oncharinput,      inst))
        GLFW.SetMouseButtonCallback(wnd.handle, curry(UISystemEvents.onmouseinput,     inst))
        GLFW.SetScrollCallback(     wnd.handle, curry(UISystemEvents.onscrollinput,    inst))
        hook!(curry(UISystemEvents.onwindowresize,   inst), wnd, :WindowResize)
        hook!(curry(UISystemEvents.onelementadded,   inst), world, :RootAdded)
        hook!(curry(UISystemEvents.onelementremoved, inst), world, :RootRemoved)
        push!(world, inst)
        inst
    end
end
UISystem(wnd::Window, world::World) = UISystem(wnd, world, GameInputMode, nothing, Vector(), Set(), ListenersType(), false, Vector2{Float64}(0, 0))
uisystem(wnd::Window, world::World) = UISystem(wnd, world)
uisystem(fn, wnd::Window, world::World) = (uisys = UISystem(wnd, world); fn(uisys); close(wnd))

VPECore.eventlisteners(sys::UISystem) = sys.listeners


module UISystemEvents
using GLFW
using VPECore
using FlixGL
using ..FlixUI

function onkeyinput(uisys, _, _, scancode, action, _)
    if action == GLFW.PRESS
        keyevent = :KeyPress
    elseif action == GLFW.REPEAT
        keyevent = :KeyRepeat
    else
        keyevent = :KeyRelease
    end
    
    emit(uisys, keyevent, scancode)
    if uisys.inputmode == UIInputMode && uisys.focuselement !== nothing && wantskeyboardinput(uisys.focuselement)
        emit(uisys.focuselement, keyevent, scancode)
    end
end

function oncharinput(uisys, _, char)
    emit(uisys, :CharReceived, char)
    if uisys.inputmode == UIInputMode && uisys.focuselement !== nothing && wantstextinput(uisys.focuselement)
        emit(uisys.focuselement, :CharReceived, char)
    end
end

function onmousemoveinput(uisys, _, xpos, ypos)
    wndwidth, wndheight = size(activewindow())
    pos = Vector2{Float64}(xpos - wndwidth/2, -ypos + wndheight/2)
    
    oldhovered = uisys.hoveredelements
    newhovered = uisys.hoveredelements = Set{AbstractUIComponent}(filter(elem->ispointover(elem, pos), uisys.elements))
    
    emit(uisys, :MouseMove, pos)
    if uisys.inputmode == UIInputMode
        foreach(elem->emit(elem, :MouseMove, pos), uisys.hoveredelements)
        foreach(elem->emit(elem, :MouseLeave), filter!(elem->wantsmouseinput(elem), setdiff(oldhovered, newhovered)))
        foreach(elem->emit(elem, :MouseEnter), filter!(elem->wantsmouseinput(elem), setdiff(newhovered, oldhovered)))
    end
end

function onmouseover(uisys, _, entered)
    entered = uisys.ismouseover = entered != 0
    if entered
        emit(uisys, :MouseEnter)
    else
        emit(uisys, :MouseLeave)
    end
end

function onmouseinput(uisys, _, button, action, _)
    btn = MouseButton(Int(button))
    if action == GLFW.PRESS
        emit(uisys, :MousePress, btn)
        if uisys.inputmode == UIInputMode
            foreach(elem->emit(elem, :MousePress, btn), filter!(elem->wantsmouseinput(elem), uisys.hoveredelements))
        end
    else
        emit(uisys, :MouseRelease, btn)
        if uisys.inputmode == UIInputMode
            foreach(elem->emit(elem, :MouseRelease, btn), filter!(elem->wantsmouseinput(elem), uisys.hoveredelements))
        end
    end
end

function onscrollinput(uisys, _, xoffset, yoffset)
    scroll = uisys.scroll = Vector2{Float64}(xoffset, yoffset)
    emit(uisys, :Scroll, scroll)
    if scroll[1] != 0
        emit(uisys, :ScrollX, scroll[1])
    end
    if scroll[2] != 0
        emit(uisys, :ScrollY, scroll[2])
    end
    
    if uisys.inputmode == UIInputMode && uisys.focuselement !== nothing && wantsscrollinput(uisys.focuselement)
        emit(uisys.focuselement, :Scroll, scroll)
        if scroll[1] != 0
            emit(uisys.focuselement, :ScrollX, scroll[1])
        end
        if scroll[2] != 0
            emit(uisys.focuselement, :ScrollY, scroll[2])
        end
    end
end

function onelementadded(uisys, transform)
    elem = getcustomdata(AbstractUIComponent, transform)
    if elem !== nothing
        push!(uisys.elements, elem)
    end
end

function onelementremoved(uisys, transform)
    elem = getcustomdata(AbstractUIComponent, transform)
    if elem !== nothing
        delete!(uisys.elements, elem)
    end
end

function onwindowresize(uisys, _)
    foreach(FlixUI.onparentresized!, uisys.elements)
end

wantsmouseinput(   elem) = WantsMouseInput    ∈ uiinputconfig(elem)
wantskeyboardinput(elem) = WantsKeyboardInput ∈ uiinputconfig(elem)
wantstextinput(    elem) = WantsTextInput     ∈ uiinputconfig(elem)
wantsscrollinput(  elem) = WantsScrollInput   ∈ uiinputconfig(elem)
end # module UISystemEvents

focusedelement(uisys::UISystem) = uisys.focuselement
function focuselement!(uisys::UISystem, elem::Optional{AbstractUIComponent})
    if uisys.focuselement !== nothing
        emit(uisys.focuselement, :Defocus)
    end
    
    uisys.focuselement = elem
    
    if elem !== nothing
        emit(elem, :Focus)
    end
    
    elem
end


function VPECore.hook!(uisys::UISystem, world::World)
    uisys.world = world
    hook!(curry(UISystemEvents.onelementadded, uisys), world, :ElementAdded)
    hook!(curry(UISystemEvents.onelementremoved, uisys), world, :ElementRemoved)
    uisys
end

function VPECore.tick!(uisys::UISystem, dt::AbstractFloat)
    uisys.scroll = Vector2{Float64}(0, 0)
    GLFW.PollEvents()
end

function Base.close(uisys::UISystem)
    unhook!(uisys.window, :WindowResize, UISystemEvents.onwindowresize)
    unhook!(uisys.world,  :ElementAdded, UISystemEvents.onelementadded)
    unhook!(uisys.world,  :ElementRemoved, UISystemEvents.onelementremoved)
    uisys.listeners = ListenersType()
    uisys.focuselement = nothing
    uisys.hoveredelements = Set(AbstractUIComponent[])
    uisys.elements = AbstractUIComponent[]
    nothing
end

getinputmode(uisys::UISystem) = uisys.inputmode
setinputmode!(uisys::UISystem, mode::InputMode) = uisys.inputmode = mode

getcursorvisibility(uisys::UISystem) = GLFW.GetInputMode(uisys.window.handle, GLFW.CURSOR)
setcursorvisibility(uisys::UISystem, mode::CursorMode) = GLFW.SetInputMode(uisys.window.handle, GLFW.CURSOR, mode == HiddenCursor ? GLFW.CURSOR_HIDDEN : mode == CapturedCursor ? GLFW.CURSOR_DISABLED : GLFW.CURSOR_NORMAL)
showcursor(uisys::UISystem)    = setcursorvisibility(uisys, NormalCursor)
hidecursor(uisys::UISystem)    = setcursorvisibility(uisys, HiddenCursor)
capturecursor(uisys::UISystem) = setcursorvisibility(uisys, CapturedCursor)

"""
Waits until the input system receives an input event. If asynchronous behavior is desired, use `tick!` instead.
"""
Base.wait(_::UISystem) = GLFW.WaitEvents()
Base.timedwait(_::UISystem, timeout::Real) = GLFW.WaitEventsTimeout(timeout)

postvanityevent() = GLFW.PostEmptyEvent()


function keyname(scancode)
    GLFW.GetKeyName(scancode)
end

function labeledkey(keyname::Symbol)
    keyname = Symbol("KEY_$keyname")
    if hasproperty(GLFW, keyname)
        getproperty(GLFW, keyname)
    else
        nothing
    end
end

"""
Get the scancode of the given labeled button. This only works reliably for US layout keyboards.
As scancodes are platform-dependent but persistent, it is best to determine scancodes for platforms
supported out of the box. For other platforms, offering key rebinds is recommended.

Key names should be intuitive human readable labels found on a standard US keyboard, such as :F, :6 and
:F4. Other names such as :Space and :Tab exist. The numpad is addressed through the prefix "KP_".

Under the hood this function accesses GLFW's named keys - refer to https://www.glfw.org/docs/3.3/group__keys.html.
For convenience, capitalization does not matter and "GLFW_KEY_" is prepended automatically.
"""
function getscancode(keyname::Symbol)
    weirdcode = labeledkey(keyname)
    if weirdcode != nothing
        GLFW.GetKeyScancode(weirdcode)
    else
        nothing
    end
end
