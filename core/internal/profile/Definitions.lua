local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Profile = Addon.Internal.Profile or {}

local Profile = Addon.Internal.Profile

Profile.Definitions = {
    SlotTextures = {
        head = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Head",
        neck = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Neck",
        shoulder = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shoulder",
        back = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Rear",
        chest = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest",
        shirt = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shirt",
        tabard = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Tabard",
        wrists = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Wrists",
        hands = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Hands",
        waist = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Waist",
        legs = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Legs",
        feet = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Feet",
        finger = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger",
        finger1 = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger",
        finger2 = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger",
        trinket = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket",
        trinket1 = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket",
        trinket2 = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket",
        mainhand = "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand",
        offhand = "Interface\\PaperDoll\\UI-PaperDoll-Slot-SecondaryHand",
        ranged = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Ranged",
        relic = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Relic",
        ammo = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Ammo",
    },
    SlotLabels = {
        mainhand = "Main Hand",
        offhand = "Off Hand",
        finger1 = "Finger",
        finger2 = "Finger",
        trinket1 = "Trinket",
        trinket2 = "Trinket",
    },
}

return Profile.Definitions
