local addonName, ns = ...

-- Shared click choices; poison rank selection and stone data stay independent.
local ApplicationData = {}
ns.ApplicationData = ApplicationData

function ApplicationData:IsAvailableChoice(key)
    return (ns.ApiCompat:IsRogue() and ns.PoisonData:IsAvailableFamily(key))
        or ns.SharpeningData:IsAvailableChoice(key)
end

function ApplicationData:GetAvailableItem(key)
    if ns.SharpeningData:IsAvailableChoice(key) then
        return ns.SharpeningData:GetAvailableItem(key)
    end
    return ns.PoisonData:GetAvailableItem(key)
end

function ApplicationData:GetLabel(key)
    if key == ns.SharpeningData.AUTO_KEY then return ns.SharpeningData.AUTO_LABEL end
    local stone = ns.SharpeningData:GetChoice(key)
    return stone and stone.label or ns.PoisonData:GetLabel(key)
end

function ApplicationData:GetItemLabel(key, itemID)
    local stone = ns.SharpeningData:GetChoice(key)
    if key == ns.SharpeningData.AUTO_KEY then
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
