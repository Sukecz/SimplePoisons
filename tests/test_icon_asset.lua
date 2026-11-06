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
