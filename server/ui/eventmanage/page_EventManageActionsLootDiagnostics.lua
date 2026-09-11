local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}
Addon.Internal = Addon.Internal or {}

local EventManage = Addon.Server.UI.EventManage
local LootLogic = Addon.Internal.Loot or {}
local UI = Addon.UI or {}
local C = UI.Constants or {}

if type(EventManage) ~= "table" or EventManage._actionsLootDiagnosticsInstalled == true then
    return
end

local CONTENT_WIDTH = 480

local LOOT_VALIDATION_REASONS = {
    ["invalid-loot-table"] = true,
    ["unknown-loot-table"] = true,
    ["invalid-draw-count"] = true,
    ["no-loot-entries"] = true,
    ["invalid-entry"] = true,
    ["duplicate-entry-id"] = true,
    ["invalid-reward"] = true,
    ["unknown-item"] = true,
    ["unknown-currency"] = true,
    ["invalid-weight"] = true,
    ["invalid-quantity-range"] = true,
    ["loot-resolver-unavailable"] = true,
}

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeToken(value)
    return string.lower(trim(value))
end

local function pack(...)
    return { n = select("#", ...), ... }
end

local function formatNumber(value)
    local numeric = tonumber(value)
    if numeric == nil then
        return tostring(value == nil and "-" or value)
    end
    if numeric == math.floor(numeric) then
        return tostring(math.floor(numeric))
    end
    return tostring(numeric)
end

local function diagnosisLabel(diagnosis, fallbackRef)
    local name = trim(diagnosis and diagnosis.name)
    if name ~= "" then
        return name
    end
    local reference = trim(diagnosis and diagnosis.lootRef or fallbackRef)
    return reference ~= "" and reference or "-"
end

local function findDiagnosticEntry(diagnosis, entryIndex)
    for index = 1, #(diagnosis and diagnosis.entries or {}) do
        local row = diagnosis.entries[index]
        if tonumber(row and row.index) == tonumber(entryIndex) then
            return row
        end
    end
    return nil
end

local function formatDiagnosticFailure(reason, detail, diagnosis)
    if type(diagnosis) == "table"
        and diagnosis.valid ~= true
        and diagnosis.reason == reason
        and trim(diagnosis.message) ~= ""
    then
        return trim(diagnosis.message)
    end

    if LOOT_VALIDATION_REASONS[tostring(reason or "")] ~= true then
        return nil
    end
    if type(LootLogic.FormatLootDiagnosticIssue) ~= "function" then
        return nil
    end

    local entry = type(detail) == "table" and findDiagnosticEntry(diagnosis, detail.entryIndex) or nil
    return LootLogic.FormatLootDiagnosticIssue(reason, detail, entry)
end

local function setDiagnosticColor(element, token)
    if not element or type(element.SetTextColor) ~= "function" then
        return
    end
    local color = UI.ResolveColor and UI.ResolveColor(nil, token) or nil
    if type(color) == "table" then
        element:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
    end
end

local function buildDiagnosticStatusText(self)
    if normalizeToken(self.ActionsLootSourceType) ~= "loot_table" then
        return ""
    end

    local diagnosis = self.ActionsLootTableDiagnosis
    if type(diagnosis) ~= "table" then
        return "Loot Table diagnostics unavailable."
    end

    local label = diagnosisLabel(diagnosis, self.ActionsLootRef)
    if diagnosis.valid == true then
        return ("Loot Table: %s — VALID — Draws %s — Entries %d — Weight %s"):format(
            label,
            formatNumber(diagnosis.drawCount),
            math.max(0, math.floor(tonumber(diagnosis.entryCount) or 0)),
            formatNumber(diagnosis.totalWeight)
        )
    end

    local message = trim(diagnosis.message)
    if message == "" then
        message = tostring(diagnosis.reason or "invalid-loot-table")
    end
    return ("Loot Table: %s — INVALID — %s"):format(label, message)
end

local function addTooltipLine(text, r, g, b)
    if GameTooltip and type(GameTooltip.AddLine) == "function" then
        GameTooltip:AddLine(tostring(text or ""), r or 1, g or 1, b or 1, true)
    end
