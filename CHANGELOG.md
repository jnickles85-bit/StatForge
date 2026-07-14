# Changelog — StatForge (WoW Classic Era addon)

All notable changes to the addon. See `AUDIT.md` for the full audit findings
and remaining roadmap (covers both this repo and StatForge-App).

## [0.5.0] — 2026-07-12

### Companion desktop app — 2026-07-13
+- Added Hardcore farming-risk model v2 with level-gated class escape tools, carried-consumable readiness, and cave, respawn, patrol, leash, and crowd-control constraints.
+- Added item-data provenance diagnostics with source/version metadata, Classic Era scope, record-count validation, build age, and runtime SHA-256 verification.
+- No addon export-schema change was required for this phase.

### Added — Import + Equip (Phase 2, closes the AMR loop)
- **Gear tab is live**: paste a setup string from the desktop app ("Send to Addon"), pick it from the setup list, review per-slot status (**E** equipped · **bag** · **bank** · **?** not found), then **Equip this setup** — swaps everything out of combat via `EquipItemByName`, with a summary line (already on / swapped / in bank / not found).
- Setup string format `SFSETUP1;label;specId;mode;slot=itemId:suffixId:enchantId;...` — matching by itemId + suffixId + requested non-zero enchantId, so random-suffix and duplicate enchanted instances equip correctly. Setups persist per character in `StatForgeDB.gearSetups`.
- Import modal with paste box + parse errors; Delete per setup.

### Fixed
- Setup matching honors a requested non-zero `enchantId` in bags, an open bank, equipped slots, and the closed-bank cache. Duplicate copies with different enchants no longer select or report the wrong copy.
- Snapshot JSON preserves `suffixId`; the in-memory snapshot previously captured it but the serializer dropped it at the producer/consumer boundary.

### Testing
- Lua behavior tests run through Fengari with `npm test`; GitHub CI runs them before luacheck. Contract coverage includes `suffixId` and bank-cache freshness serialization.

## [0.4.0] — 2026-07-10

### Added — In-game product shell (AUDIT Path A / Phase 1)
- **Main window** (`/sf` or minimap): dark StatForge chrome with tabs **Export | Gear | Options** (AMR-inspired layout, cyan brand).
- **Minimap button** — left-click toggles UI; drag to reposition (angle saved).
- **Export tab** — status card (character, last export age, bank cache age/count), **Export now**, optional **Show / Copy JSON**. Opening the tab auto-exports so SavedVariables stay fresh.
- **Gear tab** — currently-equipped overview with tooltips; Import/Equip stub for Phase 2.
- **Options tab** — show minimap button, auto-export on logout, about/help.
- **First-use splash** — bank + desktop workflow guidance (once per character profile).
- Window position remembered in `StatForgeDB.ui`.

### Added — Export data
- **`enchantId`** on every equipped/bag/bank item (item string field 3) for future scoring and equip-diff.

### Changed
- Modular layout: `Constants.lua`, `Snapshot.lua`, `UI.lua`, `ExportTab.lua`, `GearTab.lua`, `OptionsTab.lua`, `Core.lua` (no Ace dependencies).
- Version **0.4.0**; TOC `## Version` aligned.
- `deploy.ps1` copies the full multi-file addon and clears stale files.

### Commands
- `/sf` · `/statforge` — toggle main window
- `/sf export` — export without opening UI
- `/sf gear` · `/sf options` — open a specific tab
- `/sf debug` — container API dump

### Fixed (post-review)
- Window position no longer tries to store a Frame userdata in SavedVariables (only left/top numbers).
- Gear tab variable shadowing cleaned up; luacheck CI now lints all seven Lua files, not just Core.lua.

## [0.3.0] — 2026-07-09

### Added
- **Character-sheet stats in the export** (`character.stats`): real values from the game API — attributes, health/mana, armor, defense, melee/ranged attack power, crit/dodge/parry/block percentages, spell damage/healing. Gear-tooltip sums can't reproduce these (AP from strength/agility/level, etc.), so the app now shows what the game actually says. All API calls are guarded; missing APIs just omit fields.
- `/sf debug` — prints per-container slot counts from both bag APIs for diagnosing scan issues.
- `character.talentPoints` in the export ([31, 5, 15]) — lets the app auto-detect the spec.
- **Random-suffix support**: items whose link carries a suffixId ("of the Bear") export their game-resolved tooltip lines (hidden-tooltip scan), so the app can score their real stats instead of the stat-less base item.
- **Release tooling**: luacheck CI on every push (`.luacheckrc` covers the WoW API surface), BigWigs packager release workflow (tag `v*` → GitHub release zip; CurseForge/Wago upload when `CF_API_KEY`/`WAGO_API_TOKEN` secrets + TOC project IDs are set), and a weekly TOC Interface auto-bump PR.

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
