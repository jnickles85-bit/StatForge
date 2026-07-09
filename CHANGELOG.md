# Changelog — StatForge (WoW Classic Era addon)

All notable changes to the addon. See `AUDIT.md` for the full audit findings
and remaining roadmap (covers both this repo and StatForge-App).

## [0.3.0] — 2026-07-09

### Added
- **Character-sheet stats in the export** (`character.stats`): real values from the game API — attributes, health/mana, armor, defense, melee/ranged attack power, crit/dodge/parry/block percentages, spell damage/healing. Gear-tooltip sums can't reproduce these (AP from strength/agility/level, etc.), so the app now shows what the game actually says. All API calls are guarded; missing APIs just omit fields.
- `/sf debug` — prints per-container slot counts from both bag APIs for diagnosing scan issues.

### Changed
- Container scanning is dual-path: prefers `C_Container`, falls back to the classic global API per bag.
- `deploy.ps1` rewritten ASCII-only (PowerShell 5.1 choked on the previous encoding), added `-NoPull`.

## [0.2.0] — 2026-07-08

### Fixed
- **Bank items were never exported** — `BuildSnapshot()` scanned the bank but returned a hardcoded empty table. (AUDIT 1.1)
- **Stale export on reopen** — the snapshot was built once per login; every later `/sf` showed the first export. Now rebuilt on every open. (AUDIT 1.2)
- **Item link parser read shifted garbage** — `gmatch("[^:]+")` skips empty fields, so field indexes were wrong on real links. Replaced with a simple `item:(%d+)` itemID match (Classic Era has no bonus/upgrade IDs). (AUDIT 1.3)
- Panel is now ESC-closable via `UISpecialFrames`; snapshot failure no longer creates-then-destroys the frame; `jsonEscape` handles `\r`. (AUDIT 1.7)

### Added
- **SavedVariables (`StatForgeDB`)** — standard addon persistence. (AUDIT 1.5)
- **Bank caching** — bank contents are cached on `BANKFRAME_OPENED`/`CLOSED`, so exports include the bank from anywhere, with a `bankCachedAt` timestamp in the export meta. (AUDIT 1.4)
- **Auto-export for the desktop app** — every `/sf` and every logout writes the JSON export to `StatForgeDB.exports["Name-Realm"]`. WoW flushes it to `WTF/.../SavedVariables/StatForge.lua` on `/reload`/logout, where the StatForge desktop app picks it up automatically. No copy-paste needed.
- `deploy.ps1 -NoPull` switch to deploy local uncommitted changes.

### Changed
- TOC `## Interface` bumped 11505 → 11508 (Classic Era 1.15.8). (AUDIT 1.6)
- Export JSON keeps `upgradeId: 0, bonusIds: []` as constants for `StatForge-v1` format compatibility.

## [0.1.0] — earlier
- Initial export addon: `/sf` panel with copyable JSON (character, equipped, bags, talents).
