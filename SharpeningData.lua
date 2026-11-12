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
    [19] = { itemID = 3239, label = "Rough Weightstone", icon = "INV_Stone_WeightStone_01" },
    [20] = { itemID = 3240, label = "Coarse Weightstone", icon = "INV_Stone_WeightStone_02" },
    [21] = { itemID = 3241, label = "Heavy Weightstone", icon = "INV_Stone_WeightStone_03" },
    [484] = { itemID = 7965, label = "Solid Weightstone", icon = "INV_Stone_WeightStone_04" },
    [1703] = { itemID = 12643, label = "Dense Weightstone", icon = "INV_Stone_WeightStone_05" },
    [2954] = { itemID = 28420, label = "Fel Weightstone", icon = "INV_Stone_WeightStone_06", tbcOnly = true },
    [2955] = { itemID = 28421, label = "Adamantite Weightstone", icon = "INV_Stone_WeightStone_07", tbcOnly = true },
}

function SharpeningData:GetByEnchantID(enchantID)
    local stone = self.enchants[tonumber(enchantID)]
    if stone and (not stone.tbcOnly or ns.ApiCompat:IsTBC()) then
        return stone
    end
    return nil
end

function SharpeningData:GetLabel(stone)
    return ns.ApiCompat:GetItemName(stone.itemID) or stone.label
end

function SharpeningData:GetIcon(stone)
    -- Exact fallback also works before item data loads, with empty bags or dead.
    return ns.ApiCompat:GetItemIcon(stone.itemID) or ("Interface\\Icons\\" .. stone.icon)
end

-- Explicit choices retain their strength; auto mode follows flat weapon damage.
SharpeningData.order = { 40, 13, 14, 483, 1643, 2506, 2684, 2712, 2713, 7098,
    19, 20, 21, 484, 1703, 2954, 2955 }

SharpeningData.AUTO_KEY = "stone:auto"
SharpeningData.AUTO_LABEL = "Weapon Stone (Auto: max damage)"
SharpeningData.WEIGHT_AUTO_KEY = "weight:auto"
SharpeningData.WEIGHT_AUTO_LABEL = "Weightstone (Auto: max damage)"
-- Elemental crit and restricted undead/BFD bonuses cannot be ranked as flat damage.
SharpeningData.autoOrder = { 2713, 2712, 1643, 483, 14, 13, 40 }
SharpeningData.weightAutoOrder = { 2955, 2954, 1703, 484, 21, 20, 19 }

function SharpeningData:IsAvailableChoice(key)
    return key == self.AUTO_KEY or key == self.WEIGHT_AUTO_KEY or self:GetChoice(key) ~= nil
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

function SharpeningData:GetAvailableItem(key, slotID)
    if key == self.AUTO_KEY or key == self.WEIGHT_AUTO_KEY then
        local order = self.autoOrder
        if key == self.WEIGHT_AUTO_KEY then
            order = self.weightAutoOrder
        elseif slotID then
            local kind = ns.ApiCompat:GetWeaponStoneKind(slotID)
            if not kind then return nil end
            if kind == "weight" then order = self.weightAutoOrder end
        end
        for _, enchantID in ipairs(order) do
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
    local options = { { value = self.AUTO_KEY, label = ns.L.AUTO_STONE or self.AUTO_LABEL },
        { value = self.WEIGHT_AUTO_KEY, label = ns.L.AUTO_WEIGHT or self.WEIGHT_AUTO_LABEL } }
    for _, enchantID in ipairs(self.order) do
        local key = "stone:" .. enchantID
        local stone = self:GetChoice(key)
        if stone then
            options[#options + 1] = { value = key,
                label = self:GetLabel(stone) .. " (" .. string.format(ns.L.MINUTES or "%d min", self:GetDuration(stone) / 60) .. ")" }
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
