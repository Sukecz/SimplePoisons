local locales = { 'enUS', 'enGB', 'ptBR', 'deDE', 'frFR', 'esES', 'esMX', 'itIT', 'ruRU', 'koKR', 'zhCN', 'zhTW', 'unknown' }
local function formats(text)
    local out = {}
    for format in text:gmatch('%%[sd]') do out[#out + 1] = format end
    return table.concat(out)
end
local english = {}
assert(loadfile('Locales/enUS.lua'))('SimplePoisons', english)
for _, locale in ipairs(locales) do
    GetLocale = function() return locale end
    local ns = {}
    assert(loadfile('Locales/enUS.lua'))('SimplePoisons', ns)
    assert(loadfile('Locales/Translations.lua'))('SimplePoisons', ns)
    for key, text in pairs(english.L) do
        assert(type(ns.L[key]) == 'string' and ns.L[key] ~= '', locale .. ' missing ' .. key)
        assert(formats(ns.L[key]) == formats(text), locale .. ' printf mismatch ' .. key)
    end
    if locale ~= 'enUS' and locale ~= 'enGB' and locale ~= 'unknown' then
        assert(ns.L.SETTINGS ~= english.L.SETTINGS, locale .. ' must actually translate')
    else
        assert(ns.L.SETTINGS == english.L.SETTINGS)
    end
    for _, path in ipairs({ 'Defaults.lua', 'Bindings.lua', 'PoisonData.lua', 'SharpeningData.lua', 'ApiCompat.lua',
        'ApplicationData.lua', 'Database.lua', 'SecureActions.lua' }) do assert(loadfile(path))('SimplePoisons', ns) end
    ns.Database:Initialize({})
    ns.ApiCompat.GetItemCount = function() return 1 end
    ns.ApiCompat.IsCombatLocked = function() return false end
    ns.ApiCompat.IsRogue = function() return true end
    local attrs = {}
    ns.SecureActions:ConfigureButton({ slotID = 16, SetAttribute = function(_, k, v) attrs[k] = v end })
    assert(attrs.macrotext1 == '/use item:8928\n/use 16', locale .. ': application is ID based')
    assert(ns.ApiCompat:DetectPoisonFamily(16, 625) == 'instant')
    local tooltipLine
    UIParent = {}
    CreateFrame = function()
        _G.SimplePoisonsScanTooltipTextLeft1 = { GetText = function() return tooltipLine end }
        return { SetOwner = function() end, ClearLines = function() end, SetInventoryItem = function() end,
            NumLines = function() return 1 end, GetName = function() return 'SimplePoisonsScanTooltip' end }
    end
    -- Use names with accents and CJK characters, a rank omitted by the enchant,
    -- and color markup. The test never consults an English poison label.
    local name = ns.L.POISON_instant
    local loaded = true
    GetItemInfo = function(id) if loaded and id == 8928 then return name .. ' VI' end end
    C_Item = nil
    GetItemSpell = nil
    tooltipLine = '|cff00ff00' .. name .. '|r (30 min)'
    assert(ns.ApiCompat:DetectPoisonFamily(16, 0) == 'instant', locale .. ': tooltip rank difference')
    tooltipLine = 'Chance on hit: ' .. name .. ' (30 min)'
    assert(not ns.ApiCompat:DetectPoisonFamily(16, 0), 'a weapon proc description is not an applied poison')
    tooltipLine = name .. 'suffix'
    assert(not ns.ApiCompat:DetectPoisonFamily(16, 0), 'do not match inside another word')
    tooltipLine = name .. ' (30 min)'
    loaded = false
    local requests = 0
    ns.ApiCompat.RequestItemData = function() requests = requests + 1 end
    assert(not ns.ApiCompat:DetectPoisonFamily(16, 0), 'unknown data must not invent a poison')
    for event = 1, 3 do ns.ApiCompat:DetectPoisonFamily(16, 0) end
    assert(requests == 0, 'tooltip rescans must not re-request failed item data and trigger event loops')
    C_Item = { GetItemNameByID = function(id) if id == 8928 then return name .. ' VI' end end }
    assert(ns.ApiCompat:DetectPoisonFamily(16, 0) == 'instant', 'modern API fallback after legacy cache miss')
    C_Item.GetItemNameByID = nil
    GetItemSpell = function(id) if id == 8928 then return name end end
    assert(ns.ApiCompat:DetectPoisonFamily(16, 0) == 'instant', 'localized on-use spell fallback')
    loaded = true
end
print('Locales: all 11 locales, English alias/fallback, printf signatures, ID macros, localized tooltips, cold cache and API fallback passed')
