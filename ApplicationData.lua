local addonName, ns = ...

-- Shared click choices; poison rank selection and stone data stay independent.
local ApplicationData = {}
ns.ApplicationData = ApplicationData

function ApplicationData:IsAvailableChoice(key)
    return (ns.ApiCompat:IsRogue() and ns.PoisonData:IsAvailableFamily(key))
        or ns.SharpeningData:IsAvailableChoice(key)
end

function ApplicationData:GetAvailableItem(key, slotID)
    if ns.SharpeningData:IsAvailableChoice(key) then
        return ns.SharpeningData:GetAvailableItem(key, slotID)
    end
    return ns.PoisonData:GetAvailableItem(key)
end

function ApplicationData:GetLabel(key)
    if key == ns.SharpeningData.AUTO_KEY then return ns.L.AUTO_STONE or ns.SharpeningData.AUTO_LABEL end
    if key == ns.SharpeningData.WEIGHT_AUTO_KEY then return ns.L.AUTO_WEIGHT or ns.SharpeningData.WEIGHT_AUTO_LABEL end
    local stone = ns.SharpeningData:GetChoice(key)
    return stone and ns.SharpeningData:GetLabel(stone) or ns.PoisonData:GetLabel(key)
end

function ApplicationData:GetItemLabel(key, itemID)
    local stone = ns.SharpeningData:GetChoice(key)
    if key == ns.SharpeningData.AUTO_KEY or key == ns.SharpeningData.WEIGHT_AUTO_KEY then
        for _, candidate in pairs(ns.SharpeningData.enchants) do
            if candidate.itemID == itemID then stone = candidate; break end
        end
    end
    if stone then
        return ns.ApiCompat:GetItemName(itemID) or stone.label
    end
    return ns.PoisonData:GetItemLabel(key, itemID)
end

function ApplicationData:GetOptions()
    local options = ns.ApiCompat:IsRogue() and ns.PoisonData:GetOptions() or {}
    for _, option in ipairs(ns.SharpeningData:GetOptions()) do
        options[#options + 1] = option
    end
    return options
end

function ApplicationData:GetPreview(key, slotID)
    local itemID = self:GetAvailableItem(key, slotID or 16)
    local stone = ns.SharpeningData:GetChoice(key)
    if not itemID then
        if stone then
            itemID = ns.SharpeningData:GetItemIDs(stone)[1]
        elseif key == ns.SharpeningData.AUTO_KEY or key == ns.SharpeningData.WEIGHT_AUTO_KEY then
            local weight = key == ns.SharpeningData.WEIGHT_AUTO_KEY
                or ns.ApiCompat:GetWeaponStoneKind(slotID or 16) == "weight"
            itemID = weight and 12643 or 12404
        else
            local ids = ns.PoisonData:GetItemIDs(key)
            itemID = ids[#ids]
        end
    end
    local icon = itemID and ns.ApiCompat:GetItemIcon(itemID)
    if not icon and stone then icon = ns.SharpeningData:GetIcon(stone) end
    return icon or "Interface\\Icons\\Ability_Poisons", itemID
end
