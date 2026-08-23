-- ============================================================================
-- RPEngine 2 - WoW Bag Scan Test
-- ============================================================================

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffRPE Bag Test:|r " .. tostring(message))
end


-- ---------------------------------------------------------------------------
-- Compatibility wrappers
-- ---------------------------------------------------------------------------

local function GetBagNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag)
    elseif GetContainerNumSlots then
        return GetContainerNumSlots(bag)
    end

    return 0
end


local function GetBagItemInfo(bag, slot)

    -- Modern WoW API
    if C_Container and C_Container.GetContainerItemInfo then

        local info = C_Container.GetContainerItemInfo(bag, slot)

        if not info then
            return nil
        end

        return {
            itemID     = info.itemID,
            stackCount = info.stackCount or 1,
            hyperlink  = info.hyperlink,
        }
    end


    -- Older API fallback
    if GetContainerItemInfo then

        local texture,
              count,
              locked,
              quality,
              readable,
              lootable,
              link = GetContainerItemInfo(bag, slot)

        if not link then
            return nil
        end

        local itemID = tonumber(link:match("item:(%d+)"))

        return {
            itemID     = itemID,
            stackCount = count or 1,
            hyperlink  = link,
        }
    end

    return nil
end


-- ---------------------------------------------------------------------------
-- Resolve an item's displayed name
-- ---------------------------------------------------------------------------

local function GetBagItemName(info)

    if not info then
        return nil
    end

    -- First try the normal WoW item information API.
    if info.itemID then
        local name = GetItemInfo(info.itemID)

        if name then
            return name
        end
    end

    -- Fallback: item hyperlinks contain the displayed item name:
    --
    -- |cffffffff|Hitem:23572:...|h[Primal Nether]|h|r
    --
    if info.hyperlink then
        local name = info.hyperlink:match("%[(.-)%]")

        if name then
            return name
        end
    end

    return nil
end


-- ---------------------------------------------------------------------------
-- Scan player bags
-- ---------------------------------------------------------------------------

local function FindItemInBags(targetName)

    if not targetName or targetName == "" then
        targetName = "Primal Nether"
    end

    Print("Searching bags for: |cffffffff" .. targetName .. "|r")

    local totalCount = 0
    local stacksFound = 0
    local slotsScanned = 0

    -- 0 = backpack
    -- 1-4 = equipped bags
    -- 5 = reagent bag on clients that support it
    for bag = 0, 5 do

        local numSlots = GetBagNumSlots(bag)

        if numSlots and numSlots > 0 then

            for slot = 1, numSlots do

                slotsScanned = slotsScanned + 1

                local info = GetBagItemInfo(bag, slot)

                if info then

                    local itemName = GetBagItemName(info)

                    if itemName == targetName then

                        local count = info.stackCount or 1

                        stacksFound = stacksFound + 1
                        totalCount = totalCount + count

                        Print(
                            string.format(
                                "Found |cffffffff%s|r x%d - Bag %d, Slot %d, ItemID %s",
                                itemName,
                                count,
                                bag,
                                slot,
                                tostring(info.itemID)
                            )
                        )
                    end
                end
            end
        end
    end


    Print(
        string.format(
            "Finished: scanned %d slots, found %d stacks, total = %d.",
            slotsScanned,
            stacksFound,
            totalCount
        )
    )

    return totalCount
end


-- Make this accessible elsewhere in RPEngine if wanted.
RPE_BagTest_FindItem = FindItemInBags


-- ---------------------------------------------------------------------------
-- Slash command
-- ---------------------------------------------------------------------------

SLASH_RPEBAGTEST1 = "/rpebagtest"

SlashCmdList["RPEBAGTEST"] = function(msg)

    msg = msg and msg:match("^%s*(.-)%s*$") or ""

    if msg == "" then
        msg = "Primal Nether"
    end

    FindItemInBags(msg)
end


Print("Loaded. Use /rpebagtest or /rpebagtest <item name>.")