local addonName, ns = ...

local PoisonData = {}
ns.PoisonData = PoisonData

PoisonData.order = {
    "instant",
    "deadly",
    "crippling",
    "wound",
    "mindNumbing",
    "distracting",
}

PoisonData.families = {
    instant = {
        label = "Instant Poison",
        itemIDs = { 6947, 6949, 6950, 8926, 8927, 8928 },
    },
    deadly = {
        label = "Deadly Poison",
        itemIDs = { 2892, 2893, 8984, 8985, 20844 },
    },
    crippling = {
        label = "Crippling Poison",
        itemIDs = { 3775, 3776 },
    },
    wound = {
        label = "Wound Poison",
        itemIDs = { 10918, 10920, 10921, 10922 },
    },
    mindNumbing = {
        label = "Mind-numbing Poison",
        itemIDs = { 5237, 6951, 9186 },
    },
    distracting = {
        label = "Distracting Poison",
        itemIDs = { 9187 },
    },
}

function PoisonData:IsValidFamily(key)
    return type(key) == "string" and self.families[key] ~= nil
end

function PoisonData:GetFamily(key)
    return self.families[key]
end

function PoisonData:GetLabel(key)
    local family = self:GetFamily(key)
    return family and family.label or ns.L.NONE
end

function PoisonData:GetAvailableItem(key)
    local family = self:GetFamily(key)
    if not family then
        return nil
    end

    for index = #family.itemIDs, 1, -1 do
        local itemID = family.itemIDs[index]
        if ns.ApiCompat:GetItemCount(itemID) > 0 then
            return itemID
        end
    end
    return nil
end

function PoisonData:GetStock(key)
    local family = self:GetFamily(key)
    local total = 0
    if family then
        for _, itemID in ipairs(family.itemIDs) do
            total = total + ns.ApiCompat:GetItemCount(itemID)
        end
    end
    return total
end

function PoisonData:GetRepresentativeIcon(key)
    local itemID = self:GetAvailableItem(key)
    local family = self:GetFamily(key)
    itemID = itemID or (family and family.itemIDs[#family.itemIDs])
    return itemID and ns.ApiCompat:GetItemIcon(itemID) or "Interface\\Icons\\Ability_Poisons"
end

function PoisonData:GetOptions()
    local items = {}
    for _, key in ipairs(self.order) do
        local family = self.families[key]
        items[#items + 1] = { value = key, label = family.label }
    end
    return items
end
