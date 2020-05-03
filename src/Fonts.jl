######################################################################
# Generic Font and FontAtlas structs and methods.
# Also provides various methods for using fonts.
# TODO: Support for vertical fonts (e.g. Japanese as found in print media).

export Font, FontCache, FontGlyph
export font, setfontsize!, getfontsize, setlineheight!, getlineheight, measure, getglyph
export preloadchars, preload_roman_chars, preload_punctuation, preload_arabic_numbers
export clearcache!, uncache!

mutable struct FontGlyph
    img::Image2D
    advance::Vector2{Int64}
    bearing::Vector2{Int64}
    ts_lastuse::Float64
end
FontGlyph(img::FlixGL.Image2D) = FontGlyph(img, Vector2{Int64}(0, 0), Vector2{Int64}(0, 0), time())

mutable struct FontCache
    glyphs::Dict{Char, FontGlyph}
end
FontCache() = FontCache(Dict())

mutable struct Font
    handle::FT_Face
    size::UInt8        # not in pixels
    lineheight::UInt16 # Distance between lines
    baseline::UInt16   # Offset from top-left corner to baseline
    ascender::Int      # Distance from baseline to top edge of all glyphs
    descender::Int     # Distance from baseline to bottom edge of all glyphs
    caches::Dict{UInt8, FontCache}
end
Font(handle::FT_Face) = Font(handle, 0, 0, 0, 0, 0, Dict())


function font(path::String, idx::Integer = 1; size::Integer = 0)
    ref = Ref{FT_Face}(C_NULL)
    err = FT_New_Face(ftlibrary(), path, idx-1, ref)
    if err != 0 throw(FontError("error code $err")) end
    fnt = Font(ref[])
    
    if size != 0
        @assert size > 0
        setfontsize!(fnt, size)
    end
    fnt
end

function destroy(font::Font)
    FT_Done_Face(font.handle)
end

function setfontsize!(font::Font, size::Integer)
    font.size = size
    
    # Get DPI. If Window is not in fullscreen, assume DPI of primary monitor.
    monitor = getmonitor(activewindow())
    if monitor == nothing monitor = Monitor(1) end
    dpih, dpiv = getdpi(monitor)
    
    err = FT_Set_Char_Size(font.handle, 0, size << 6, dpih, dpiv)
    if err != 0 throw(FontError("error code $err")) end
    
    ftfont = unsafe_load(font.handle)
    ftsize = unsafe_load(ftfont.size)
    font.lineheight = ftsize.metrics.height >> 6
    font.ascender   = ftfont.bbox.yMax >> 6
    font.descender  = ftfont.bbox.yMin >> 6
    font.baseline   = font.ascender + 1
    
    font
end
getfontsize(font::Font) = font.size


function preloadchars(font::Font, chars::AbstractString)
    for char ∈ chars
        getglyph(font, char)
    end
end
preload_roman_chars(font::Font) = preloadchars(font, "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz")
preload_punctuation(font::Font) = preloadchars(font, ".,;:'\"!?-()[]<>")
preload_arabic_numbers(font::Font) = preloadchars(font, "0123456789")


"""
Measures dimensions of the provided text. If word wrapping is desired, apply `wordwrap` function before calling `measure`.

`lineheight` is a factor by which to multiply the regular
"""
function measure(font::Font, text::AbstractString; lineheight::Real = 1)
    if length(strip(text)) == 0 return (0, 0) end
    
    lineheight = round(Int, lineheight * font.lineheight)
    
    # Normalize newlines
    text  = replace(text, r"\r\n|\n\r" => "\n")
    lines = remove_trailing_newlines!(split(text, "\n"))
    
    width  = 0
    height = (length(lines)-1) * lineheight  # Last line uses different height
    height += font.ascender - font.descender # Last line uses global glyph height to ensure it can hold any glyph
    
    for line ∈ lines
        linewidth = 0
        
        for char ∈ line
            glyph = getglyph(font, char)
            linewidth += xcoord(glyph.advance)
        end
        
        width = max(width, linewidth)
    end
    
    (width, height)
end

function findcolortype(font::Font, text::AbstractString)
    reduce(promote_type, (getcolortype(getglyph(font, char)) for char ∈ text))
end

getcolortype(glyph::FontGlyph) = extract_color_type(glyph.img)
function getcolortype(ftpixelmode::UInt8)
    if ftpixelmode == FT_PIXEL_MODE_MONO || ftpixelmode == FT_PIXEL_MODE_GRAY
        NormGrayscale
    # elseif ftpixelmode == FT_PIXEL_MODE_GRAY2
    #     GrayscaleColor{UInt16}
    # elseif ftpixelmode == FT_PIXEL_MODE_GRAY4
    #     GrayscaleColor{UInt32}
    elseif ftpixelmode ∈ (FT_PIXEL_MODE_LCD, FT_PIXEL_MODE_LCD_V)
        NormColor3
    elseif ftpixelmode == FT_PIXEL_MODE_BGRA
        NormColor
    else
        throw(FontError("Unknown or unsupported pixel mode $ftpixelmode"))
    end
