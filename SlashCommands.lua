local addonName, ns = ...

local SlashCommands = {}
ns.SlashCommands = SlashCommands

local function trimLower(message)
    return string.lower((message or ""):match("^%s*(.-)%s*$"))
end

function SlashCommands:Handle(message)
    local command = trimLower(message)
    if command == "" or command == "config" or command == "options" then
        ns.Options:Open()
    elseif command == "move" or command == "unlock" then
        ns.Buttons:SetUnlocked(true)
    elseif command == "lock" then
        ns.Buttons:SetUnlocked(false)
    elseif command == "reset" then
        StaticPopup_Show("SIMPLEPOISONS_CONFIRM_RESET")
    elseif command == "api" or command == "debug" then
        ns.Core:Print(ns.ApiCompat:GetBuildReport())
    else
        ns.Core:Print(ns.L.HELP)
    end
end

function SlashCommands:Register()
    StaticPopupDialogs.SIMPLEPOISONS_CONFIRM_RESET = {
        text = ns.L.RESET_CONFIRM,
        button1 = ns.L.RESET,
        button2 = ns.L.CANCEL,
        OnAccept = function()
            if ns.ApiCompat:IsCombatLocked() then
                ns.Core:Print(ns.L.COMBAT_LOCKED)
                return
            end
            ns.Database:Reset()
            ns.Buttons:ApplyLayout()
            ns.Buttons:ApplyPosition()
            ns.SecureActions:RefreshAll()
            ns.Buttons:Refresh()
            ns.MinimapButton:UpdatePosition()
            ns.MinimapButton:RefreshVisibility()
            ns.Options:Refresh()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    _G.SLASH_SIMPLEPOISONS1 = "/simplepoisons"
    _G.SLASH_SIMPLEPOISONS2 = "/sp"
    SlashCmdList.SIMPLEPOISONS = function(message)
        SlashCommands:Handle(message)
    end
end
