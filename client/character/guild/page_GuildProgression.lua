local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Guild = Addon.Client.UI.Guild or {}

local Client = Addon.Client
local GuildUI = Addon.Client.UI.Guild
local UI = Addon.UI or {}

local ProgressionPage = GuildUI.ProgressionPage or {}
GuildUI.ProgressionPage = ProgressionPage
ProgressionPage.__index = ProgressionPage

local function describeResolution(resolution)
    if not resolution or resolution.inGuild ~= true then
        return "Join a guild to view its read-only progression."
    end

    if resolution.conflict then
        return "Conflict: multiple Guild Settings match this guild. Progression is unavailable until it is resolved."
    end

    if not resolution.setting then
        return resolution.reason == "guild-loading"
            and "Guild information is still loading."
            or "No active Guild Setting matches this guild."
    end

    return "Display only. Progression entries are not evaluated or unlocked here."
end

function ProgressionPage:Build(parent, owner)
    self.owner = owner
    if self.frame then
        return self.frame
    end

    self.frame = CreateFrame("Frame", "RPEGuildProgressionPage", parent)
    self.frame:SetAllPoints(parent)

    self.RootLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.frame, "RPEGuildProgressionRootLayout", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RootLayout, self.frame, 0, 0, 0, 0)

    self.StatusText = UI.CreateText(self.RootLayout:GetFrame(), "RPEGuildProgressionStatusText", "", {
        width = 520,
        height = 32,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.RootLayout:AddChild(self.StatusText)

    self.SummaryText = UI.CreateText(self.RootLayout:GetFrame(), "RPEGuildProgressionSummaryText", "", {
        width = 520,
        height = 20,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.RootLayout:AddChild(self.SummaryText)

    self.EntryPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEGuildProgressionEntryPanel", {
        width = 520,
        height = 270,
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.EntryPanel)

    self.EntryList = UI.ScrollLayout:New({
        name = "RPEGuildProgressionEntryList",
        width = 512,
        height = 264,
        visibleRows = 9,
        rowHeight = 42,
        rowSpacing = 1,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 82,
        statusWidth = 68,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
        rowWordWrap = true,
    })
    self.EntryList:SetParent(self.EntryPanel:GetContentFrame())
    self.EntryList:SetRowRenderer(function(row, entry, entryIndex)
        local name = tostring(entry and entry.name or "")
        if name == "" then
            name = tostring(entry and entry.id or ("Entry " .. tostring(entryIndex)))
        end
        local details = tostring(entry and entry.description or "")
        if entry and entry.lockedText ~= "" then
            details = details ~= "" and (details .. "\n" .. entry.lockedText) or entry.lockedText
        end
        local spellRefs = entry and entry.spellRefs or {}
        if #spellRefs > 0 then
            details = details ~= "" and (details .. "\n") or ""
            details = details .. "Spells: " .. table.concat(spellRefs, ", ")
        end
        row:SetCategory(tostring(entry and entry.id or ("Entry " .. tostring(entryIndex))))
        row:SetTestName(name)
        row:SetStatus("View")
        row:SetDetail(details)
    end)
    self.EntryList:Create()
    UI.Utils.AnchorFill(self.EntryList, self.EntryPanel:GetContentFrame(), 0, 0, 0, 0)

    self.EmptyText = UI.CreateText(self.EntryPanel:GetContentFrame(), "RPEGuildProgressionEmptyText", "", {
        width = 320,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.EmptyText:GetFrame():SetPoint("CENTER", self.EntryPanel:GetContentFrame(), "CENTER", 0, 0)

    self:Refresh()
    return self.frame
end

function ProgressionPage:Refresh()
    if not self.frame then
        return nil
    end

    local setting, resolution
    if Client.Guild and Client.Guild.GetActiveGuildSetting then
        setting, resolution = Client.Guild:GetActiveGuildSetting()
    end

    local hasSetting = setting ~= nil and resolution and resolution.conflict ~= true
    local progression = hasSetting and setting.progression or {}
    local entries = progression and progression.entries or {}
    self.StatusText:SetText(describeResolution(resolution))
    self.SummaryText:SetText(hasSetting
        and ("Configured slots: %d | Entries: %d"):format(tonumber(progression.slotCount) or 0, #entries)
        or "")
    self.EntryList:SetItems(entries or {})
    self.EmptyText:SetText(not hasSetting and "No active Guild Setting." or (#entries == 0 and "No progression entries configured." or ""))
    return self.frame
end

return ProgressionPage
