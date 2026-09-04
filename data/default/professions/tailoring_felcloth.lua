local _, Addon = ...

local definitions = Addon.Data and Addon.Data.DefaultDatasets and Addon.Data.DefaultDatasets.Definitions or nil
local definition = definitions and definitions["7259f1d3"] or nil
if type(definition) ~= "table" or type(definition.dataset) ~= "table" then
    error("Tailoring default dataset must be registered before loading the Felcloth extension.")
end

definition.version = math.max(tonumber(definition.version) or 0, 2)
local dataset = definition.dataset
dataset.items = dataset.items or {}

local function findItemByName(name)
    for index = 1, #dataset.items do
        local item = dataset.items[index]
        if type(item) == "table" and item.name == name then
            return item
        end
    end
    return nil
end

local item = findItemByName("Felcloth")
if not item then
    item = {
        id = "8dc72367",
        name = "Felcloth",
    }
    dataset.items[#dataset.items + 1] = item
end

item.allowWowConversion = true
item.armorWeight = "cosmetic"
item.bindingFlag = "none"
item.blueSockets = 0
item.canDisenchant = false
item.canSell = true
item.canStack = true
item.canTrade = true
item.cogSockets = 0
item.conditions = {}
item.consumableElixirType = ""
item.consumableType = ""
item.damageMode = "fixed"
item.damagePerTurn = 0
item.description = ""
item.gemColor = "none"
item.genericModificationKey = ""
item.greenSockets = 0
item.icon = "interface/icons/inv_fabric_felrag.blp"
item.isTwoHanded = false
item.itemLevel = 0
item.itemSetKey = ""
item.itemType = "material"
item.maxDamagePerTurn = 0
item.maxGenericModificationCounts = {}
item.maxModificationCounts = {}
item.maxStackSize = 200
item.metaSockets = 0
item.minDamagePerTurn = 0
item.modificationKind = "generic"
item.prismaticSockets = 0
item.quality = "common"
item.redSockets = 0
item.sellPrice = 0
item.skillBonuses = {}
item.socketTypes = {}
item.sockets = {}
item.stats = {}
item.tags = {}
item.targetArmorWeight = "none"
item.targetSlotRefs = {}
item.targetTwoHandedOnly = false
item.uniqueFlag = "none"
item.validSlotRefs = {}
item.wowConversionSkillRef = "f82db71a:goqp0alw"
item.yellowSockets = 0
