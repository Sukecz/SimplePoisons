-- Validate the decoder-compatible container without a graphics-library dependency.
local file = assert(io.open("assets/minimap-icon.tga", "rb"))
local data = file:read("*a")
file:close()
local function u16(offset)
    return data:byte(offset) + data:byte(offset + 1) * 256
end
assert(data:byte(2) == 0, "no color map")
assert(data:byte(3) == 2, "minimap texture must be uncompressed true-color TGA")
assert(u16(13) == 256 and u16(15) == 256)
assert(data:byte(17) == 32 and data:byte(18) % 16 == 8, "RGBA with 8-bit alpha")
local start = 19 + data:byte(1)
assert(#data >= start - 1 + 256 * 256 * 4, "complete pixel payload")
local green, transparent = 0, 0
for offset = start, start + 256 * 256 * 4 - 1, 4 do
    local b, g, r, a = data:byte(offset, offset + 3)
    if a > 128 and g > 100 and g > r and g > b then green = green + 1 end
    if a == 0 then transparent = transparent + 1 end
end
assert(green > 1000, "visible green artwork must be present")
assert(transparent > 1000, "preserve transparent background")
print("Minimap texture: complete raw RGBA TGA, visible green logo and transparency passed")


local header = assert(io.open("assets/logo-header.tga", "rb"))
local logo = header:read("*a")
header:close()
assert(logo:byte(3) == 2 and logo:byte(17) == 32 and logo:byte(18) % 16 == 8)
assert(logo:byte(13) + logo:byte(14) * 256 == 512 and logo:byte(15) + logo:byte(16) * 256 == 256)
local alphaStart = 19 + logo:byte(1)
local empty, opaque = 0, 0
for offset = alphaStart + 3, alphaStart + 512 * 256 * 4 - 1, 4 do
    local alpha = logo:byte(offset)
    assert(alpha, "complete header texture")
    if alpha == 0 then empty = empty + 1 end
    if alpha > 128 then opaque = opaque + 1 end
end
assert(empty > 20000 and opaque > 20000, "header must preserve artwork and real transparent surroundings")
print("Header logo: decoder-compatible RGBA TGA with transparent background passed")
