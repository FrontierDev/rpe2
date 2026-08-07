local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local function shallowCloneTable(value)
    local copy = {}
    for key, nestedValue in pairs(type(value) == "table" and value or {}) do
        copy[key] = nestedValue
    end

    return copy
end

local function getComponentTitle(component)
    local effectType = component and component.effect and component.effect.type or "damage"
    local phase = component and component.castPhase or "on_cast_end"
    return ("%s / %s"):format(phase, effectType)
end

function DataEditor:EnsureSpellInspectorComponentContextMenu()
    if self.SpellInspectorComponentContextMenu then
        return self.SpellInspectorComponentContextMenu
    end

    self.SpellInspectorComponentContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorSpellInspectorComponentContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item then
                return
            end

            if item.value == "remove-component" and self.ContextMenuSpellComponentIndex then
                local removeIndex = self.ContextMenuSpellComponentIndex
                self:CommitSelectedSpell(function(spell)
                    table.remove(spell.components or {}, removeIndex)
                end)
            elseif item.value == "remove-scaling" and self.ContextMenuSpellScalingIndex then
                local component = self:GetSelectedSpellInspectorComponent()
                local removeIndex = self.ContextMenuSpellScalingIndex
                if component then
                    self:CommitSelectedSpell(function()
                        local scaling = component.effect and component.effect.statScaling or {}
                        table.remove(scaling, removeIndex)
                    end)
                end
            end

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.SpellInspectorComponentContextMenu:SetParent(self.SpellInspectorPage or UIParent)
    self.SpellInspectorComponentContextMenu:Create()
    return self.SpellInspectorComponentContextMenu
end

function DataEditor:ShowSpellInspectorComponentContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureSpellInspectorComponentContextMenu()
    self.ContextMenuSpellComponentIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-component" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:ShowSpellInspectorScalingContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureSpellInspectorComponentContextMenu()
    self.ContextMenuSpellScalingIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-scaling" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:BuildSpellInspectorComponentRows(spell)
    local rows = {}

    for index = 1, #(spell and spell.components or {}) do
        local component = spell.components[index]
        rows[#rows + 1] = {
            rowIndex = index,
            title = getComponentTitle(component),
            detail = self:FormatSpellInspectorTargetSummary(component),
        }
    end

    return rows
end

function DataEditor:BuildSpellInspectorScalingRows(component)
    local rows = {}
    local scaling = component and component.effect and component.effect.statScaling or {}
    for index = 1, #scaling do
        local entry = scaling[index]
        rows[#rows + 1] = {
            rowIndex = index,
            statName = self:ResolveSpellInspectorReferenceLabel("stats", entry and entry.statRef or ""),
            coefficientText = tostring(entry and entry.coefficient or 0),
        }
    end
    return rows
end

function DataEditor:RefreshSpellInspectorComponentsTable()
    local _, spell = self:GetSelectedSpellAndDataset()
    local rows = self:BuildSpellInspectorComponentRows(spell)

    if self.SpellInspectorComponentsScroll and self.SpellInspectorComponentsScroll.SetItems then
        self.SpellInspectorComponentsScroll:SetItems(rows)
    end

    local selectedIndex = tonumber(self.SelectedSpellInspectorComponentIndex)
    if not selectedIndex or not rows[selectedIndex] then
        self.SelectedSpellInspectorComponentIndex = rows[1] and 1 or nil
    end
end

function DataEditor:RefreshSpellInspectorScalingTable()
    local component = self:GetSelectedSpellInspectorComponent()
    local rows = self:BuildSpellInspectorScalingRows(component)

    if self.SpellInspectorScalingScroll and self.SpellInspectorScalingScroll.SetItems then
        self.SpellInspectorScalingScroll:SetItems(rows)
    end
end

