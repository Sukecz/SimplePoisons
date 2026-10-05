local addonName, ns = ...

local Core = {}
ns.Core = Core

function Core:Print(message)
    local prefix = "|cff6fd48fSimplePoisons:|r "
    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. tostring(message))
    elseif type(print) == "function" then
        print("SimplePoisons: " .. tostring(message))
    end
end

function Core:Initialize()
    ns.Database:Initialize(SimplePoisonsDB)
    ns.PoisonData:RequestItemData()
    ns.Buttons:Create()
    ns.MinimapButton:Create()
    ns.SecureActions:RefreshAll()
    ns.SlashCommands:Register()
    if not ns.ApiCompat:IsRogue() and not ns.ApiCompat:IsCombatLocked() then
        ns.Buttons.anchor:Hide()
    end
end

function Core:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= addonName then
            return
        end
        self:Initialize()
        self.frame:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        ns.SecureActions:RefreshAll()
        ns.Buttons:Refresh()
        ns.MinimapButton:RefreshVisibility()
        self:Print(ns.L.READY)
    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.SecureActions:RefreshAll()
        ns.Buttons:OnCombatEnded()
        ns.Buttons:Refresh(true)
        if ns.Options.frame and ns.Options.frame:IsShown() then
            ns.Options:Refresh()
        end
    elseif event == "BAG_UPDATE_DELAYED" or event == "GET_ITEM_INFO_RECEIVED"
        or event == "SKILL_LINES_CHANGED" or event == "SPELLS_CHANGED"
        or event == "PLAYER_ALIVE" or event == "PLAYER_ENTERING_WORLD"
        or (event == "UNIT_LEVEL" and ... == "player") then
        ns.SecureActions:RefreshAll()
        ns.Buttons:Refresh(true)
    elseif event == "PLAYER_EQUIPMENT_CHANGED"
        or (event == "UNIT_INVENTORY_CHANGED" and ... == "player") then
        ns.Buttons:Refresh(true)
    end
end

Core.frame = CreateFrame("Frame")
Core.frame:RegisterEvent("ADDON_LOADED")
Core.frame:RegisterEvent("PLAYER_LOGIN")
Core.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
Core.frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
Core.frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
Core.frame:RegisterEvent("BAG_UPDATE_DELAYED")
Core.frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
Core.frame:RegisterEvent("UNIT_LEVEL")
Core.frame:RegisterEvent("SKILL_LINES_CHANGED")
Core.frame:RegisterEvent("SPELLS_CHANGED")
Core.frame:RegisterEvent("PLAYER_ALIVE")
Core.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Core.frame:SetScript("OnEvent", function(_, event, ...)
    Core:OnEvent(event, ...)
end)
