-- ============================================================================
-- RPEngine 2 - Runecloth Consumption Test
--
-- Slash command:
--     /rpedeleterunecloth
--
-- Finds Runecloth in the player's bags and permanently deletes exactly 1.
-- ============================================================================

local TARGET_ITEM_NAME = "Runecloth"


local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(
        "|cff00ccffRPE Runecloth Test:|r " .. tostring(message)
    )
end


-- ============================================================================
-- Get item name from container information
-- ============================================================================

local function GetItemNameFromContainerInfo(info)

    if not info then
        return nil
    end

    -- The hyperlink already contains the item's displayed name.
    --
    -- Example:
    -- |cffffffff|Hitem:14047:...|h[Runecloth]|h|r
    --
    if info.hyperlink then
        local name = info.hyperlink:match("%[(.-)%]")

        if name then
            return name
        end
    end

    -- Fallback if hyperlink parsing fails.
    if info.itemID then
        local name = C_Item.GetItemInfo(info.itemID)

        if name then
            return name
        end
    end

    return nil
end


-- ============================================================================
-- Find the first Runecloth stack
-- ============================================================================

local function FindRunecloth()

    -- Bag 0 = backpack
    -- Bags 1-4 = normal equipped bags
    -- Bag 5 = reagent bag, where supported
    for bag = 0, 5 do

        local numSlots = C_Container.GetContainerNumSlots(bag)

        if numSlots and numSlots > 0 then

            for slot = 1, numSlots do

                local info = C_Container.GetContainerItemInfo(bag, slot)

                if info then

                    local itemName = GetItemNameFromContainerInfo(info)

                    if itemName == TARGET_ITEM_NAME then

                        return {
                            bag = bag,
                            slot = slot,
                            itemID = info.itemID,
                            stackCount = info.stackCount or 1,
                            hyperlink = info.hyperlink,
                        }
                    end
                end
            end
        end
    end

    return nil
end


-- ============================================================================
-- Delete exactly one Runecloth
-- ============================================================================

local function DeleteOneRunecloth()

    -- We don't want to interfere with something the player already has
    -- attached to their cursor.
    local cursorType = GetCursorInfo()

    if cursorType then
        Print("|cffff4444Failed:|r Your cursor is already holding something.")
        Print("Clear your cursor and try again.")
        return false
    end


    -- Find a Runecloth stack.
    local item = FindRunecloth()

    if not item then
        Print("|cffff4444No Runecloth found.|r")
        return false
    end


    Print(
        string.format(
            "Found Runecloth: Bag %d, Slot %d, Stack %d",
            item.bag,
            item.slot,
            item.stackCount
        )
    )


    -- ------------------------------------------------------------------------
    -- Move EXACTLY ONE Runecloth onto the cursor.
    --
    -- If the stack contains more than one item, split one from it.
    --
    -- If there is only one item in the stack, pick up the whole stack
    -- (which is exactly one item).
    -- ------------------------------------------------------------------------

    if item.stackCount > 1 then

        C_Container.SplitContainerItem(
            item.bag,
            item.slot,
            1
        )

    else

        C_Container.PickupContainerItem(
            item.bag,
            item.slot
        )

    end


    -- ------------------------------------------------------------------------
    -- Safety check:
    -- Make sure that the cursor now actually contains the expected item.
    -- ------------------------------------------------------------------------

    local cursorTypeAfter, cursorItemID = GetCursorInfo()

    if cursorTypeAfter ~= "item" then
        Print("|cffff4444Failed:|r Runecloth was not placed on the cursor.")
        return false
    end


    if cursorItemID ~= item.itemID then

        Print(
            "|cffff4444Safety check failed:|r " ..
            "the cursor item is not the Runecloth that was selected."
        )

        ClearCursor()

        return false
    end


    -- ------------------------------------------------------------------------
    -- Permanently destroy the single Runecloth on the cursor.
    -- ------------------------------------------------------------------------

    DeleteCursorItem()


    Print("|cff00ff00Consumed 1 Runecloth.|r")

    return true
end


-- ============================================================================
-- Expose the function for later RPEngine use
-- ============================================================================

RPE_DeleteOneRunecloth = DeleteOneRunecloth


-- ============================================================================
-- Slash command
-- ============================================================================

SLASH_RPEDELETERUNECLOTH1 = "/rpedeleterunecloth"

SlashCmdList["RPEDELETERUNECLOTH"] = function()
    DeleteOneRunecloth()
end


Print("Loaded. Type /rpedeleterunecloth to consume 1 Runecloth.")