end

local function showDiagnosticTooltip(self, owner)
    local diagnosis = self.ActionsLootTableDiagnosis
    if normalizeToken(self.ActionsLootSourceType) ~= "loot_table"
        or type(diagnosis) ~= "table"
        or not GameTooltip
        or type(GameTooltip.SetOwner) ~= "function"
    then
        return
    end

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if type(GameTooltip.ClearLines) == "function" then
        GameTooltip:ClearLines()
    end

    addTooltipLine("Loot Table: " .. diagnosisLabel(diagnosis, self.ActionsLootRef))
    if diagnosis.valid == true then
        addTooltipLine("Status: VALID", 0.35, 0.9, 0.45)
    else
        addTooltipLine("Status: INVALID", 0.95, 0.35, 0.35)
    end
    addTooltipLine(("Draw Count: %s"):format(formatNumber(diagnosis.drawCount)))
    addTooltipLine(("Entry Count: %d"):format(math.max(0, math.floor(tonumber(diagnosis.entryCount) or 0))))
    addTooltipLine(("Total Weight: %s"):format(formatNumber(diagnosis.totalWeight)))

    for index = 1, #(diagnosis.entries or {}) do
        local entry = diagnosis.entries[index]
        local entryId = trim(entry and entry.id)
        local rewardType = trim(entry and entry.rewardType)
        local reference = trim(entry and entry.ref)
        local rewardName = trim(entry and entry.resolvedName)
        local identity = rewardName ~= "" and rewardName or (reference ~= "" and reference or "-")
        local quantity = ("%s-%s"):format(formatNumber(entry and entry.minQuantity), formatNumber(entry and entry.maxQuantity))
        local status = entry and entry.valid == true and "VALID" or "INVALID"
        addTooltipLine(("%d. [%s] %s %s — %s — Weight %s — Qty %s — %s"):format(
            tonumber(entry and entry.index) or index,
            entryId ~= "" and entryId or "-",
            rewardType ~= "" and rewardType or "-",
            reference ~= "" and reference or "-",
            identity,
            formatNumber(entry and entry.weight),
            quantity,
            status
        ), entry and entry.valid == true and 0.8 or 0.95, entry and entry.valid == true and 0.9 or 0.5, entry and entry.valid == true and 0.8 or 0.5)
        if entry and entry.valid ~= true and trim(entry.message) ~= "" then
            addTooltipLine("    " .. trim(entry.message), 0.95, 0.55, 0.55)
        end
    end

    if diagnosis.legacyItemsPresent == true then
        addTooltipLine("Legacy items data is preserved but is not executable Loot Table data.", 0.95, 0.9, 0.7)
    end
    if type(GameTooltip.Show) == "function" then
        GameTooltip:Show()
    end
end

function EventManage:RefreshActionLootDiagnostics()
    local text = self.ActionsLootDiagnosticText
    if not text then
        return false
    end

    local isTable = normalizeToken(self.ActionsLootSourceType) == "loot_table"
    text:SetText(buildDiagnosticStatusText(self))
    if not isTable then
        setDiagnosticColor(text, "text.muted")
        return true
    end

    local diagnosis = self.ActionsLootTableDiagnosis
    if type(diagnosis) == "table" and diagnosis.valid == true then
        setDiagnosticColor(text, "success")
    elseif type(diagnosis) == "table" then
        setDiagnosticColor(text, "danger")
    else
        setDiagnosticColor(text, "warning")
    end
    return true
end

