-- Small, shared helpers for tests that load addon files in isolation.  These
-- keep the bootstrap contract in one place without duplicating production
-- implementations or making tests depend on the full WoW runtime.
local Support = {}

function Support.LoadAddonFile(path, addon, addonName)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(addonName or "RPEngine2", addon)
    return addon
end

function Support.EnsureCommsOperations(addon)
    addon.Internal = addon.Internal or {}
    addon.Internal.Comms = addon.Internal.Comms or {}
    addon.Internal.Comms.Operations = addon.Internal.Comms.Operations or {}
    local operations = addon.Internal.Comms.Operations
    operations.GetOpcode = operations.GetOpcode or function()
        return 1
    end
    operations.Get = operations.Get or function()
        return nil
    end
    return operations
end

function Support.EnsureUI(addon)
    addon.UI = addon.UI or {}
    addon.UI.ResolveColor = addon.UI.ResolveColor or function(_, key)
        return key
    end
    return addon.UI
end

return Support
