local _, Addon = ...

-- Event-rejoin revision/mutation runtime disabled.
-- Normal event replication remains on the existing server/client domain paths.
Addon.Server = Addon.Server or {}
return Addon.Server
