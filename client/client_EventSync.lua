local _, Addon = ...

-- Event-rejoin revision/repair pipeline disabled.
-- Normal event actions and domain messages use the existing client paths.
Addon.Client = Addon.Client or {}
return Addon.Client
