module FlixUI
using FlixGL
using FreeType
using StaticArrays
import FlixGL.LowLevel
export destroy, compile, compile!

const dir_assets  = "$(@__DIR__)/../assets"
const dir_shaders = "$dir_assets/shaders"
const Optional{T} = Union{Nothing, T}

include("./Errors.jl")
include("./EventDispatcher.jl")
include("./Fonts.jl")
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
