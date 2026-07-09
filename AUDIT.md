# StatForge Audit — July 8, 2026

Scope: `StatForge` (WoW Classic Era addon) and `StatForge-App` (Electron/React optimizer).
Findings verified against the actual 38,294-item `item-data.json`.

> **For agents/teammates:** this is the master audit + roadmap for BOTH repos.
> Per-repo change history lives in each repo's `CHANGELOG.md`.
> Status below is current as of 2026-07-08. Test suite: 43/43 passing.

## STATUS

### ✅ Completed (2026-07-08)
| Item | Where |
|---|---|
| 1.1 Bank never exported | addon `Core.lua` |
| 1.2 Stale snapshot on reopen | addon `Core.lua` |
| 1.3 Item link parser index-shifted | addon `Core.lua` |
| 1.4 Bank scan only worked at banker → now cached via events | addon `Core.lua` |
| 1.5 SavedVariables adopted (`StatForgeDB`) | addon `Core.lua`, `.toc` |
| 1.6 TOC bumped 11505 → 11508 | addon `.toc` |
| 1.7 ESC-close, panel create/destroy order, `\r` escaping | addon `Core.lua` |
| 2.1 "Use:" effects scored as permanent stats | app `itemDatabase.tsx` |
| 2.2 Weapon DPS ignored | app `itemDatabase.tsx`, `statWeights.ts` |
| 2.3 No level/class/proficiency filters | app `upgradeEngine.ts`, `slotCompatibility.ts` |
| 2.4 Slots scored in isolation → joint solvers for weapons (2H vs MH+OH), ring pairs, trinket pairs; Unique enforced | app `upgradeEngine.ts` |
| 3.1 Copy-paste killed → SavedVariables auto-export (addon) + file watcher auto-import (app) | both repos |
| 3.2 Upgrade Finder — full-DB "what should I farm" per slot with sources, faction/phase/level filters (2026-07-09) | app `upgradeFinder.ts`, `UpgradesPanel.tsx`, `data/zones.ts` |
| 3.3 Data pipeline precompute — 33MB → 6.8MB Era-only compact file, built by shared parser, ~120ms load (2026-07-09) | app `itemParser.ts`, `scripts/build-item-data.mjs` |

### ⬜ Remaining (rough priority order)
| Item | Notes |
|---|---|
| 3.3b Local icon cache | icons still hotlink wow.zamimg.com — cache locally for offline use |
| 2.6 Random-suffix items ("of the Bear") | suffix carries the stats at low level; suffix ID is already in the exported itemLink |
| 2.6 Spec auto-detect from talents | needs per-tab talent counts in the export (current flat 1/0 string is undecodable) |
| 2.5 Dead stat channels in presets | spellDamage*/expertise/resilience/armorPen don't exist in this dataset |
| 2.6 `getItemScore` duplicated | `upgradeEngine.ts` + `slotCompatibility.ts` |
| 3.4 App polish | persist last import/spec in localStorage, tooltips in Upgrades tab, Electron bump + auto-update, CSP |
| 3.5 Release hygiene | CI (lint+vitest), BigWigs packager → CurseForge/Wago, TOC auto-bump action |

---

## 1. Addon (Core.lua) — bugs

### 1.1 Bank is scanned but never exported — CRITICAL
`BuildSnapshot()` fills a local `bank` table (lines 137–161), then the return statement hardcodes `bank = {}` (line 179). Commit `846463e` claims this was fixed; it wasn't. Every export ships an empty bank, so the app's "bags + bank" candidate pool silently loses all bank items.

Fix: change line 179 to `bank = bank,`.

### 1.2 Stale snapshot on reopen — HIGH
`ShowPanel()` only builds the snapshot the first time the panel is created. Every later `/sf` just calls `panel:Show()` with the old JSON. Change gear, re-export, and you get your *first* export again until you `/reload`.

Fix: move snapshot building + `eb:SetText(json)` out of the create-once path so it runs on every `ShowPanel()` call.

### 1.3 Item link parsing is index-shifted — HIGH
`itemString:gmatch("[^:]+")` **skips empty fields**. Real item strings are mostly empty fields (`item:12345::::::::60:::::`), so `parts[13]` is almost never actually field 13. The `numBonusIDs`/`bonusIds`/`upgradeId` extraction reads garbage or nothing. It happens to be harmless only because Classic Era items have no bonus IDs — which is also the reason to delete it.

