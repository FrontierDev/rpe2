local _, Addon = ...

-- Superseded snapshot/revision rejoin integration disabled.
-- Server:ReconcileClientEventSession() now runs its original event snapshot path.
Addon.Server = Addon.Server or {}
return Addon.Server