function DataEditor:BuildSpellInspectorComponentsPage(page)
    local function handleMouseWheel(_, delta)
        local _, maxValue = self.SpellInspectorComponentsScrollBar:GetMinMaxValues()
        local current = self.SpellInspectorComponentsScrollBar:GetValue() or 0
        local nextValue = math.max(0, math.min(maxValue or 0, current - ((delta or 0) * 24)))
        self.SpellInspectorComponentsScrollBar:SetValue(nextValue)
    end

    local function attachMouseWheel(target)
        local frame = target and target.GetFrame and target:GetFrame() or target
        if not frame then
            return
        end

        if frame.EnableMouseWheel then
            frame:EnableMouseWheel(true)
        end

        if frame.HookScript then
            frame:HookScript("OnMouseWheel", handleMouseWheel)
        elseif frame.SetScript then
            frame:SetScript("OnMouseWheel", handleMouseWheel)
        end
    end

    self.SpellInspectorComponentsScrollFrame = CreateFrame("ScrollFrame", "RPEDataEditorSpellInspectorComponentsScrollFrame", page)
    self.SpellInspectorComponentsScrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    self.SpellInspectorComponentsScrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -20, 0)
    self.SpellInspectorComponentsScrollFrame:EnableMouseWheel(true)
    self.SpellInspectorComponentsScrollFrame:SetClipsChildren(true)
    attachMouseWheel(page)
    attachMouseWheel(self.SpellInspectorComponentsScrollFrame)

    self.SpellInspectorComponentsScrollBar = CreateFrame("Slider", "RPEDataEditorSpellInspectorComponentsScrollBar", page)
    self.SpellInspectorComponentsScrollBar:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, -2)
    self.SpellInspectorComponentsScrollBar:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 2)
    self.SpellInspectorComponentsScrollBar:SetOrientation("VERTICAL")
    self.SpellInspectorComponentsScrollBar:SetMinMaxValues(0, 0)
    self.SpellInspectorComponentsScrollBar:SetValueStep(12)
    if self.SpellInspectorComponentsScrollBar.SetObeyStepOnDrag then
        self.SpellInspectorComponentsScrollBar:SetObeyStepOnDrag(true)
    end
    self.SpellInspectorComponentsScrollBar:SetWidth(12)

    self.SpellInspectorComponentsScrollBarTrack = self.SpellInspectorComponentsScrollBarTrack or self.SpellInspectorComponentsScrollBar:CreateTexture(nil, "BACKGROUND")
    self.SpellInspectorComponentsScrollBarTrack:SetAllPoints(self.SpellInspectorComponentsScrollBar)
    local trackColor = UI.ResolveColor(nil, "scrollbar.track")
    self.SpellInspectorComponentsScrollBarTrack:SetColorTexture(trackColor.r or 0.08, trackColor.g or 0.09, trackColor.b or 0.11, trackColor.a or 0.95)

    self.SpellInspectorComponentsScrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = self.SpellInspectorComponentsScrollBar.GetThumbTexture and self.SpellInspectorComponentsScrollBar:GetThumbTexture() or nil
    if thumb and thumb.SetVertexColor then
        local thumbColor = UI.ResolveColor(nil, "scrollbar.thumb")
        thumb:SetVertexColor(thumbColor.r or 0.42, thumbColor.g or 0.46, thumbColor.b or 0.52, thumbColor.a or 1)
    end
    self.SpellInspectorComponentsScrollBar:SetValue(0)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, self.SpellInspectorComponentsScrollFrame, "RPEDataEditorSpellInspectorComponentsLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        autoSize = true,
    })
    root:GetFrame():SetPoint("TOPLEFT", self.SpellInspectorComponentsScrollFrame, "TOPLEFT", 0, 0)
    root:GetFrame():SetPoint("TOPRIGHT", self.SpellInspectorComponentsScrollFrame, "TOPRIGHT", 0, 0)
    self.SpellInspectorComponentsScrollFrame:SetScrollChild(root:GetFrame())

    self.SpellInspectorComponentsScrollBar:SetScript("OnValueChanged", function(_, value)
        self.SpellInspectorComponentsScrollFrame:SetVerticalScroll(value or 0)
    end)
    self.SpellInspectorComponentsScrollFrame:SetScript("OnMouseWheel", handleMouseWheel)
    self.SpellInspectorComponentsScrollFrame:SetScript("OnSizeChanged", function(scrollFrame)
        local width = math.max(1, (scrollFrame:GetWidth() or self.SpellInspectorFieldWidth) - 4)
        root:GetFrame():SetWidth(width)
        if root.RefreshLayout then
            root:RefreshLayout()
        end
    end)
    attachMouseWheel(root)

    self.SpellInspectorComponentsRoot = root

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorComponentsLabel", "Components"))

    self.SpellInspectorComponentsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorSpellInspectorComponentsPanel", {
        width = self.SpellInspectorFieldWidth,
        height = 74,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.SpellInspectorComponentsPanel)
    attachMouseWheel(self.SpellInspectorComponentsPanel)

    self.SpellInspectorComponentsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorSpellInspectorComponentsScroll",
        width = self.SpellInspectorFieldWidth,
        height = 72,
        visibleRows = 4,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 124,
        statusWidth = 90,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.SpellInspectorComponentsScroll:SetParent(self.SpellInspectorComponentsPanel:GetContentFrame())
    self.SpellInspectorComponentsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetCategory then
            row:SetCategory(item and item.title or "")
        end
        if row.SetStatus then
            row:SetStatus(item and item.detail or "")
        end
        if row.SetDetail then
            row:SetDetail("")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedSpellInspectorComponentIndex(itemIndex)
                    self:RefreshSpellInspectorPage()
                elseif button == "RightButton" then
                    self:ShowSpellInspectorComponentContextMenu(frame, item)
                end
            end)
        end
    end)
    self.SpellInspectorComponentsScroll:Create()
    UI.Utils.AnchorFill(self.SpellInspectorComponentsScroll, self.SpellInspectorComponentsPanel:GetContentFrame(), 0, 0, 0, 0)
    attachMouseWheel(self.SpellInspectorComponentsScroll)

    self.SpellInspectorComponentToolbar = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorSpellInspectorComponentToolbar", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.SpellInspectorComponentToolbar)
    attachMouseWheel(self.SpellInspectorComponentToolbar)

    self.SpellInspectorAddComponentButton = UI.CreateButton(self.SpellInspectorComponentToolbar:GetFrame(), "RPEDataEditorSpellInspectorAddComponentButton", "Add Component", 92, function()
        self:CommitSelectedSpell(function(spell)
            spell.components = spell.components or {}
            spell.components[#spell.components + 1] = {
                castPhase = "on_cast_end",
                target = { type = "single", requiresTarget = true, targetDisposition = "enemy", minTargets = 1, maxTargets = 1 },
                effect = { type = "damage" },
            }
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.SpellInspectorComponentToolbar:AddChild(self.SpellInspectorAddComponentButton)
    attachMouseWheel(self.SpellInspectorAddComponentButton)

    local function createGroup(name, labelText, height)
        local groupHeight = 12 + 2 + (height or self.SpellInspectorControlHeight)
        local group = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), name, {
            width = self.SpellInspectorFieldWidth,
            height = groupHeight,
            spacing = 2,
            fitChildrenWidth = true,
            fitChildrenHeight = false,
        })
        group._visibleHeight = groupHeight
        root:AddChild(group)
        group:AddChild(self:BuildSpellInspectorLabel(group:GetFrame(), name .. "Label", labelText))
        attachMouseWheel(group)
        return group
    end

    self.SpellInspectorComponentPhaseGroup = createGroup("RPEDataEditorSpellInspectorComponentPhaseGroup", "Cast Phase", 18)
    self.SpellInspectorComponentPhaseDropdown = UI.CreateDropdown(self.SpellInspectorComponentPhaseGroup:GetFrame(), "RPEDataEditorSpellInspectorComponentPhaseDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        items = self:GetSpellInspectorCastPhaseItems(),
        onValueChanged = function(value)
            if self._refreshingSpellInspector then
                return
            end

            local component = self:GetSelectedSpellInspectorComponent()
            if component then
                self:CommitSelectedSpell(function()
                    component.castPhase = value
                end)
            end
        end,
    })
    self.SpellInspectorComponentPhaseGroup:AddChild(self.SpellInspectorComponentPhaseDropdown)
    attachMouseWheel(self.SpellInspectorComponentPhaseDropdown)

    self.SpellInspectorComponentCastingGroupGroup = createGroup("RPEDataEditorSpellInspectorComponentCastingGroupGroup", "Target Group", 12)
    self.SpellInspectorComponentCastingGroupText = self:BuildSpellInspectorLabel(
        self.SpellInspectorComponentCastingGroupGroup:GetFrame(),
        "RPEDataEditorSpellInspectorComponentCastingGroupText",
        "Enemy Target"
    )
    self.SpellInspectorComponentCastingGroupText._visibleHeight = 12
    self.SpellInspectorComponentCastingGroupGroup:AddChild(self.SpellInspectorComponentCastingGroupText)
    attachMouseWheel(self.SpellInspectorComponentCastingGroupText)

    self.SpellInspectorComponentTargetGroup = createGroup("RPEDataEditorSpellInspectorComponentTargetGroup", "Target", 102)
    self.SpellInspectorComponentTargetTypeDropdown = UI.CreateDropdown(self.SpellInspectorComponentTargetGroup:GetFrame(), "RPEDataEditorSpellInspectorComponentTargetTypeDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        items = self:GetSpellInspectorTargetTypeItems(),
        onValueChanged = function(value)
            if self._refreshingSpellInspector then
                return
            end

            local component = self:GetSelectedSpellInspectorComponent()
            if component then
                self:CommitSelectedSpell(function()
                    component.target = component.target or {}
                    component.target.type = value
                    if value == "caster" then
                        component.target.requiresTarget = false
                        component.target.targetDisposition = "ally"
                        component.target.minTargets = 1
                        component.target.maxTargets = 1
                        component.target.disableSelfCast = false
                    elseif value == "pet" then
                        component.target.requiresTarget = false
                        component.target.targetDisposition = "ally"
                        component.target.minTargets = 1
                        component.target.maxTargets = 1
                        component.target.disableSelfCast = false
                    elseif value == "last_attackers" then
                        component.target.requiresTarget = true
                        component.target.targetDisposition = "enemy"
                        component.target.minTargets = 1
                        component.target.maxTargets = 1
                        component.target.disableSelfCast = false
                    end
                end)
            end
        end,
    })
    self.SpellInspectorComponentTargetGroup:AddChild(self.SpellInspectorComponentTargetTypeDropdown)
    attachMouseWheel(self.SpellInspectorComponentTargetTypeDropdown)

    self.SpellInspectorComponentRequiresTargetCheckbox = self:CreateSpellInspectorCheckbox(self.SpellInspectorComponentTargetGroup:GetFrame(), "RPEDataEditorSpellInspectorComponentRequiresTargetCheckbox", "Requires Target", false, function(checked)
        if self._refreshingSpellInspector then
            return
        end

        local component = self:GetSelectedSpellInspectorComponent()
        if component then
            self:CommitSelectedSpell(function()
                component.target = component.target or {}
                component.target.requiresTarget = checked == true
            end)
        end
    end)
    self.SpellInspectorComponentTargetGroup:AddChild(self.SpellInspectorComponentRequiresTargetCheckbox)
    attachMouseWheel(self.SpellInspectorComponentRequiresTargetCheckbox)

    self.SpellInspectorComponentDisableSelfCastCheckbox = self:CreateSpellInspectorCheckbox(self.SpellInspectorComponentTargetGroup:GetFrame(), "RPEDataEditorSpellInspectorComponentDisableSelfCastCheckbox", "Disable Self-Cast", false, function(checked)
        if self._refreshingSpellInspector then
            return
        end

        local component = self:GetSelectedSpellInspectorComponent()
        if component then
            self:CommitSelectedSpell(function()
                component.target = component.target or {}
                component.target.disableSelfCast = checked == true
            end)
        end
    end)
    self.SpellInspectorComponentTargetGroup:AddChild(self.SpellInspectorComponentDisableSelfCastCheckbox)
    attachMouseWheel(self.SpellInspectorComponentDisableSelfCastCheckbox)

    self.SpellInspectorComponentTargetDispositionDropdown = UI.CreateDropdown(self.SpellInspectorComponentTargetGroup:GetFrame(), "RPEDataEditorSpellInspectorComponentTargetDispositionDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        items = self:GetSpellInspectorTargetDispositionItems(),
        onValueChanged = function(value)
            if self._refreshingSpellInspector then
                return
            end

            local component = self:GetSelectedSpellInspectorComponent()
            if component then
                self:CommitSelectedSpell(function()
                    component.target = component.target or {}
                    component.target.targetDisposition = value
                end)
            end
        end,
    })
    self.SpellInspectorComponentTargetGroup:AddChild(self.SpellInspectorComponentTargetDispositionDropdown)
    attachMouseWheel(self.SpellInspectorComponentTargetDispositionDropdown)

    self.SpellInspectorComponentTargetCountRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.SpellInspectorComponentTargetGroup:GetFrame(), "RPEDataEditorSpellInspectorComponentTargetCountRow", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.SpellInspectorComponentTargetGroup:AddChild(self.SpellInspectorComponentTargetCountRow)
    attachMouseWheel(self.SpellInspectorComponentTargetCountRow)

    self.SpellInspectorComponentMinTargetsInput = UI.CreateTextInput(self.SpellInspectorComponentTargetCountRow:GetFrame(), "RPEDataEditorSpellInspectorComponentMinTargetsInput", {
        width = math.floor((self.SpellInspectorFieldWidth - 4) / 2),
        height = 18,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SpellInspectorComponentTargetCountRow:AddChild(self.SpellInspectorComponentMinTargetsInput)
    attachMouseWheel(self.SpellInspectorComponentMinTargetsInput)

    self.SpellInspectorComponentMaxTargetsInput = UI.CreateTextInput(self.SpellInspectorComponentTargetCountRow:GetFrame(), "RPEDataEditorSpellInspectorComponentMaxTargetsInput", {
        width = math.floor((self.SpellInspectorFieldWidth - 4) / 2),
        height = 18,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SpellInspectorComponentTargetCountRow:AddChild(self.SpellInspectorComponentMaxTargetsInput)
    attachMouseWheel(self.SpellInspectorComponentMaxTargetsInput)

    self.SpellInspectorEffectTypeGroup = createGroup("RPEDataEditorSpellInspectorEffectTypeGroup", "Effect Type", 18)
    self.SpellInspectorEffectTypeDropdown = UI.CreateDropdown(self.SpellInspectorEffectTypeGroup:GetFrame(), "RPEDataEditorSpellInspectorEffectTypeDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        items = self:GetSpellInspectorEffectTypeItems(),
        onValueChanged = function(value)
            if self._refreshingSpellInspector then
                return
            end

            local component = self:GetSelectedSpellInspectorComponent()
            if component then
                self:CommitSelectedSpell(function()
                    local nextEffect = shallowCloneTable(component.effect)
                    nextEffect.type = value
                    if value == "apply_aura" then
                        nextEffect.stacks = tonumber(nextEffect.stacks or nextEffect.auraStacks) or 1
                        nextEffect.statScaling = nil
                        nextEffect.alwaysHits = nil
                        nextEffect.applyAura = nil
                    elseif value == "remove_aura" then
                        nextEffect.stacks = tonumber(nextEffect.stacks or nextEffect.auraStacks) or 1
                        nextEffect.baseDamage = nil
                        nextEffect.baseHealing = nil
                        nextEffect.basePower = nil
                        nextEffect.threatCoefficient = nil
                        nextEffect.weaponDamageMode = nil
                        nextEffect.weaponDamageCoefficient = nil
                        nextEffect.statScaling = nil
                        nextEffect.damageSchoolRefs = nil
                        nextEffect.hitType = nil
                        nextEffect.damageType = nil
                        nextEffect.alwaysHits = nil
                        nextEffect.usesProjectile = nil
                        nextEffect.projectilePath = nil
                        nextEffect.projectileSpeed = nil
                        nextEffect.applyAura = nil
                        nextEffect.auraStacks = nil
                        nextEffect.duration = nil
                        nextEffect.resourceRef = nil
                        nextEffect.amount = nil
                        nextEffect.unitRef = nil
                    elseif value == "interrupt" or value == "revert" then
                        nextEffect.baseDamage = nil
                        nextEffect.baseHealing = nil
                        nextEffect.basePower = nil
                        nextEffect.threatCoefficient = nil
                        nextEffect.weaponDamageMode = nil
                        nextEffect.weaponDamageCoefficient = nil
                        nextEffect.statScaling = nil
                        nextEffect.damageSchoolRefs = nil
                        nextEffect.hitType = nil
                        nextEffect.damageType = nil
                        nextEffect.alwaysHits = nil
                        nextEffect.usesProjectile = nil
                        nextEffect.projectilePath = nil
                        nextEffect.projectileSpeed = nil
                        nextEffect.applyAura = nil
                        nextEffect.auraRef = nil
                        nextEffect.auraStacks = nil
                        nextEffect.stacks = nil
                        nextEffect.duration = nil
                        nextEffect.resourceRef = nil
                        nextEffect.amount = nil
                        nextEffect.unitRef = nil
                    elseif value == "summon_pet" then
                        nextEffect.baseDamage = nil
                        nextEffect.baseHealing = nil
                        nextEffect.basePower = nil
                        nextEffect.threatCoefficient = nil
                        nextEffect.weaponDamageMode = nil
                        nextEffect.weaponDamageCoefficient = nil
                        nextEffect.statScaling = nil
                        nextEffect.damageSchoolRefs = nil
                        nextEffect.hitType = nil
                        nextEffect.damageType = nil
                        nextEffect.alwaysHits = nil
                        nextEffect.usesProjectile = nil
                        nextEffect.projectilePath = nil
                        nextEffect.projectileSpeed = nil
                        nextEffect.applyAura = nil
                        nextEffect.auraRef = nil
                        nextEffect.auraStacks = nil
                        nextEffect.stacks = nil
                        nextEffect.duration = nil
                        nextEffect.resourceRef = nil
                        nextEffect.amount = nil
                        nextEffect.unitRef = nextEffect.unitRef or nil
                    end
                    component.effect = nextEffect
                    if value == "summon_pet" then
                        component.target = {
                            type = "caster",
                            requiresTarget = false,
                            targetDisposition = "ally",
                            minTargets = 1,
                            maxTargets = 1,
                        }
                    elseif value == "interrupt" or value == "revert" then
                        component.target = component.target or {}
                        if tostring(component.target.type or "") == "pet" then
                            component.target.type = "single"
                        end
                    end
                end)
            end
        end,
    })
    self.SpellInspectorEffectTypeGroup:AddChild(self.SpellInspectorEffectTypeDropdown)
    attachMouseWheel(self.SpellInspectorEffectTypeDropdown)

    self.SpellInspectorBaseDamageGroup = createGroup("RPEDataEditorSpellInspectorBaseDamageGroup", "Base Damage")
    self.SpellInspectorBaseDamageInput = UI.CreateTextInput(self.SpellInspectorBaseDamageGroup:GetFrame(), "RPEDataEditorSpellInspectorBaseDamageInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitBaseDamage = function()
        local component = self:GetSelectedSpellInspectorComponent()
        if component then
            self:CommitSelectedSpell(function()
                component.effect.baseDamage = tonumber(self.SpellInspectorBaseDamageInput:GetText()) or 0
            end)
        end
    end
    self.SpellInspectorBaseDamageInput:SetScript("OnEnterPressed", commitBaseDamage)
    self.SpellInspectorBaseDamageInput:SetScript("OnEditFocusLost", commitBaseDamage)
    self.SpellInspectorBaseDamageGroup:AddChild(self.SpellInspectorBaseDamageInput)

    self.SpellInspectorThreatCoefficientGroup = createGroup("RPEDataEditorSpellInspectorThreatCoefficientGroup", "Threat Coefficient")
    self.SpellInspectorThreatCoefficientInput = UI.CreateTextInput(self.SpellInspectorThreatCoefficientGroup:GetFrame(), "RPEDataEditorSpellInspectorThreatCoefficientInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitThreatCoefficient = function()
        local component = self:GetSelectedSpellInspectorComponent()
        if component then
            self:CommitSelectedSpell(function()
                component.effect.threatCoefficient = tonumber(self.SpellInspectorThreatCoefficientInput:GetText()) or 1
            end)
        end
    end
    self.SpellInspectorThreatCoefficientInput:SetScript("OnEnterPressed", commitThreatCoefficient)
    self.SpellInspectorThreatCoefficientInput:SetScript("OnEditFocusLost", commitThreatCoefficient)
    self.SpellInspectorThreatCoefficientGroup:AddChild(self.SpellInspectorThreatCoefficientInput)

    self.SpellInspectorBaseHealingGroup = createGroup("RPEDataEditorSpellInspectorBaseHealingGroup", "Base Healing")
    self.SpellInspectorBaseHealingInput = UI.CreateTextInput(self.SpellInspectorBaseHealingGroup:GetFrame(), "RPEDataEditorSpellInspectorBaseHealingInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitBaseHealing = function()
        local component = self:GetSelectedSpellInspectorComponent()
        if component then
            self:CommitSelectedSpell(function()
                component.effect.baseHealing = tonumber(self.SpellInspectorBaseHealingInput:GetText()) or 0
            end)
        end
    end
    self.SpellInspectorBaseHealingInput:SetScript("OnEnterPressed", commitBaseHealing)
    self.SpellInspectorBaseHealingInput:SetScript("OnEditFocusLost", commitBaseHealing)
    self.SpellInspectorBaseHealingGroup:AddChild(self.SpellInspectorBaseHealingInput)

    self.SpellInspectorBasePowerGroup = createGroup("RPEDataEditorSpellInspectorBasePowerGroup", "Base Power")
    self.SpellInspectorBasePowerInput = UI.CreateTextInput(self.SpellInspectorBasePowerGroup:GetFrame(), "RPEDataEditorSpellInspectorBasePowerInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitBasePower = function()
        local component = self:GetSelectedSpellInspectorComponent()
        if component then
            self:CommitSelectedSpell(function()
                component.effect.basePower = tonumber(self.SpellInspectorBasePowerInput:GetText()) or 0
            end)
        end
    end
    self.SpellInspectorBasePowerInput:SetScript("OnEnterPressed", commitBasePower)
    self.SpellInspectorBasePowerInput:SetScript("OnEditFocusLost", commitBasePower)
    self.SpellInspectorBasePowerGroup:AddChild(self.SpellInspectorBasePowerInput)

    self.SpellInspectorWeaponDamageModeGroup = createGroup("RPEDataEditorSpellInspectorWeaponDamageModeGroup", "Weapon Damage Mode", 18)
    self.SpellInspectorWeaponDamageModeDropdown = UI.CreateDropdown(self.SpellInspectorWeaponDamageModeGroup:GetFrame(), "RPEDataEditorSpellInspectorWeaponDamageModeDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        items = self:GetSpellInspectorWeaponDamageModeItems(),
        onValueChanged = function(value)
            if self._refreshingSpellInspector then
                return
            end
            local component = self:GetSelectedSpellInspectorComponent()
            if component then
                self:CommitSelectedSpell(function()
                    component.effect.weaponDamageMode = value
                end)
            end
        end,
    })
    self.SpellInspectorWeaponDamageModeGroup:AddChild(self.SpellInspectorWeaponDamageModeDropdown)

    self.SpellInspectorWeaponDamageCoefficientGroup = createGroup("RPEDataEditorSpellInspectorWeaponDamageCoefficientGroup", "Weapon Damage Coefficient")
    self.SpellInspectorWeaponDamageCoefficientInput = UI.CreateTextInput(self.SpellInspectorWeaponDamageCoefficientGroup:GetFrame(), "RPEDataEditorSpellInspectorWeaponDamageCoefficientInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitWeaponDamageCoefficient = function()
        local component = self:GetSelectedSpellInspectorComponent()
        if component then
            self:CommitSelectedSpell(function()
                component.effect.weaponDamageCoefficient = tonumber(self.SpellInspectorWeaponDamageCoefficientInput:GetText()) or 1
            end)
        end
    end
    self.SpellInspectorWeaponDamageCoefficientInput:SetScript("OnEnterPressed", commitWeaponDamageCoefficient)
    self.SpellInspectorWeaponDamageCoefficientInput:SetScript("OnEditFocusLost", commitWeaponDamageCoefficient)
    self.SpellInspectorWeaponDamageCoefficientGroup:AddChild(self.SpellInspectorWeaponDamageCoefficientInput)

    self.SpellInspectorDamageSchoolsGroup = createGroup("RPEDataEditorSpellInspectorDamageSchoolsGroup", "Damage Schools", 18)
    self.SpellInspectorDamageSchoolsDropdown = UI.CreateDropdown(self.SpellInspectorDamageSchoolsGroup:GetFrame(), "RPEDataEditorSpellInspectorDamageSchoolsDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        multiSelect = true,
        items = self:BuildSpellInspectorDamageSchoolsAcrossDatasets(),
        onValueChanged = function()
            if self._refreshingSpellInspector then
                return
            end
            local component = self:GetSelectedSpellInspectorComponent()
            if component then
                self:CommitSelectedSpell(function()
                    component.effect.damageSchoolRefs = self.SpellInspectorDamageSchoolsDropdown:GetSelectedValues()
                end)
            end
        end,
    })
    self.SpellInspectorDamageSchoolsGroup:AddChild(self.SpellInspectorDamageSchoolsDropdown)
    attachMouseWheel(self.SpellInspectorDamageSchoolsDropdown)

    self.SpellInspectorScalingGroup = createGroup("RPEDataEditorSpellInspectorScalingGroup", "Stat Scaling", 110)
    self.SpellInspectorScalingPanel = UI.CreatePanel(self.SpellInspectorScalingGroup:GetFrame(), "RPEDataEditorSpellInspectorScalingPanel", {
        width = self.SpellInspectorFieldWidth,
        height = 56,
        contentInset = 1,
        showBorder = true,
    })
    self.SpellInspectorScalingGroup:AddChild(self.SpellInspectorScalingPanel)
    attachMouseWheel(self.SpellInspectorScalingPanel)

    self.SpellInspectorScalingScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorSpellInspectorScalingScroll",
        width = self.SpellInspectorFieldWidth,
        height = 54,
        visibleRows = 3,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.SpellInspectorScalingScroll:SetParent(self.SpellInspectorScalingPanel:GetContentFrame())
    self.SpellInspectorScalingScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "statName", width = 150, justifyH = "LEFT" },
                { key = "coefficientText", width = 44, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowSpellInspectorScalingContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.SpellInspectorScalingScroll:Create()
    UI.Utils.AnchorFill(self.SpellInspectorScalingScroll, self.SpellInspectorScalingPanel:GetContentFrame(), 0, 0, 0, 0)
    attachMouseWheel(self.SpellInspectorScalingScroll)

    self.SpellInspectorPendingScalingRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.SpellInspectorScalingGroup:GetFrame(), "RPEDataEditorSpellInspectorPendingScalingRow", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.SpellInspectorScalingGroup:AddChild(self.SpellInspectorPendingScalingRow)
    attachMouseWheel(self.SpellInspectorPendingScalingRow)

    self.SpellInspectorPendingScalingStatDropdown = UI.CreateDropdown(self.SpellInspectorPendingScalingRow:GetFrame(), "RPEDataEditorSpellInspectorPendingScalingStatDropdown", {
        width = 146,
        height = 18,
        items = self:BuildSpellInspectorStatsAcrossDatasets(),
    })
    self.SpellInspectorPendingScalingRow:AddChild(self.SpellInspectorPendingScalingStatDropdown)
    attachMouseWheel(self.SpellInspectorPendingScalingStatDropdown)

    self.SpellInspectorPendingScalingCoefficientInput = UI.CreateTextInput(self.SpellInspectorPendingScalingRow:GetFrame(), "RPEDataEditorSpellInspectorPendingScalingCoefficientInput", {
        width = 44,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SpellInspectorPendingScalingRow:AddChild(self.SpellInspectorPendingScalingCoefficientInput)
    attachMouseWheel(self.SpellInspectorPendingScalingCoefficientInput)

    self.SpellInspectorAddScalingButton = UI.CreateButton(self.SpellInspectorPendingScalingRow:GetFrame(), "RPEDataEditorSpellInspectorAddScalingButton", "Add", 36, function()
        local component = self:GetSelectedSpellInspectorComponent()
        if not component or tostring(component.effect and component.effect.type or "") == "apply_aura" then
            return
        end

        local statRef = self.SpellInspectorPendingScalingStatDropdown and self.SpellInspectorPendingScalingStatDropdown.GetSelectedValue and self.SpellInspectorPendingScalingStatDropdown:GetSelectedValue() or ""
        if statRef == "" then
            return
        end

        local coefficient = tonumber(self.SpellInspectorPendingScalingCoefficientInput and self.SpellInspectorPendingScalingCoefficientInput:GetText()) or 0
        self:CommitSelectedSpell(function()
            component.effect.statScaling = component.effect.statScaling or {}
            component.effect.statScaling[#component.effect.statScaling + 1] = {
                statRef = statRef,
                coefficient = coefficient,
            }
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.SpellInspectorPendingScalingRow:AddChild(self.SpellInspectorAddScalingButton)
    attachMouseWheel(self.SpellInspectorAddScalingButton)

    self.SpellInspectorAlwaysHitsCheckbox = self:CreateSpellInspectorCheckbox(root:GetFrame(), "RPEDataEditorSpellInspectorAlwaysHitsCheckbox", "Always Hits", false, function(checked)
        if self._refreshingSpellInspector then
            return
        end
        local component = self:GetSelectedSpellInspectorComponent()
        if component then
            self:CommitSelectedSpell(function()
                component.effect.alwaysHits = checked == true
            end)
        end
    end)
    self.SpellInspectorAlwaysHitsCheckbox._visibleHeight = 18
    root:AddChild(self.SpellInspectorAlwaysHitsCheckbox)
    attachMouseWheel(self.SpellInspectorAlwaysHitsCheckbox)

    self.SpellInspectorHitTypeGroup = createGroup("RPEDataEditorSpellInspectorHitTypeGroup", "Hit Type", 18)
    self.SpellInspectorHitTypeDropdown = UI.CreateDropdown(self.SpellInspectorHitTypeGroup:GetFrame(), "RPEDataEditorSpellInspectorHitTypeDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        items = self:GetSpellInspectorHitTypeItems(),
        onValueChanged = function(value)
            if self._refreshingSpellInspector then
                return
            end
            local component = self:GetSelectedSpellInspectorComponent()
            if component then
                self:CommitSelectedSpell(function()
                    component.effect.hitType = value
                end)
            end
        end,
    })
    self.SpellInspectorHitTypeGroup:AddChild(self.SpellInspectorHitTypeDropdown)
    attachMouseWheel(self.SpellInspectorHitTypeDropdown)

    self.SpellInspectorDamageTypeGroup = createGroup("RPEDataEditorSpellInspectorDamageTypeGroup", "Damage Type", 18)
    self.SpellInspectorDamageTypeDropdown = UI.CreateDropdown(self.SpellInspectorDamageTypeGroup:GetFrame(), "RPEDataEditorSpellInspectorDamageTypeDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        items = self:GetSpellInspectorDamageTypeItems(),
        onValueChanged = function(value)
            if self._refreshingSpellInspector then
                return
            end
            local component = self:GetSelectedSpellInspectorComponent()
            if component then
                self:CommitSelectedSpell(function()
                    component.effect.damageType = value
                end)
            end
        end,
    })
    self.SpellInspectorDamageTypeGroup:AddChild(self.SpellInspectorDamageTypeDropdown)
    attachMouseWheel(self.SpellInspectorDamageTypeDropdown)

    self.SpellInspectorApplyAuraCheckbox = self:CreateSpellInspectorCheckbox(root:GetFrame(), "RPEDataEditorSpellInspectorApplyAuraCheckbox", "Apply Aura", false, function(checked)
        if self._refreshingSpellInspector then
            return
        end
        local component = self:GetSelectedSpellInspectorComponent()
        if component then
            self:CommitSelectedSpell(function()
                component.effect.applyAura = checked == true
            end)
        end
    end)
    self.SpellInspectorApplyAuraCheckbox._visibleHeight = 18
    root:AddChild(self.SpellInspectorApplyAuraCheckbox)
    attachMouseWheel(self.SpellInspectorApplyAuraCheckbox)

    self.SpellInspectorAuraGroup = createGroup("RPEDataEditorSpellInspectorAuraGroup", "Aura", 18)
    self.SpellInspectorAuraDropdown = UI.CreateDropdown(self.SpellInspectorAuraGroup:GetFrame(), "RPEDataEditorSpellInspectorAuraDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        items = self:BuildSpellInspectorAurasAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingSpellInspector then
                return
            end

            local component = self:GetSelectedSpellInspectorComponent()
            if component then
                self:CommitSelectedSpell(function()
                    component.effect.auraRef = value ~= "" and value or nil
                end)
            end
        end,
    })
    self.SpellInspectorAuraGroup:AddChild(self.SpellInspectorAuraDropdown)
    attachMouseWheel(self.SpellInspectorAuraDropdown)

    local function createEffectTextGroup(groupName, labelText, fieldName)
        local group = createGroup(groupName, labelText)
        self[fieldName] = UI.CreateTextInput(group:GetFrame(), fieldName, {
            width = self.SpellInspectorFieldWidth,
            height = self.SpellInspectorControlHeight,
            text = "",
            borderColor = UI.ResolveColor(nil, "panel.border"),
        })
        group:AddChild(self[fieldName])
        attachMouseWheel(self[fieldName])
        return group
    end

    self.SpellInspectorAuraStacksGroup = createEffectTextGroup("RPEDataEditorSpellInspectorAuraStacksGroup", "Aura Stacks", "SpellInspectorAuraStacksInput")
    self.SpellInspectorApplyAuraDurationGroup = createEffectTextGroup("RPEDataEditorSpellInspectorApplyAuraDurationGroup", "Aura Duration", "SpellInspectorApplyAuraDurationInput")
    self.SpellInspectorResourceAmountGroup = createEffectTextGroup("RPEDataEditorSpellInspectorResourceAmountGroup", "Resource Amount", "SpellInspectorResourceAmountInput")

    self.SpellInspectorResourceEffectGroup = createGroup("RPEDataEditorSpellInspectorResourceEffectGroup", "Resource", 18)
    self.SpellInspectorResourceEffectDropdown = UI.CreateDropdown(self.SpellInspectorResourceEffectGroup:GetFrame(), "RPEDataEditorSpellInspectorResourceEffectDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        items = self:BuildSpellInspectorResourcesAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingSpellInspector then
                return
            end
            local component = self:GetSelectedSpellInspectorComponent()
            if component then
                self:CommitSelectedSpell(function()
                    component.effect.resourceRef = value ~= "" and value or nil
                end)
            end
        end,
    })
    self.SpellInspectorResourceEffectGroup:AddChild(self.SpellInspectorResourceEffectDropdown)
    attachMouseWheel(self.SpellInspectorResourceEffectDropdown)

    self.SpellInspectorSummonPetUnitGroup = createGroup("RPEDataEditorSpellInspectorSummonPetUnitGroup", "Summoned Unit", 18)
    self.SpellInspectorSummonPetUnitDropdown = UI.CreateDropdown(self.SpellInspectorSummonPetUnitGroup:GetFrame(), "RPEDataEditorSpellInspectorSummonPetUnitDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        items = self:BuildSpellInspectorUnitsAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingSpellInspector then
                return
            end

            local component = self:GetSelectedSpellInspectorComponent()
            if component then
                self:CommitSelectedSpell(function()
                    component.effect.unitRef = value ~= "" and value or nil
                end)
            end
        end,
    })
    self.SpellInspectorSummonPetUnitGroup:AddChild(self.SpellInspectorSummonPetUnitDropdown)
    attachMouseWheel(self.SpellInspectorSummonPetUnitDropdown)

    self.SpellInspectorCasterEventsGroup = createGroup("RPEDataEditorSpellInspectorCasterEventsGroup", "Caster Events (Spell)", 18)
    self.SpellInspectorCasterEventsDropdown = UI.CreateDropdown(self.SpellInspectorCasterEventsGroup:GetFrame(), "RPEDataEditorSpellInspectorCasterEventsDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        multiSelect = true,
        items = self:GetSpellInspectorEventItems(),
        onValueChanged = function()
            if self._refreshingSpellInspector then
                return
            end
            self:CommitSelectedSpell(function(spell)
                    spell.casterEvents = self.SpellInspectorCasterEventsDropdown:GetSelectedValues()
                end)
        end,
    })
    self.SpellInspectorCasterEventsGroup:AddChild(self.SpellInspectorCasterEventsDropdown)
    attachMouseWheel(self.SpellInspectorCasterEventsDropdown)

    self.SpellInspectorTargetEventsGroup = createGroup("RPEDataEditorSpellInspectorTargetEventsGroup", "Target Events", 18)
    self.SpellInspectorTargetEventsDropdown = UI.CreateDropdown(self.SpellInspectorTargetEventsGroup:GetFrame(), "RPEDataEditorSpellInspectorTargetEventsDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        multiSelect = true,
        items = self:GetSpellInspectorEventItems(),
        onValueChanged = function()
            if self._refreshingSpellInspector then
                return
            end
            local component = self:GetSelectedSpellInspectorComponent()
            if component then
                self:CommitSelectedSpell(function()
                    component.effect.targetEvents = self.SpellInspectorTargetEventsDropdown:GetSelectedValues()
                end)
            end
        end,
    })
    self.SpellInspectorTargetEventsGroup:AddChild(self.SpellInspectorTargetEventsDropdown)
    attachMouseWheel(self.SpellInspectorTargetEventsDropdown)

    local function bindInput(fieldName, callback)
        self[fieldName]:SetScript("OnEnterPressed", callback)
        self[fieldName]:SetScript("OnEditFocusLost", callback)
    end

    bindInput("SpellInspectorComponentMinTargetsInput", function()
        local component = self:GetSelectedSpellInspectorComponent()
        if component then
            self:CommitSelectedSpell(function()
                component.target = component.target or {}
                component.target.minTargets = tonumber(self.SpellInspectorComponentMinTargetsInput:GetText()) or 0
            end)
        end
    end)
    bindInput("SpellInspectorComponentMaxTargetsInput", function()
        local component = self:GetSelectedSpellInspectorComponent()
        if component then
            self:CommitSelectedSpell(function()
                component.target = component.target or {}
                component.target.maxTargets = tonumber(self.SpellInspectorComponentMaxTargetsInput:GetText()) or 0
            end)
        end
    end)

    bindInput("SpellInspectorAuraStacksInput", function()
        local component = self:GetSelectedSpellInspectorComponent()
        if component then
            self:CommitSelectedSpell(function()
                local stackCount = tonumber(self.SpellInspectorAuraStacksInput:GetText()) or 1
                component.effect.stacks = stackCount
                if tostring(component.effect.type or "damage") == "apply_aura" then
                    component.effect.auraStacks = nil
                else
                    component.effect.auraStacks = stackCount
                end
            end)
        end
    end)
    bindInput("SpellInspectorApplyAuraDurationInput", function()
        local component = self:GetSelectedSpellInspectorComponent()
        if component then
            self:CommitSelectedSpell(function()
                component.effect.duration = tonumber(self.SpellInspectorApplyAuraDurationInput:GetText()) or 12
            end)
        end
    end)
    bindInput("SpellInspectorResourceAmountInput", function()
        local component = self:GetSelectedSpellInspectorComponent()
        if component then
            self:CommitSelectedSpell(function()
                component.effect.amount = tonumber(self.SpellInspectorResourceAmountInput:GetText()) or 0
            end)
        end
    end)

    local function refreshScrollBounds()
        local frame = root:GetFrame()
        local viewportHeight = self.SpellInspectorComponentsScrollFrame and self.SpellInspectorComponentsScrollFrame:GetHeight() or 0
        local contentHeight = frame and frame:GetHeight() or 0
        local maxScroll = math.max(0, math.floor(contentHeight - viewportHeight + 0.5))
        self.SpellInspectorComponentsScrollBar:SetMinMaxValues(0, maxScroll)
        if self.SpellInspectorComponentsScrollBar.SetShown then
            self.SpellInspectorComponentsScrollBar:SetShown(maxScroll > 0)
        elseif maxScroll > 0 and self.SpellInspectorComponentsScrollBar.Show then
            self.SpellInspectorComponentsScrollBar:Show()
        elseif self.SpellInspectorComponentsScrollBar.Hide then
            self.SpellInspectorComponentsScrollBar:Hide()
        end
        if (self.SpellInspectorComponentsScrollBar:GetValue() or 0) > maxScroll then
            self.SpellInspectorComponentsScrollBar:SetValue(maxScroll)
        end
    end

    self.RefreshSpellInspectorComponentsScrollBounds = refreshScrollBounds
    root:GetFrame():SetScript("OnSizeChanged", refreshScrollBounds)
    self.SpellInspectorComponentsScrollFrame:SetScript("OnShow", refreshScrollBounds)
    refreshScrollBounds()
end