local baseBuildActionLootGrant = EventManage.BuildActionLootGrant
if type(baseBuildActionLootGrant) == "function" then
    function EventManage:BuildActionLootGrant(...)
        local grant, reason, detail = baseBuildActionLootGrant(self, ...)
        self.ActionsLootTableDiagnosis = nil

        local sourceType = normalizeToken(type(grant) == "table" and grant.sourceType or self.ActionsLootSourceType)
        if sourceType ~= "loot_table" then
            return grant, reason, detail
        end

        local lootRef = trim(type(grant) == "table" and grant.lootRef or self.ActionsLootRef)
        if type(grant) ~= "table" then
            if reason == "unknown-loot-table" or reason == "invalid-loot-table" then
                local message = type(LootLogic.FormatLootDiagnosticIssue) == "function"
                    and LootLogic.FormatLootDiagnosticIssue(reason, detail or { lootRef = lootRef }, nil)
                    or "The selected Loot Table cannot be resolved."
                self.ActionsLootTableDiagnosis = {
                    valid = false,
                    reason = reason,
                    detail = detail or { lootRef = lootRef },
                    message = message,
                    lootRef = lootRef,
                    entries = {},
                    issues = {},
                }
            end
            return grant, reason, detail
        end

        if type(LootLogic.DiagnoseLootReference) ~= "function" then
            self.ActionsLootTableDiagnosis = {
                valid = false,
                reason = "loot-resolver-unavailable",
                detail = { reason = "diagnostics-unavailable" },
                message = "Loot Table diagnostics are unavailable.",
                lootRef = lootRef,
                entries = {},
                issues = {},
            }
            return nil, "loot-resolver-unavailable", self.ActionsLootTableDiagnosis.detail
        end

        local diagnosis = LootLogic.DiagnoseLootReference(lootRef)
        self.ActionsLootTableDiagnosis = diagnosis
        if type(diagnosis) ~= "table" or diagnosis.valid ~= true then
            return nil,
                type(diagnosis) == "table" and diagnosis.reason or "invalid-loot-table",
                type(diagnosis) == "table" and diagnosis.detail or { lootRef = lootRef }
        end
        return grant, reason, detail
    end
end

local baseRefreshActionLootSection = EventManage.RefreshActionLootSection
if type(baseRefreshActionLootSection) == "function" then
    function EventManage:RefreshActionLootSection(...)
        local results = pack(baseRefreshActionLootSection(self, ...))
        self:RefreshActionLootDiagnostics()
        return unpack(results, 1, results.n)
    end
end

local baseDistributeActionLoot = EventManage.DistributeActionLoot
if type(baseDistributeActionLoot) == "function" then
    function EventManage:DistributeActionLoot(...)
        local results = pack(baseDistributeActionLoot(self, ...))
        if results[1] == nil then
            local reason = results[2]
            local detail = results[3]
            local message = formatDiagnosticFailure(reason, detail, self.ActionsLootTableDiagnosis)
            if message and type(self.SetActionsStatus) == "function" then
                self:SetActionsStatus("Distribute Loot failed: " .. message)
            end
        end
        self:RefreshActionLootDiagnostics()
        return unpack(results, 1, results.n)
    end
end

local baseBuildActionLootSection = EventManage.BuildActionLootSection
if type(baseBuildActionLootSection) == "function" then
    function EventManage:BuildActionLootSection(root, ...)
        local result = baseBuildActionLootSection(self, root, ...)
        if not self.ActionsLootDiagnosticText and root and type(UI.CreateText) == "function" then
            self.ActionsLootDiagnosticText = UI.CreateText(root:GetFrame(), "RPEServerEventManageActionsLootDiagnosticText", "", {
                width = CONTENT_WIDTH,
                height = 18,
                fontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
                fontSize = (C.FontSizes and C.FontSizes.Body) or 8,
                textColor = UI.ResolveColor(nil, "text.muted"),
                justifyH = "LEFT",
                justifyV = "MIDDLE",
                wordWrap = false,
            })
            root:AddChild(self.ActionsLootDiagnosticText)

            local frame = self.ActionsLootDiagnosticText.GetFrame and self.ActionsLootDiagnosticText:GetFrame() or nil
            if frame then
                frame:EnableMouse(true)
                frame:SetScript("OnEnter", function(owner)
                    showDiagnosticTooltip(self, owner)
                end)
                frame:SetScript("OnLeave", function()
                    if GameTooltip and type(GameTooltip.Hide) == "function" then
                        GameTooltip:Hide()
                    end
                end)
            end
            if type(root.RefreshLayout) == "function" then
                root:RefreshLayout()
            end
        end
        self:RefreshActionLootDiagnostics()
        return result
    end
end

EventManage._actionsLootDiagnosticsInstalled = true
