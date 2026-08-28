## Validation result: FAIL — pooled Achievement rows are not reset when unbound

The main #78 implementation is otherwise in place on current `main` (`f51e600`):

- dedicated `Addon.Client.UI.Tooltips.Achievement` builder exists;
- it returns `type = "game"` specs through the existing RPE/WoW `GameTooltip` path;
- Profile Achievement rows bind a function-valued tooltip lazily;
- title/description/category/subcategory/individual criteria/completion date/rewards/reward state are represented;
- row rebinding replaces the tooltip resolver with the currently bound Achievement;
- no native Blizzard Achievement API dependency was introduced;
- TOC load order places the Achievement tooltip builder before `page_ProfileAchievements.lua`.

### Blocking issue

`core/ui/prefabs/AchievementEntry.lua` now defines:

```lua
function AchievementEntry:Reset()
    self:SetOnClick(nil)
    self:SetTooltip(nil)
    self:SetAchievementData(nil)
    return self
end
```

but the shared `core/ui/elements/ScrollLayout.lua` never calls `row:Reset()` when a pooled row becomes unbound/hidden.

In `ScrollLayout:RefreshRows()`, when there is no item for a visible pooled row, the current behavior is only:

```lua
if rowFrame.Hide then
    rowFrame:Hide()
end
```

and rows beyond `visibleRows` are likewise only hidden. Therefore a row that previously represented Achievement A retains A's function-valued tooltip closure/detail while hidden. This violates the #78 requirement that **hidden/unbound pooled rows must not retain stale Achievement tooltip data**.

A normal A -> B recycled bind is safe because the row renderer overwrites the tooltip resolver before B is shown, but the unbound pooled-row state itself is still stale and retains references to the previous Achievement/Profile detail.

### Required fix

Add a generic optional reset hook to `ScrollLayout` when a row becomes unbound/inactive, e.g. before hiding it:

```lua
if row and type(row.Reset) == "function" then
    row:Reset()
end
if rowFrame and rowFrame.Hide then
    rowFrame:Hide()
end
```

Apply this at minimum to both cases in `RefreshRows()`:

1. `visibleIndex > self.visibleRows`;
2. `item == nil` for an otherwise visible pooled row.

Keep the hook generic/optional so other row prefabs are unaffected unless they implement `Reset()`.

### Revalidation cases

```text
row shows Achievement A
-> hover shows A

list/filter shrinks so that pooled row becomes unbound
-> row Reset() runs
-> stored tooltip spec/resolver is nil
-> old A detail is no longer retained by the row

same row later binds Achievement B
-> hover shows B only
-> no stale A title/criteria/reward data

row moves outside visibleRows because visible-row count shrinks
-> Reset() runs before/in conjunction with hiding
```

Keep #78 open until the pooled-row reset path is wired into `ScrollLayout` and the above cases pass.