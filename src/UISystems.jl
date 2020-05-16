######################################################################
# UI System associated with a single window.
# Inspired by HTML/ECMAScript DOM structure & event bubbling.
# TODO: Determine hovered elements (sorted by z-index) and bubble events until either the end was reached or propagation stopped.
# TODO: Support gamepads.

export UISystem
export PressState, Pressed, Released, Repeated
export CursorMode, NormalCursor, HiddenCursor, CapturedCursor
export MouseButton, LeftMouseButton, RightMouseButton, MiddleMouseButton, ForwardMouseButton, BackwardMouseButton, MouseButton6, MouseButton7, MouseButton8
export register!, remove!
export cursorvisibility, showcursor, hidecursor, capturecursor
export getmousebutton
export postvanityevent
export keyname, getscancode

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

The :MouseMove, :MousePress, :MouseRelease, :MouseEnter, and :MouseLeave events propagate to elements underneath the cursor.

Note: When the mouse cursor is being captured, the mouse position is virtualized. In order to determine the offset, the
delta between current and last virtual mouse position must be calculated.
 """
mutable struct UISystem
    window::Window
    elements::Vector{AbstractUIElement}
    hoveredelements::Set{AbstractUIElement}
    listeners::ListenersType
    ismouseover::Bool
    scroll::Vector2{Float64}
    
    function UISystem(wnd, elements, hoveredelements, listeners, ismouseover, scroll)
        inst = new(wnd, elements, hoveredelements, listeners, ismouseover, scroll)
        GLFW.SetCursorPosCallback(  wnd.handle, curry(UISystemGLFWEvents.onmousemoveinput, inst))
        GLFW.SetCursorEnterCallback(wnd.handle, curry(UISystemGLFWEvents.onmouseover,      inst))
        GLFW.SetKeyCallback(        wnd.handle, curry(UISystemGLFWEvents.onkeyinput,       inst))
        GLFW.SetCharCallback(       wnd.handle, curry(UISystemGLFWEvents.oncharinput,      inst))
        GLFW.SetMouseButtonCallback(wnd.handle, curry(UISystemGLFWEvents.onmouseinput,     inst))
        GLFW.SetScrollCallback(     wnd.handle, curry(UISystemGLFWEvents.onscrollinput,    inst))
        inst
    end
end
UISystem(wnd::Window) = UISystem(wnd, Vector(), Set(), ListenersType(), false, Vector2{Float64}(0, 0))

VPECore.eventlisteners(sys::UISystem) = sys.listeners


module UISystemGLFWEvents
using GLFW
using VPECore
using FlixGL
using ..FlixUI

function onkeyinput(uisys, _, _, scancode, action, _)
    if action == GLFW.PRESS
        emit(uisys, :KeyPress, scancode)
    elseif action == GLFW.REPEAT
        emit(uisys, :KeyRepeat, scancode)
    else
        emit(uisys, :KeyRelease, scancode)
    end
end

function oncharinput(uisys, _, char)
    emit(uisys, :CharReceived, char)
end

function onmousemoveinput(uisys, _, xpos, ypos)
    wndwidth, wndheight = size(activewindow())
    pos = Vector2{Float64}(xpos - wndwidth/2, -ypos + wndheight/2)
    
    oldhovered = uisys.hoveredelements
    newhovered = uisys.hoveredelements = Set{AbstractUIElement}(filter(elem->ispointover(elem, pos), uisys.elements))
    
    emit(uisys, :MouseMove, pos)
    foreach(elem->emit(elem, :MouseMove, pos), uisys.hoveredelements)
    foreach(elem->emit(elem, :MouseLeave), setdiff(oldhovered, newhovered))
    foreach(elem->emit(elem, :MouseEnter), setdiff(newhovered, oldhovered))
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
        foreach(elem->emit(elem, :MousePress, btn), uisys.hoveredelements)
    else
        emit(uisys, :MouseRelease, btn)
        foreach(elem->emit(elem, :MouseRelease, btn), uisys.hoveredelements)
    end
end

function onscrollinput(uisys, _, xoffset, yoffset)
    scroll = uisys.scroll = Vector2{Float64}(xoffset, yoffset)
    emit(uisys, :Scroll, scroll)
    if scroll[1] != 0
        emit(uisys, :ScrollX, scroll[1])
    elseif scroll[2] != 0
        emit(uisys, :ScrollY, scroll[2])
    end
end
end # module UISystemGLFWEvents

function register!(uisys::UISystem, elem)
    push!(uisys.elements, elem)
    uisys
end

function remove!(uisys::UISystem, elem)
    delete!(uisys.elements, elem)
    uisys
end

function FlixUI.tick!(uisys::UISystem, dt::AbstractFloat)
    uisys.scroll = Vector2{Float64}(0, 0)
    GLFW.PollEvents()
end

cursorvisibility(uisys::UISystem, mode::CursorMode) = GLFW.SetInputMode(uisys.window.handle, GLFW.CURSOR, mode == HiddenCursor ? GLFW.CURSOR_HIDDEN : mode == CapturedCursor ? GLFW.CURSOR_DISABLED : GLFW.CURSOR_NORMAL)
showcursor(uisys::UISystem)    = cursorvisibility(uisys, NormalCursor)
hidecursor(uisys::UISystem)    = cursorvisibility(uisys, HiddenCursor)
capturecursor(uisys::UISystem) = cursorvisibility(uisys, CapturedCursor)

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
