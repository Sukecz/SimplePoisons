local addonName, ns = ...

local ApiCompat = {}
ns.ApiCompat = ApiCompat

function ApiCompat:IsCombatLocked()
    return type(InCombatLockdown) == "function" and InCombatLockdown() or false
end
function ApiCompat:IsTBC()
    return WOW_PROJECT_ID ~= nil
        and WOW_PROJECT_BURNING_CRUSADE_CLASSIC ~= nil
        and WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
end

function ApiCompat:IsRogue()
    if type(UnitClass) ~= "function" then
        return true
    end
    local _, classToken = UnitClass("player")
    return classToken == "ROGUE"
end

function ApiCompat:GetItemCount(itemID)
    if type(GetItemCount) == "function" then
        return tonumber(GetItemCount(itemID, false, false)) or 0
    end
    if C_Item and type(C_Item.GetItemCount) == "function" then
        return tonumber(C_Item.GetItemCount(itemID, false, false, false)) or 0
    end
    return 0
end

function ApiCompat:GetItemIcon(itemID)
    if type(GetItemIcon) == "function" then
        return GetItemIcon(itemID)
    end
    if C_Item and type(C_Item.GetItemIconByID) == "function" then
        return C_Item.GetItemIconByID(itemID)
    end
    if type(GetItemInfoInstant) == "function" then
        local _, _, _, _, icon = GetItemInfoInstant(itemID)
        return icon
    end
    return nil
end

function ApiCompat:GetItemName(itemID)
    if type(GetItemInfo) == "function" then
        return GetItemInfo(itemID)
    end
    if C_Item and type(C_Item.GetItemNameByID) == "function" then
        return C_Item.GetItemNameByID(itemID)
    end
    return nil
end

function ApiCompat:GetWeaponState(slotID)
    local state = {
        hasWeapon = type(GetInventoryItemID) ~= "function" or GetInventoryItemID("player", slotID) ~= nil,
        hasEnchant = false,
        expirationMS = 0,
        charges = 0,
        enchantID = nil,
    }

    if type(GetWeaponEnchantInfo) ~= "function" then
        return state
    end

    local mh, mhExpiration, mhCharges, mhEnchantID,
        oh, ohExpiration, ohCharges, ohEnchantID = GetWeaponEnchantInfo()
    if slotID == ns.Constants.MAIN_HAND_SLOT then
        state.hasEnchant = mh and true or false
        state.expirationMS = tonumber(mhExpiration) or 0
        state.charges = tonumber(mhCharges) or 0
        state.enchantID = tonumber(mhEnchantID)
    else
        state.hasEnchant = oh and true or false
        state.expirationMS = tonumber(ohExpiration) or 0
        state.charges = tonumber(ohCharges) or 0
        state.enchantID = tonumber(ohEnchantID)
    end
    return state
end

function ApiCompat:GetWeaponTexture(slotID)
    if type(GetInventoryItemTexture) == "function" then
        return GetInventoryItemTexture("player", slotID)
    end
    return nil
end

local function normalized(text)
    return type(text) == "string" and string.lower(text) or ""
end

function ApiCompat:DetectPoisonFamily(slotID)
    if type(CreateFrame) ~= "function" or not UIParent then
        return nil
    end

    if not self.scanTooltip then
        self.scanTooltip = CreateFrame("GameTooltip", "SimplePoisonsScanTooltip", UIParent, "GameTooltipTemplate")
        self.scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end

    local tooltip = self.scanTooltip
    tooltip:ClearLines()
    local ok = pcall(tooltip.SetInventoryItem, tooltip, "player", slotID)
    if not ok then
        return nil
    end

    local lines = {}
    for index = 1, tooltip:NumLines() do
        local left = _G[tooltip:GetName() .. "TextLeft" .. index]
        local right = _G[tooltip:GetName() .. "TextRight" .. index]
        if left and left:GetText() then
            lines[#lines + 1] = normalized(left:GetText())
        end
        if right and right:GetText() then
            lines[#lines + 1] = normalized(right:GetText())
        end
    end

    for _, key in ipairs(ns.PoisonData.order) do
        local family = ns.PoisonData:GetFamily(key)
        for index = #family.itemIDs, 1, -1 do
            local name = self:GetItemName(family.itemIDs[index])
            if name then
                local needle = normalized(name)
                for _, line in ipairs(lines) do
                    if string.find(line, needle, 1, true) then
                        return key
                    end
                end
            end
        end
    end
    return nil
end

function ApiCompat:GetBuildReport()
    local version, build, date, interface = "unknown", "unknown", "unknown", "unknown"
    if type(GetBuildInfo) == "function" then
        version, build, date, interface = GetBuildInfo()
    end
    return string.format(
        "version=%s build=%s date=%s interface=%s project=%s weaponEnchantAPI=%s",
        tostring(version), tostring(build), tostring(date), tostring(interface),
        tostring(WOW_PROJECT_ID), tostring(type(GetWeaponEnchantInfo) == "function")
    )
end
