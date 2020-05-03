export FontError

abstract type AbstractSimpleError <: Exception end

struct FontError <: Exception
    message::AbstractString
end
FontError() = "generic font error"

function Base.show(io::IO, err::T) where {T<:AbstractSimpleError}
    if length(err.message) == 0
        write(io, "Font Error")
    else
        write(io, "Font Error: $(err.message)")
    end
end
