export FontError

abstract type AbstractFlixUIError <: Exception end
abstract type AbstractSimpleError <: AbstractFlixUIError end

struct FontError <: AbstractSimpleError
    message::AbstractString
end
FontError() = "generic font error"

function Base.show(io::IO, err::AbstractSimpleError)
    if length(err.message) == 0
        write(io, "Font Error")
    else
        write(io, "Font Error: $(err.message)")
    end
end
