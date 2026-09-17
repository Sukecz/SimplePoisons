local addonName, ns = ...

local PoisonData = {}
ns.PoisonData = PoisonData

PoisonData.order = {
    "instant",
    "deadly",
    "crippling",
    "wound",
    "mindNumbing",
    "anesthetic",
}

PoisonData.families = {
    instant = {
        label = "Instant Poison",
        itemIDs = { 6947, 6949, 6950, 8926, 8927, 8928 },
        enchantIDs = { 323, 324, 325, 623, 624, 625 },
        tbcItemIDs = { 21927 },
        tbcEnchantIDs = { 2641 },
    },
    deadly = {
        label = "Deadly Poison",
        itemIDs = { 2892, 2893, 8984, 8985, 20844 },
        enchantIDs = { 7, 8, 626, 627, 2630 },
        tbcItemIDs = { 22053, 22054 },
        tbcEnchantIDs = { 2642, 2643 },
    },
    crippling = {
        label = "Crippling Poison",
        itemIDs = { 3775, 3776 },
        enchantIDs = { 22, 603 },
    },
    wound = {
        label = "Wound Poison",
        itemIDs = { 10918, 10920, 10921, 10922 },
        enchantIDs = { 703, 704, 705, 706 },
        tbcItemIDs = { 22055 },
        tbcEnchantIDs = { 2644 },
    },
    mindNumbing = {
        label = "Mind-numbing Poison",
        itemIDs = { 5237, 6951, 9186 },
        enchantIDs = { 35, 23, 643 },
    },
    anesthetic = {
        label = "Anesthetic Poison",
        itemIDs = { 21835 },
        enchantIDs = { 2640 },
        tbcOnly = true,
    },
}

PoisonData.enchantFamilies = {}
PoisonData.tbcEnchantFamilies = {}
for familyKey, family in pairs(PoisonData.families) do
    if not family.tbcOnly then
        for _, enchantID in ipairs(family.enchantIDs) do
            PoisonData.enchantFamilies[enchantID] = familyKey
        end
    end
    local tbcEnchantIDs = family.tbcEnchantIDs or (family.tbcOnly and family.enchantIDs) or {}
    for _, enchantID in ipairs(tbcEnchantIDs) do
        PoisonData.tbcEnchantFamilies[enchantID] = familyKey
    end
end

function PoisonData:IsValidFamily(key)
    return type(key) == "string" and self.families[key] ~= nil
end

function PoisonData:IsAvailableFamily(key)
    local family = self.families[key]
    return family ~= nil and (not family.tbcOnly or ns.ApiCompat:IsTBC())
end

function PoisonData:GetFamily(key)
    return self.families[key]
end

function PoisonData:GetItemIDs(key)
    local family = self:GetFamily(key)
    if not family or not self:IsAvailableFamily(key) then
        return {}
    end
    if not ns.ApiCompat:IsTBC() or not family.tbcItemIDs then
        return family.itemIDs
    end
    local itemIDs = {}
    for _, itemID in ipairs(family.itemIDs) do
        itemIDs[#itemIDs + 1] = itemID
    end
    for _, itemID in ipairs(family.tbcItemIDs) do
        itemIDs[#itemIDs + 1] = itemID
    end
    return itemIDs
end

function PoisonData:GetLabel(key)
    local family = self:GetFamily(key)
    return family and family.label or ns.L.NONE
end

function PoisonData:GetFamilyByEnchantID(enchantID)
    enchantID = tonumber(enchantID)
    return self.enchantFamilies[enchantID]
        or (ns.ApiCompat:IsTBC() and self.tbcEnchantFamilies[enchantID])
end

function PoisonData:GetAvailableItem(key)
    local family = self:GetFamily(key)
    if not family or not self:IsAvailableFamily(key) then
        return nil
    end

    local itemIDs = self:GetItemIDs(key)
    for index = #itemIDs, 1, -1 do
        local itemID = itemIDs[index]
        if ns.ApiCompat:GetItemCount(itemID) > 0 then
            return itemID
        end
    end
    return nil
end

function PoisonData:GetStock(key)
    local family = self:GetFamily(key)
    local total = 0
    if family and self:IsAvailableFamily(key) then
        for _, itemID in ipairs(self:GetItemIDs(key)) do
            total = total + ns.ApiCompat:GetItemCount(itemID)
        end
    end
    return total
end

function PoisonData:GetRepresentativeIcon(key)
    local itemID = self:GetAvailableItem(key)
    local family = self:GetFamily(key)
    local itemIDs = self:GetItemIDs(key)
    itemID = itemID or itemIDs[#itemIDs]
    return itemID and ns.ApiCompat:GetItemIcon(itemID) or "Interface\\Icons\\Ability_Poisons"
end

function PoisonData:RequestItemData()
    for _, key in ipairs(self.order) do
        if self:IsAvailableFamily(key) then
            for _, itemID in ipairs(self:GetItemIDs(key)) do
                ns.ApiCompat:RequestItemData(itemID)
            end
        end
    end
end

function PoisonData:GetOptions()
    local items = {}
    for _, key in ipairs(self.order) do
        local family = self.families[key]
        if self:IsAvailableFamily(key) then
            items[#items + 1] = { value = key, label = family.label }
        end
    end
    return items
end
