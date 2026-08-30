local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ActionBarWidget = Client.UI.ActionBarWidget

if type(ActionBarWidget) ~= "table"
    or type(ActionBarWidget.EnsureSlot) ~= "function"
    or ActionBarWidget._skillRollActivationExtensionInstalled == true
then
    return true
end

local baseEnsureSlot = ActionBarWidget.EnsureSlot

function ActionBarWidget:EnsureSlot(index)
    local slot = baseEnsureSlot(self, index)
    if type(slot) ~= "table" or slot._skillRollActivationHookInstalled == true then
        return slot
    end

    local frame = type(slot.GetFrame) == "function" and slot:GetFrame() or nil
    if frame and type(frame.HookScript) == "function" then
        frame:HookScript("OnMouseUp", function(_, button)
            if button ~= "LeftButton"
                or not slot.boundSkillRef
                or slot.enabled == false
                or (type(self.IsUnlocked) == "function" and self:IsUnlocked())
                or type(Client.ActivateActionBarSkill) ~= "function"
            then
                return
            end

            Client:ActivateActionBarSkill(slot.boundSkillRef)
        end)
        slot._skillRollActivationHookInstalled = true
    end

    return slot
end

ActionBarWidget._skillRollActivationExtensionInstalled = true
return true