Fix: for Classic Era, all you need is `local id = tonumber(link:match("item:(%d+)"))`. Drop bonusIds/upgradeId from the format entirely (the app never uses them either), or split with a pattern that preserves empty fields: `for part in (itemString..":"):gmatch("(.-):")`.

### 1.4 Bank scan only works while the bank window is open — HIGH
Bank containers return 0 slots unless you're at the banker. Running `/sf` anywhere else silently exports no bank items with no warning. There's no `BANKFRAME_OPENED` handler and no cache.

Fix: register `BANKFRAME_OPENED`, scan then, cache in SavedVariables, and merge the cached bank into every export (with a `bankCachedAt` timestamp).

### 1.5 "No SavedVariables — ToS-safe" is a misconception — DESIGN
SavedVariables are the standard, fully-allowed persistence mechanism; SimulationCraft, TSM, WeakAuras companions all use them. Avoiding them costs you bank caching (1.4) and forces the giant copy-paste workflow (see §3.1). Nothing about SavedVariables is a ToS risk.

### 1.6 TOC interface version outdated — MEDIUM
`## Interface: 11505` — Classic Era has been on 1.15.8 (11508) since October 2025 and may be higher now. The addon loads flagged "out of date". Verify in-game with `/dump select(4, GetBuildInfo())` and update, or automate with p3lim's toc-interface-updater GitHub Action.

### 1.7 Smaller items
- Panel isn't ESC-closable via the standard mechanism: add `tinsert(UISpecialFrames, "StatForgeExportPanel")`.
- `GetItemInfo(id)` is async on cache miss — `quality` comes back 0 for uncached items. You export quality but the app never reads it; either drop it or use `Item:CreateFromItemID` callbacks.
- `jsonEscape` misses `\r` and other control characters.
- On snapshot failure the panel is created then destroyed (`panel = nil`) — build the snapshot *first*, then create the frame.
- Failed exports print raw Lua errors to chat; wrap in a friendlier message.

---

## 2. App — correctness bugs in the upgrade engine

### 2.1 "Use:" effects counted as permanent stats — HIGH (verified)
`parseTooltip` routes `Use:` lines into `parseEquipLine`. "Use: Increases spell power by 175 for 15 sec." (Talisman of Ephemeral Power) is scored as a permanent +175 spell power. Any on-use trinket without the word "chance" is massively overvalued and will dominate trinket recommendations.

Fix: only parse `Equip:` lines; treat `Use:` separately (ignore, or score at a heavy discount).

### 2.2 Weapon damage/DPS completely ignored — HIGH
Tooltips contain `64 - 140 Damage` and `(42.50 damage per second)` but nothing parses them. In Classic, weapon DPS is *the* dominant stat for melee/hunter weapons — a gray 40 DPS weapon beats an epic 20 DPS one. Current MH/OH/Ranged recommendations are effectively random for physical specs.

Fix: parse the DPS line into `weaponDps` (and `weaponSpeed` — slow/fast matters per spec), add it to `ParsedStats`, and give it a large weight in physical DPS presets.

### 2.3 No requiredLevel or class-restriction checks — HIGH
The engine will recommend a Requires Level 56 item to a level 30 hardcore character, and cross-class items (`Classes: Mage` tier pieces) to anyone. It also never checks weapon proficiency — Priests get sword recommendations, Paladins get wands.

Fix: filter candidates on `requiredLevel <= character.level`, parse `Classes:` tooltip lines, and add a class → usable weapon subclass table (the DB already has `subclass: "Mace"` etc.).

### 2.4 Slots scored in isolation — MEDIUM (this is the gap vs. AskMrRobot)
Per-slot greedy scoring can't handle: 2H vs. MH+OH tradeoffs (a 2H upgrade "wins" slot 16 while OH still counts); the same bag item recommended for both ring/trinket slots simultaneously; the ring equipped in Finger 2 being suggested as an "upgrade" for Finger 1; Unique-Equipped constraints.

Fix: a small combinatorial "Best in Bags" solver — enumerate weapon configurations (2H | MH+OH), assign rings/trinkets as pairs, enforce uniqueness. Item counts here are tiny; brute force is fine.

### 2.5 Dead stat channels — LOW
The dataset normalizes everything to "spell power" (8,903 items) — school-specific damage lines occur exactly twice. All `spellDamageArcane/Fire/...` fields are ~always 0, yet presets weight them at 1.5, which does nothing. Remove them, or parse the two legacy lines and move on. Same story: `expertiseRating`, `resilienceRating`, `armorPenetrationRating` don't exist in this dataset — dead weight in every preset and type.

