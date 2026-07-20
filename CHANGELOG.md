# Changelog — StatForge (WoW Classic Era addon)

All notable changes to the addon. See `AUDIT.md` for the full audit findings
and remaining roadmap (covers both this repo and StatForge-App).

## Unreleased

### Companion desktop app — 2026-07-20 (CI reproducibility)
- Repaired the companion app's npm lockfile after dependency modernization omitted Electron Builder's Windows Squirrel/signing peer packages. Clean Node 22/npm 10 installation, 235 tests, lint, TypeScript/build, NSIS plus unpacked packaging, and packaged smoke now pass. No addon export-schema change was required.

### Distribution — 2026-07-19
- Decision: signed NSIS installer and controlled auto-update are **deferred indefinitely**. Code-signing certificate purchase rejected for now. The app + addon will ship as a plain zip for manual download/redownload, matching the CurseForge manual-update pattern every WoW player already accepts. The WoW addon itself (Lua/XML) never needed signing — this decision concerns only the Electron desktop companion .exe. Revisit only if SmartScreen warnings drive users away from public distribution or if seamless auto-update becomes a priority. Recorded in `AUDIT.md` Phase 4.1.

### Companion desktop app — 2026-07-19 (accessibility)
- Completed Phase 4.4 accessibility in the companion app: aria-live regions for ImportPanel error/success and AnalysisSnapshotsPanel save/restore messages (screen readers now announce import outcomes and snapshot operations); aria-label on all icon-only buttons (What-if slot/enchant remove, level +/−, scenario delete, Diagnostics per-error delete); aria-expanded on FarmingLocationsPanel toggle buttons; decorative chevrons and status icons marked aria-hidden. No addon export-schema change was required.

### Companion desktop app — 2026-07-19
- Added a What-if planning mode to the companion app. Users can clone the current character into a sandbox, swap gear from the full item database, edit talents and level, and see side-by-side DPS/survival score deltas against the real loadout — all non-destructive, with scenario save/restore. No addon export-schema change was required.

### Companion desktop app — 2026-07-18
- Added a bounded Custom encounter duration to the companion app. The persisted whole-second value drives the same deterministic effect-uptime window in owned and Finder analysis, round-trips through reproducible snapshots, and does not infer rotations or additional encounter mechanics; no addon export-schema change was required.

### Companion desktop app — 2026-07-16
- Added versioned reproducible Finder snapshots with exact imported character/loadout inputs, deterministic model-component and item-data SHA-256 identities, visible assumptions, and normalized objective-score breakdowns.
- Snapshots remain local, support JSON save/export/import, and can replay their embedded character and settings with explicit exact, drifted, malformed, or incompatible outcomes.
- Added deterministic confidence/sensitivity analysis over saved Pareto candidates using five disclosed DPS/survival trade-off lenses. Per-slot results identify Stable, Sensitive, and Model-limited recommendations with exact winner, objective-delta, and model-boundary evidence; the labels are not probabilities.
- No addon export-schema change was required; the app embeds the existing validated `StatForge-v1` input inside its separate analysis-snapshot contract.
- Expanded the shared talent-tab model beyond Mage with deterministic Shadow Priest and Affliction Warlock school modules. Tied and unsupported tabs keep explicit base-preset fallbacks, and no addon export-schema change was required.
- Added a dedicated Elemental Shaman caster preset and conservative Nature-school module. Only Elemental-dominant evidence activates it; tied or unsupported Shaman tabs retain explicit fallback behavior, and no addon export-schema change was required.
- Added a conservative Retribution Paladin Holy-school module in the companion app. It preserves physical weights, applies only to unambiguous Retribution-dominant evidence, and retains explicit fallback for tied or unsupported Paladin tabs; no addon export-schema change was required.
- Added a conservative Protection Paladin Holy-school module in the companion app. It preserves the existing hybrid preset's non-school weights, applies only to unambiguous Protection-dominant evidence, and keeps Holy-, Retribution-, tied-, or malformed evidence on the base fallback without claiming a tank rotation or threat model; no addon export-schema change was required.
- Added explicit Automatic, Solo (30s), Dungeon boss (90s), and Raid boss (180s) encounter profiles to the companion app. The selected duration drives deterministic on-use uptime in both owned and Finder analyses, persists locally, and is embedded in reproducible snapshots; no addon export-schema change was required.
- Hardened the companion app's Electron development lifecycle with a strict Vite port contract. A port-5173 collision now stops the coupled launcher instead of moving Vite to 5174 and leaving Electron to poll a dead renderer URL; no addon export-schema change was required.

### Companion desktop app — 2026-07-15
- Added non-dominated Finder recommendations with separate whole-loadout DPS and survival objectives plus Maximum DPS, normalized Balanced, and Maximum Survival lenses.
- Recommendation explanations expose both objective deltas and the active lens; acquisition planning now follows the selected deterministic utility.
- No addon export-schema change was required; the desktop app evaluates both objectives from the existing snapshot.
- Added deterministic Mage Arcane, Fire, and Frost school models selected from exported talent-tab points, with ambiguous exports retaining the established fallback rather than guessing.
- Added visible 30-second leveling and 180-second raid-boss encounter windows shared by owned-upgrade and Finder scoring.
- No addon export-schema change was required; the existing optional `character.talentPoints` field supplies specialization evidence.

### Fixed
- GitHub CI now lets luacheck discover the repository's checked-in `.luacheckrc` instead of passing the local path to the action's URL-only `config` input.
- Gear setup matching now distinguishes a same-item/suffix copy with the wrong requested enchant from an item that is fully missing. The Gear tab shows `ench`, the equip summary reports a separate wrong-enchant count, and the addon never equips the mismatched copy.
- Setup import now rejects a malformed non-empty gear token instead of silently dropping it from an otherwise valid setup.

### Testing
- Expanded the Fengari WoW-API mock harness from 3 to 11 behavior tests covering real item-link fields, setup parsing, equipped/bag/closed-bank enchant matching, combat lockdown, equip decisions, bank-cache preservation, JSON escaping, suffix IDs, and bank freshness.
- Added a repeatable in-game release matrix for bank events, logout persistence, UI lifecycle, tooltip scanning, enchant-specific setup matching, and sequential equipping.

## [0.5.0] — 2026-07-12

### Companion desktop app — 2026-07-14
- Added complete-loadout marginal scoring with conservative cap profiles, tooltip-first/verified-ID enchant resolution, and deterministic static set-threshold evaluation.
- Finder explanations now expose cap assumptions, enchant treatment, and gained or lost set thresholds while leaving unknown or opaque effects neutral.
- No addon export-schema change was required; existing exported `enchantId` and instance tooltip evidence drive enchant resolution.

### Companion desktop app — 2026-07-13
- Added Hardcore farming-risk model v2 with level-gated class escape tools, carried-consumable readiness, and cave, respawn, patrol, leash, and crowd-control constraints.
- Added item-data provenance diagnostics with source/version metadata, Classic Era scope, record-count validation, build age, and runtime SHA-256 verification.
- No addon export-schema change was required for this phase.

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
