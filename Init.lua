local addonName, Addon = ...

RPE = RPE or {}

-- Namespaces
Addon.Name = addonName
Addon.API = Addon.API or {}
Addon.UI = Addon.UI or {}
Addon.Internal = Addon.Internal or {}
Addon.Debug = Addon.Debug or {}
Addon.Utils = Addon.Utils or {}
Addon.Data = Addon.Data or {}
Addon.Commands = Addon.Commands or {}

Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Internal.Events = Addon.Internal.Events or {}
Addon.Internal.Tasks = Addon.Internal.Tasks or {}
Addon.Internal.Constants = Addon.Internal.Constants or {}
Addon.Internal.Registry = Addon.Internal.Registry or {}

Addon.Server = Addon.Server or {}
Addon.Client = Addon.Client or {}

Addon.Internal.Constants.AddonMessagePrefix = Addon.Internal.Constants.AddonMessagePrefix or "RPE"
