local addonName, ns = ...

local SecureActions = {}
ns.SecureActions = SecureActions

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

    button:SetAttribute("useOnKeyDown", false)
    -- Clear the complete binding space, including removed or reassigned slots.
    button.availableItems = {}
    button.boundChoices = {}
    for bind, attribute in pairs(ns.Bindings.attributes) do
        local choice = ns.Database:GetClick(bind)
        local itemID = choice and ns.ApplicationData:GetAvailableItem(choice, button.slotID)
        local macro = self:BuildMacro(itemID, button.slotID)
        local prefix, suffix = attribute.prefix, attribute.suffix
        button:SetAttribute(prefix .. "type" .. suffix, macro and "macro" or (prefix ~= "" and "" or nil))
        button:SetAttribute(prefix .. "macrotext" .. suffix, macro)
        button.availableItems[bind] = itemID
        button.boundChoices[bind] = choice
    end
    self.refreshPending = false
end

function SecureActions:RefreshKeyboard()
    if ns.ApiCompat:IsCombatLocked() then self.refreshPending = true; return end
    if type(SetOverrideBindingClick) ~= "function" or type(ClearOverrideBindings) ~= "function" then return end
    self.keyButtons = self.keyButtons or {}
    self.bindingOwner = self.bindingOwner or CreateFrame("Frame", "SimplePoisonsBindingOwner", UIParent)
    local owner = self.bindingOwner
    ClearOverrideBindings(owner)
    self.keyState = {}
    for _, button in pairs(self.keyButtons) do
        button:SetAttribute("type", nil)
        button:SetAttribute("macrotext", nil)
    end
    for index, slot in ipairs(ns.Database:GetSlots()) do
        if ns.Bindings:IsKeyboard(slot.bind) then
            local button = self.keyButtons[index]
            local name = "SimplePoisonsKeySlot" .. index
            if not button then
                button = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
                button:RegisterForClicks("AnyUp")
                button:SetAttribute("useOnKeyDown", false)
                self.keyButtons[index] = button
            end
            local itemID = ns.ApplicationData:GetAvailableItem(slot.choice, slot.target or 16)
            local macro = self:BuildMacro(itemID, slot.target or 16)
            button:SetAttribute("type", macro and "macro" or nil)
            button:SetAttribute("macrotext", macro)
            self.keyState[slot.bind] = { choice = slot.choice, itemID = itemID, target = slot.target or 16 }
            SetOverrideBindingClick(owner, true, slot.bind:sub(5), name, "LeftButton")
        end
    end
end

function SecureActions:RefreshAll()
    if ns.ApiCompat:IsCombatLocked() then
        self.refreshPending = true
        return
    end
    if ns.Buttons.mainButton then
        self:ConfigureButton(ns.Buttons.mainButton)
        self:ConfigureButton(ns.Buttons.offButton)
        self:RefreshKeyboard()
    end
end

function SecureActions:OnCombatEnded()
    if self.refreshPending then
        self:RefreshAll()
    end
end
