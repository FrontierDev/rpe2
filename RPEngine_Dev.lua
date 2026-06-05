local addonName, Addon = ...

RPE = RPE or {}

-- Root addon namespace
Addon.Name = addonName

-- NOTE TO SELF:
-- Every file in the addon should now start with "local _, Addon = ..."

-- 
Addon.API = Addon.API or {}
Addon.UI = Addon.UI or {}
Addon.Server = Addon.Server or {}
Addon.Client = Addon.Client or {}
Addon.Utils = Addon.Utils or {}
Addon.Data = Addon.Data or {}