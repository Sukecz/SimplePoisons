local addonName, ns = ...

local SharpeningData = {}
ns.SharpeningData = SharpeningData

-- Item/enchant mappings and per-client durations: docs/sharpening-stones.md.
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

-- Explicit choices retain their strength; auto mode follows flat weapon damage.
SharpeningData.order = { 40, 13, 14, 483, 1643, 2506, 2684, 2712, 2713, 7098 }

SharpeningData.AUTO_KEY = "stone:auto"
SharpeningData.AUTO_LABEL = "Sharpening Stone (Auto: max damage)"
-- Elemental crit and restricted undead/BFD bonuses cannot be ranked as flat damage.
SharpeningData.autoOrder = { 2713, 2712, 1643, 483, 14, 13, 40 }

function SharpeningData:IsAvailableChoice(key)
    return key == self.AUTO_KEY or self:GetChoice(key) ~= nil
end

function SharpeningData:GetChoice(key)
    local enchantID = type(key) == "string" and key:match("^stone:(%d+)$")
    local stone = enchantID and self:GetByEnchantID(enchantID)
    if not stone or (tonumber(enchantID) == 7098 and not ns.ApiCompat:IsSoD()) then
        return nil
    end
    return stone
end

function SharpeningData:GetItemIDs(stone)
    if stone.itemID == 18262 and ns.ApiCompat:IsForever() then
        return { 287980, 18262 }
    elseif stone.itemID == 23122 and ns.ApiCompat:IsSoD() then
        return { 238241, 23122 }
    end
    return { stone.itemID }
end

function SharpeningData:GetDuration(stone)
    return (ns.ApiCompat:IsTBC() or stone.itemID == 23122) and 3600 or 1800
end

function SharpeningData:GetAvailableItem(key)
    if key == self.AUTO_KEY then
        for _, enchantID in ipairs(self.autoOrder) do
            local itemID = self:GetAvailableItem("stone:" .. enchantID)
            if itemID then return itemID end
        end
        return nil
    end
    local stone = self:GetChoice(key)
    if stone then
        for _, itemID in ipairs(self:GetItemIDs(stone)) do
            if ns.ApiCompat:GetItemCount(itemID) > 0 and ns.ApiCompat:MeetsItemLevel(itemID) then
                return itemID
            end
        end
    end
end

function SharpeningData:GetOptions()
    local options = { { value = self.AUTO_KEY, label = self.AUTO_LABEL } }
    for _, enchantID in ipairs(self.order) do
        local key = "stone:" .. enchantID
        local stone = self:GetChoice(key)
        if stone then
            options[#options + 1] = { value = key,
                label = string.format("%s (%d min)", stone.label, self:GetDuration(stone) / 60) }
        end
    end
    return options
end

function SharpeningData:RequestItemData()
    for _, option in ipairs(self:GetOptions()) do
        local stone = self:GetChoice(option.value)
        if stone then
            for _, itemID in ipairs(self:GetItemIDs(stone)) do
                ns.ApiCompat:RequestItemData(itemID)
            end
        end
    end
end
