local addonName, ns = ...

local SharpeningData = {}
ns.SharpeningData = SharpeningData

-- Monitoring only: these items never enter poison options or secure macros.
-- Item textures and enchant IDs audited against client databases, 2026-10-07.
SharpeningData.enchants = {
    [40] = { itemID = 2862, label = "Rough Sharpening Stone", icon = "INV_Stone_SharpeningStone_01" },
    [13] = { itemID = 2863, label = "Coarse Sharpening Stone", icon = "INV_Stone_SharpeningStone_02" },
    [14] = { itemID = 2871, label = "Heavy Sharpening Stone", icon = "INV_Stone_SharpeningStone_03" },
    [483] = { itemID = 7964, label = "Solid Sharpening Stone", icon = "INV_Stone_SharpeningStone_04" },
    [1643] = { itemID = 12404, label = "Dense Sharpening Stone", icon = "INV_Stone_SharpeningStone_05" },
    [2506] = { itemID = 18262, label = "Elemental Sharpening Stone", icon = "INV_Stone_02" },
    [2684] = { itemID = 23122, label = "Consecrated Sharpening Stone", icon = "INV_Stone_SharpeningStone_02" },
    [2712] = { itemID = 23528, label = "Fel Sharpening Stone", icon = "INV_Stone_SharpeningStone_06", tbcOnly = true },
    [2713] = { itemID = 23529, label = "Adamantite Sharpening Stone", icon = "INV_Stone_SharpeningStone_07", tbcOnly = true },
    [7098] = { itemID = 211845, label = "Blackfathom Sharpening Stone", icon = "INV_Misc_Rune_04" },
}

function SharpeningData:GetByEnchantID(enchantID)
    local stone = self.enchants[tonumber(enchantID)]
    if stone and (not stone.tbcOnly or ns.ApiCompat:IsTBC()) then
        return stone
    end
    return nil
end

function SharpeningData:GetIcon(stone)
    -- Exact fallback also works before item data loads, with empty bags or dead.
    return ns.ApiCompat:GetItemIcon(stone.itemID) or ("Interface\\Icons\\" .. stone.icon)
end
