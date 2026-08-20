local addonName, ns = ...

local SecureActions = {}
ns.SecureActions = SecureActions

local ATTRIBUTE_INDEX = {
    LeftButton = "1",
    RightButton = "2",
    MiddleButton = "3",
}

function SecureActions:BuildMacro(itemID, slotID)
    if not tonumber(itemID) then
        return nil
    end
    return string.format("/use item:%d\n/use %d", itemID, slotID)
end
function SecureActions:ConfigureButton(button)
    if not button then
        return
    end
    if ns.ApiCompat:IsCombatLocked() then
        self.refreshPending = true
        return
    end

    for mouseButton, suffix in pairs(ATTRIBUTE_INDEX) do
        local familyKey = ns.Database:GetClick(mouseButton)
        local itemID = ns.PoisonData:GetAvailableItem(familyKey)
        local macro = self:BuildMacro(itemID, button.slotID)
        button:SetAttribute("type" .. suffix, macro and "macro" or nil)
        button:SetAttribute("macrotext" .. suffix, macro)
        button.availableItems = button.availableItems or {}
        button.availableItems[mouseButton] = itemID
    end
    self.refreshPending = false
end

function SecureActions:RefreshAll()
    if ns.ApiCompat:IsCombatLocked() then
        self.refreshPending = true
        return
    end
    if ns.Buttons.mainButton then
        self:ConfigureButton(ns.Buttons.mainButton)
        self:ConfigureButton(ns.Buttons.offButton)
    end
end

function SecureActions:OnCombatEnded()
    if self.refreshPending then
        self:RefreshAll()
    end
end
