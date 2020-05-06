export InputSystem
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
"""
mutable struct InputSystem
    window::Window
    elements::Set{AbstractUIElement}
    listeners::Dict{Symbol, Vector}
    ismouseover::Bool
    scroll::Vector2{Float64}
    
    function InputSystem(wnd, elements, listeners, ismouseover, scroll)
        inst = new(wnd, elements, listeners, ismouseover, scroll)
        GLFW.SetKeyCallback(        wnd.handle, curry(InputSystemGLFWEvents.onkeyinput,    inst))
        GLFW.SetCharCallback(       wnd.handle, curry(InputSystemGLFWEvents.oncharinput,   inst))
        GLFW.SetCursorEnterCallback(wnd.handle, curry(InputSystemGLFWEvents.onmouseover,   inst))
        GLFW.SetMouseButtonCallback(wnd.handle, curry(InputSystemGLFWEvents.onmouseinput,  inst))
        GLFW.SetScrollCallback(     wnd.handle, curry(InputSystemGLFWEvents.onscrollinput, inst))
        inst
    end
end
InputSystem(wnd::Window) = InputSystem(wnd, Set(), Dict(), false, Vector2{Float64}(0, 0))


module InputSystemGLFWEvents
using GLFW
using FlixGL
using ..FlixUI

function onkeyinput(insys, _, _, scancode, action, _)
    if action == GLFW.PRESS
        emit(insys, :KeyPress, scancode)
    elseif action == GLFW.REPEAT
        emit(insys, :KeyRepeat, scancode)
    else
        emit(insys, :KeyRelease, scancode)
    end
end

function oncharinput(insys, _, char)
    emit(insys, :CharReceived, char)
end

function onmousemoveinput(insys, _, xpos, ypos)
    pos = insys.tmpmousestate.position = Vector2{Float64}(xpos, ypos)
    emit(insys, :MouseMove, pos)
end

function onmouseover(insys, _, entered)
    entered = insys.ismouseover = entered != 0
    if entered
        emit(insys, :MouseEnter)
    else
        emit(insys, :MouseLeave)
    end
end

function onmouseinput(insys, _, button, action, _)
    if action == GLFW.PRESS
        emit(insys, :MousePress,   MouseButton(Int(button)))
    else
        emit(insys, :MouseRelease, MouseButton(Int(button)))
    end
end

function onscrollinput(insys, _, xoffset, yoffset)
    scroll = insys.scroll = Vector2{Float64}(xoffset, yoffset)
    emit(insys, :Scroll, scroll)
    if scroll[1] != 0
        emit(insys, :ScrollX, scroll[1])
    elseif scroll[2] != 0
        emit(insys, :ScrollY, scroll[2])
    end
end
end # module InputSystemGLFWEvents

function register!(insys::InputSystem, elem)
    push!(insys.elements, elem)
    insys
end

function remove!(insys::InputSystem, elem)
    delete!(insys.elements, elem)
    insys
end

function tick!(insys::InputSystem, delta::Real)
    insys.scroll = Vector2{Float64}(0, 0)
    GLFW.PollEvents()
end

cursorvisibility(insys::InputSystem, mode::CursorMode) = GLFW.SetInputMode(insys.window, GLFW.CURSOR, mode == HiddenCursor ? GLFW.CURSOR_HIDDEN : mode == CapturedCursor ? GLFW.CURSOR_DISABLED : GLFW.CURSOR_NORMAL)
showcursor(insys::InputSystem)    = cursorvisibility(insys, NormalCursor)
hidecursor(insys::InputSystem)    = cursorvisibility(insys, HiddenCursor)
capturecursor(insys::InputSystem) = cursorvisibility(insys, CapturedCursor)

"""
Waits until the input system receives an input event. If asynchronous behavior is desired, use `tick!` instead.
"""
Base.wait(_::InputSystem) = GLFW.WaitEvents()
Base.timedwait(_::InputSystem, timeout::Real) = GLFW.WaitEventsTimeout(timeout)

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