end

function compile(font::Font, text::AbstractString; lineheight::AbstractFloat = 1.0)
    width, height = measure(font, text, lineheight=lineheight)
    pixels = zeros(findcolortype(font, text), height, width)
    
    text  = replace(text, r"\r\n|\n\r" => "\n")
    lines = remove_trailing_newlines!(split(text, "\n"))
    
    # TODO: Bearing.X can be negative - adjust for this on first characters of each line
    
    pen = MVector(1, height - font.baseline) # 1-based index
    for line ∈ lines
        for char ∈ text
            glyph = getglyph(font, char)
            pasteglyph!(pixels, glyph, pen)
            pen += glyph.advance
        end
        pen[1]  = 1
        pen[2] -= lineheight
    end
    
    Image2D(pixels)
end

function pasteglyph!(pxs::Array{<:AbstractColor, 2}, glyph::FontGlyph, pen)
    cols, rows = size(glyph)
    xstart, yend = pen + glyph.bearing
    xend   = xstart + cols
    ystart = yend - rows
    pxs[ystart:yend-1, xstart:xend-1] .= pixels(glyph.img)
    pxs
end

function getglyph(font::Font, char::Char)
    cache = currentcache!(font)
    if char ∈ cache
        return cache.glyphs[char]
    end
    
    err = FT_Load_Char(font.handle, codepoint(char), FT_LOAD_RENDER)
    if err != 0
        throw(FontError("error code $err"))
    end
    
    ftface  = unsafe_load(font.handle)
    ftglyph = unsafe_load(ftface.glyph)
    glyph = FontGlyph(extractglyphimage(ftglyph.bitmap))
    glyph.advance = Vector2{Int64}(ftglyph.advance.x >> 6, ftglyph.advance.y >> 6)
    glyph.bearing = Vector2{Int64}(ftglyph.metrics.horiBearingX >> 6, ftglyph.metrics.horiBearingY >> 6)
    cache.glyphs[char] = glyph
end

function extractglyphimage(bitmap)
    pixmode = bitmap.pixel_mode
    if pixmode ∉ (FT_PIXEL_MODE_GRAY, FT_PIXEL_MODE_GRAY2, FT_PIXEL_MODE_GRAY4)
        throw(FontError("Currently only 1-, 2- & 4-byte grayscale pixel modes supported"))
    end
    if bitmap.num_grays != 256
        throw(FontError("Less than 256 levels of grayscale are currently not supported"))
    end
    
    img  = FlixGL.Image2D(zeros(getcolortype(pixmode), bitmap.rows, bitmap.width))
    buff = IOBuffer()
    
    for row ∈ 0:bitmap.rows-1
        # Reuse the same IOBuffer object - avoids allocations
        # NOTE: bitmap.pitch can be negative! Hence read every single row individually rather than the complete memseg.
        bytes = unsafe_wrap(Vector{UInt8}, bitmap.buffer+row*bitmap.pitch, bitmap.pitch)
        buff.data = bytes
        buff.size = length(bytes)
        seek(buff, 0)
        
        for col ∈ 1:bitmap.width
            if pixmode == FT_PIXEL_MODE_GRAY
                img.data[bitmap.rows-row, col] = ByteGrayscale(read(buff, UInt8))
            elseif pixmode == FT_PIXEL_MODE_GRAY2
                img.data[bitmap.rows-row, col] = GrayscaleColor{Uint16}(read(buff, UInt16))
            elseif pixmode == FT_PIXEL_MODE_GRAY4
                img.data[bitmap.rows-row, col] = GrayscaleColor{UInt32}(read(buff, UInt32))
            end
        end
    end
    
    img
end


function currentcache!(font::Font)
    if !haskey(font.caches, font.size)
        font.caches[font.size] = FontCache()
    end
    font.caches[font.size]
end

hasglyph(cache::FontCache, char::Char) = haskey(cache.glyphs, char)
Base.:∈(char::Char, cache::FontCache) = hasglyph(cache, char)


# Glyph Methods

Base.size(glyph::FontGlyph) = size(glyph.img)


# Cache Control

function clearcache!(font::Font, size::UInt8)
    if haskey(font.caches, size)
        delete!(font.caches, size)
    end
    font
end
function clearcache!(font::Font)
    font.caches = Dict()
    font
end

function uncache!(font::Font, size::UInt8, chars::Union{<:AbstractString, Char})
    if haskey(font.cache, size)
        cache = font.caches[size]
        for char ∈ chars
            delete!(cache.glyphs, char)
        end
    end
    font
end
uncache!(font::Font, chars::Union{<:AbstractString, Char}) = uncache!(font, font.size, chars)


# Helpers

function remove_trailing_newlines!(lines::AbstractVector)
    if length(lines) == 0 return lines end
    line = pop!(lines)
    while length(lines) > 0 && length(strip(line)) == 0
        line = pop!(lines)
    end
    push!(lines, line)
    lines
end
