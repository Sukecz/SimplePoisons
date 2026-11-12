-- Export the real options widgets using the integration-test mock. This is a
-- layout preview, not a claim about native WoW rendering or live secure clicks.
SIMPLEPOISONS_WIDGETS = {}
local destination = assert(arg[1], "Usage: lua5.1 tools/preview_options.lua OUTPUT.json [picker|binding]")
local mode = arg[2]
local function rgba(value)
    return type(value) == "table" and type(value[1]) == "number" and value or nil
end
local function json(value)
    if type(value) == "string" then
        return '"' .. value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r') .. '"'
    elseif type(value) == "number" or type(value) == "boolean" then return tostring(value)
    elseif type(value) == "table" then
        local result = {}
        for key, item in pairs(value) do result[#result + 1] = json(tostring(key)) .. ':' .. json(item) end
        return '{' .. table.concat(result, ',') .. '}'
    end
    return 'null'
end
function SIMPLEPOISONS_PREVIEW(ns)
    ns.ApiCompat.GetItemCount = function() return 8 end
    ns.ApiCompat.IsRogue = function() return true end
    ns.ApiCompat.GetWeaponStoneKind = function() return 'sharpen' end
    ns.ApiCompat.GetItemName = function() return nil end
    local icons = { [8928] = 'Ability_Poisons', [20844] = 'Ability_Rogue_DualWeild', [3776] = 'Ability_PoisonSting',
        [10922] = 'INV_Misc_Herb_16', [9186] = 'Spell_Nature_NullifyDisease' }
    for _, stone in pairs(ns.SharpeningData.enchants) do icons[stone.itemID] = stone.icon end
    ns.ApiCompat.GetItemIcon = function(_, id) return 'Interface\\Icons\\' .. (icons[id] or 'Ability_Poisons') end
    ns.Database:Initialize({ slots = {
        { bind = 'LeftButton', choice = 'instant' }, { bind = 'RightButton', choice = 'deadly' },
        { bind = 'MiddleButton', choice = 'crippling' }, { bind = 'key:SHIFT-F8', choice = 'wound', target = 16 },
        { bind = 'shift-LeftButton', choice = 'mindNumbing' },
        { bind = 'key:CTRL-F9', choice = 'stone:1643', target = 17 },
        { bind = 'Button4', choice = 'stone:auto' }, { bind = '', choice = 'weight:auto' },
    } })
    ns.Options.page = 1
    ns.Options:Open()
    if mode == 'picker' then ns.Options:OpenPicker(1) end
    if mode == 'binding' then ns.Options:BeginCapture(1); ns.Options:SetCandidate('key:CTRL-F8') end
    local result = { root = ns.Options.frame.id, widgets = {} }
    for _, widget in ipairs(SIMPLEPOISONS_WIDGETS) do
        local point = {}
        for index, component in ipairs(widget.point or {}) do
            point[index] = type(component) == 'table' and { relative = component.id } or component
        end
        result.widgets[widget.id] = { id = widget.id, parent = widget.parent and widget.parent.id,
            kind = widget.kind, template = widget.template, point = point,
            text = type(widget.text) == 'string' and widget.text or nil, font = widget.font,
            width = widget.width, height = widget.height, texture = widget.texture,
            shown = widget.shown, background = rgba(widget.background), border = rgba(widget.border),
            alpha = widget.alpha, color = widget.color, strata = widget.strata,
            checked = type(widget.checked) == "boolean" and widget.checked or nil,
            value = type(widget.value) == "number" and widget.value or nil }
    end
    local file = assert(io.open(destination, 'w')); file:write(json(result)); file:close()
end
dofile('tests/test_ui.lua')