### 2.6 Smaller items
- `getItemScore` is duplicated in `upgradeEngine.ts` and `slotCompatibility.ts` — drift risk; keep one.
- `deltaPercent` is hardcoded 100 when nothing is equipped — display "new slot" instead.
- Talents are exported as a flat 1/0 string with no tab boundaries — impossible to decode into a spec. Export per-tab point counts ("31/5/15") and use it to auto-select the spec preset (currently the user picks manually and the default is just the first spec of the class).
- `equipped` validation requires `itemLink` but the app only ever uses `itemId` — loosen the schema or use the link (it encodes suffixes, see below).
- **Random-suffix items ("of the Bear/Eagle") are scored as the base item** — the suffix carries all the stats at low levels, which is exactly the hardcore leveling audience. The suffix ID is in the itemLink you already export; parse it and apply suffix stats.

---

## 3. Modernization — what would make it feel like Raidbots/AMR

### 3.1 Kill the copy-paste (biggest win)
You already ship an Electron app — use it. Write the export to SavedVariables (`StatForgeDB`), then have the app locate the WoW folder and **watch** `WTF/Account/<acct>/SavedVariables/StatForge.lua` with `fs.watch`. Flow becomes: `/sf` in-game → `/reload` (or logout) → app auto-imports and toasts "Character updated". This is how TSM Desktop and WeakAuras Companion work, and it's the single biggest look-and-feel upgrade available. Keep paste as fallback. (If you keep paste: emit *minified* JSON — the pretty-printed string concatenation in Core.lua is slow in Lua and bloats the EditBox — or better, a LibDeflate-compressed export string like SimC/Raidbots.)

### 3.2 "Upgrade Finder" beyond your bags
Best-in-bags is table stakes; AMR/Raidbots' value is "what should I go get." You already ship the full 38k item DB and a farming-locations panel — connect them: for each slot, show the top N obtainable upgrades filtered by level/phase/class, with drop source (the DB has `source` data) and link into the Farming tab. For hardcore, add a risk weighting (you already have `farmingRisk.tsx`).

### 3.3 Data pipeline
34 MB JSON, shipped twice, fetched and regex-parsed on every startup. Precompute at build time: run the tooltip parser once in a Node script, emit a compact records file (only equippable items, only the ~15 stat fields that exist in Era, pre-parsed) — likely under 3 MB, instant startup, and it turns parser bugs into build-time-visible diffs. Cache Wowhead icons locally instead of hotlinking `wow.zamimg.com` (offline support, no broken images).

### 3.4 App polish
- Persist last import + chosen spec/mode in localStorage so relaunch doesn't land on the import screen.
- Auto-detect spec from talents (needs 2.6 talent fix).
- Wowhead-style hover tooltips on every item (you have `ItemTooltip.tsx` — wire it into UpgradesPanel, which currently shows only name + stat pills).
- Virtualize the bag grid / upgrade list if you ever show full-DB results.
- Electron 31 is old; bump, and add `electron-updater` so users get updates. Consider Tauri later if installer size matters.
- Add a CSP meta tag; you're loading remote images into a privileged shell.

### 3.5 Release hygiene
- Addon: package with the BigWigs packager GitHub Action → CurseForge/Wago, auto-bump TOC.
- App: CI running `lint` + `vitest` (tests exist and pass, but the upgrade engine has only 2 — add regression tests for 2.1–2.4, they're all easily testable).
- deploy.ps1: copy is fine, but you don't need to restart WoW — `/reload` picks up file changes; only TOC changes need a full restart.

---

## Priority order

1. Addon 1.1 (bank hardcoded empty) + 1.2 (stale panel) — one-line fixes, both user-facing data corruption.
2. App 2.1 (Use: effects) + 2.2 (weapon DPS) + 2.3 (level/class filters) — recommendations are wrong until these land.
3. TOC bump (1.6) + link parser cleanup (1.3).
4. SavedVariables + file-watcher auto-import (3.1) — the "modern" feel.
5. Best-in-Bags solver (2.4), suffix support (2.6), Upgrade Finder from full DB (3.2).
6. Data pipeline precompute (3.3), polish (3.4), CI/packaging (3.5).
