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
    ns.SharpeningData:RequestItemData()
    ns.Buttons:Create()
    ns.MinimapButton:Create()
    ns.SecureActions:RefreshAll()
    ns.SlashCommands:Register()
    ns.Options:RegisterCategory()
end

-- Inventory APIs can still be empty at PLAYER_ENTERING_WORLD on a cold login.
-- A finite sequence also refreshes late enchant/Auto data without idle polling.
local EQUIPMENT_RETRY_DELAYS = { 0.5, 1, 2, 4, 8 }

function Core:QueueEquipmentRefresh()
    self.equipmentGeneration = (self.equipmentGeneration or 0) + 1
    if not C_Timer or type(C_Timer.After) ~= "function" then return end
    local generation = self.equipmentGeneration
    local function schedule(index)
        local delay = EQUIPMENT_RETRY_DELAYS[index]
        if not delay then return end
        C_Timer.After(delay, function()
            if generation ~= self.equipmentGeneration then return end
            ns.SecureActions:RefreshAll()
            ns.Buttons:Refresh(true)
            schedule(index + 1)
        end)
    end
    schedule(1)
end

function Core:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= addonName then
            return
        end
        self:Initialize()
        self.frame:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        ns.Options:RegisterCategory()
        ns.MinimapButton:Create()
        ns.SecureActions:RefreshAll()
        ns.Buttons:Refresh()
        ns.MinimapButton:RefreshVisibility()
        self:Print(ns.L.READY)
    elseif event == "PLAYER_ENTERING_WORLD" then
        ns.SecureActions:RefreshAll()
        ns.Buttons:Refresh(true)
        self:QueueEquipmentRefresh()
    elseif event == "PLAYER_LEAVING_WORLD" then
        self.equipmentGeneration = (self.equipmentGeneration or 0) + 1
    elseif event == "PLAYER_REGEN_DISABLED" then
        ns.Options:CancelCapture()
        if ns.Options.picker then ns.Options.picker:Hide() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.SecureActions:RefreshAll()
        ns.Buttons:OnCombatEnded()
        ns.Buttons:Refresh(true)
        if ns.Options.frame and ns.Options.frame:IsShown() then
            ns.Options:Refresh()
        end
    elseif event == "BAG_UPDATE_DELAYED" or event == "GET_ITEM_INFO_RECEIVED"
        or event == "ITEM_DATA_LOAD_RESULT"
        or event == "SKILL_LINES_CHANGED" or event == "SPELLS_CHANGED"
        or event == "PLAYER_ALIVE"
        or (event == "UNIT_LEVEL" and ... == "player") then
        ns.SecureActions:RefreshAll()
        ns.Buttons:Refresh(true)
    elseif event == "PLAYER_EQUIPMENT_CHANGED"
        or event == "WEAPON_ENCHANT_CHANGED" or event == "WEAPON_SLOT_CHANGED"
        or (event == "UNIT_INVENTORY_CHANGED" and ... == "player") then
        ns.SecureActions:RefreshAll()
        ns.Buttons:Refresh(true)
    end
end

Core.frame = CreateFrame("Frame")
Core.frame:RegisterEvent("ADDON_LOADED")
Core.frame:RegisterEvent("PLAYER_LOGIN")
Core.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
Core.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
Core.frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
Core.frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
-- Older client builds may not expose the dedicated weapon events.
pcall(Core.frame.RegisterEvent, Core.frame, "WEAPON_ENCHANT_CHANGED")
pcall(Core.frame.RegisterEvent, Core.frame, "WEAPON_SLOT_CHANGED")
Core.frame:RegisterEvent("BAG_UPDATE_DELAYED")
Core.frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
pcall(Core.frame.RegisterEvent, Core.frame, "ITEM_DATA_LOAD_RESULT")
Core.frame:RegisterEvent("UNIT_LEVEL")
Core.frame:RegisterEvent("SKILL_LINES_CHANGED")
Core.frame:RegisterEvent("SPELLS_CHANGED")
Core.frame:RegisterEvent("PLAYER_ALIVE")
Core.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Core.frame:RegisterEvent("PLAYER_LEAVING_WORLD")
Core.frame:SetScript("OnEvent", function(_, event, ...)
    Core:OnEvent(event, ...)
end)
