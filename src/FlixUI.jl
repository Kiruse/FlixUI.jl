module FlixUI
# -- Base imports --
using GLFW
# -- STD imports --
using Printf
# -- VPE imports --
using VPECore
using FlixGL
using FreeType
using GetSetProp
# -- 3rd Party imports --
using StaticArrays
using BitFlags
# -- Submodule imports --
import FlixGL.LowLevel

# General purpose methods exports
export destroy, compile, compile!

const dir_assets  = "$(@__DIR__)/../assets"
const dir_shaders = "$dir_assets/shaders"
const Optional{T} = Union{Nothing, T}

include("./Errors.jl")
include("./Fonts.jl")
include("./UIAbstracts.jl")
include("./UIInputConfigs.jl")
include("./UISystems.jl")
include("./UIMimics.jl")
include("./UIElements.jl")

function __init__()
    global _ftlib
    ref = Ref{FT_Library}()
    err = FT_Init_FreeType(ref)
    @assert err == 0
    _ftlib = ref[]
end

function __exit__()
    global _ftlib
    err = FT_Done_FreeType(_ftlib)
    @assert err == 0
    _ftlib = nothing
end
atexit(__exit__)

ftlibrary() = _ftlib
_ftlib = nothing

end # module
