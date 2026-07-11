# StatForge Audit — July 10, 2026

Scope: `StatForge` (WoW Classic Era addon) and `StatForge-App` (Electron/React optimizer).  
Reference comparison: local install of **AskMrRobotClassic** at  
`C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\AskMrRobotClassic`  
plus AMR product docs (export ↔ website ↔ import ↔ Gear tab equip flow).

> **For agents/teammates:** master audit + roadmap for BOTH repos.  
> Per-repo history: each repo’s `CHANGELOG.md`.  
> App tests: **61/61** passing (2026-07-10).  
> **Path A chosen:** in-game shell first. Addon **0.4.0** = Phase 1 shell shipped.

---

## STATUS SNAPSHOT

### ✅ Done (correctness + companion pipeline)

| Area | Status |
|---|---|
| Bank export / bank cache / stale panel / link parser / TOC 11508 | Fixed (addon 0.2.0+) |
| SavedVariables auto-export + Electron file watcher auto-import | Done |
| Use: not permanent; weapon DPS; level/class/proficiency; joint weapons/rings/trinkets; Unique | Done |
| Upgrade Finder (full DB + sources/faction/phase) | Done |
| Compact item DB (33MB → ~6.8MB), shared parser, icon cache | Done |
| Spec auto-detect, random-suffix tooltips, character-sheet stats | Done |
| Session persistence, Upgrades tooltips, CI (app + addon luacheck/packager/TOC) | Done |
| **A1 Phase 1 — multi-tab UI + minimap + Export status** | **Done (addon 0.4.0)** |
| **A2 Version/TOC/README aligned** | **Done (0.4.0)** |
| **A3 enchantId on export items** | **Done (0.4.0)** |

### ⬜ Open (priority)

| # | Item | Repo | Why it matters |
|---|---|---|---|
| **A1 Phase 2** | Import setup string + Gear tab Equip | addon (+ app “Send to Addon”) | Closes AMR loop |
| **A1 Phase 3** | Optional light in-game upgrades display | addon | Nice-to-have; app remains brain |
| **P1** | Character roster switcher | app | Multi-alt hardcore reality |
| **P2** | Watcher-first empty state; bank age in UI | app | Companion feel |
| **P3** | Electron bump + installer + auto-update | app | Ship-ready product |
| **P4** | Cap-aware EP, on-use discount, enchants, set bonuses | app | Recommendation quality |
| **P5** | Loadouts / “apply best” preview | app + addon | Closed loop with Gear Equip |

---

## 1. What StatForge is (positioning)

| | Raidbots | AskMrRobot | **StatForge** |
|--|----------|------------|---------------|
| Combat sim | Yes | Weights / models | Linear EP (today) |
| Best-in-bags | Yes | Yes | Yes (joint slots) |
| Full-DB farm targets | Weak | Strong | Strong + **HC risk** |
| Auto import | SimC string | Addon string / companion | **SavedVariables watcher** |
| **In-game gear UI** | No | **Yes (core)** | **Export panel only** |
| Hardcore risk | No | No | **Yes** |

**Winning strategy:** Hardcore-first companion (safe farms, obtainable upgrades, offline desktop) **plus** an AMR-style in-game shell for export, import, and equipping optimized sets. Do not chase full sim day one.

---

## 2. App audit (condensed — still valid)

### Strengths
- Correct product shape for Classic Hardcore.
- Modern companion workflow (SV + watcher).
- Shared pure parser, compact DB, solid unit coverage on hard correctness cases.
- UI polish (theme, tooltips, animations) is above average for a v0.x desktop tool.

### Gaps vs state of the art
1. **EP ceiling** — linear weights lack hit caps, set bonuses, enchants, discounted on-use.
2. **No multi-character roster** — newest export always wins.
3. **No loadouts** — analysis only; no “apply this set.”
4. **Not distributed** — no installer / auto-update.
5. **Architecture** — large panel files, prop-drilled state; fine for now, pressure-grows with loadouts.
6. **First-run still paste-led** even when watcher is live.

### App roadmap (after or in parallel with addon UI)
1. Character switcher + export age / `bankCachedAt` surface.  
2. Watcher-first import CTA.  
3. electron-builder + electron-updater.  
4. Soft-cap EP + on-use discount + enchants + Classic set bonuses.  
5. Loadout model + “Send to Addon” string (pairs with Gear tab).  
6. Virtualized long lists; richer Finder → Farming loop.

---

## 3. Addon audit — current state

### What works
- Dual bag API path, bank cache with empty-scan guard, logout auto-export.
- Suffix tooltip scan, character-sheet stats, talentPoints for app spec detect.
- ESC-closable export frame, friendly failure messages.
- Deploy script; packager + luacheck + TOC auto-bump workflows.

### What’s holding it back
| Issue | Detail |
|---|---|
| **Export-only UI** | Single 700×500 EditBox frame. No tabs, minimap, gear review, or import path. |
| **No return path** | App optimizes; player must equip manually. AMR’s value is **Send to Addon → Gear tab → Equip**. |
| **Version drift** | `Core.lua` = 0.3.0; `.toc` / README = 0.2.0. |
| **No enchantId** | Item string field 2 unused; blocks equip-diff + scoring. |
| **Pretty JSON only** | Fine for EditBox; minified string better for SV / import payloads. |
| **No Ace / structure** | Fine at ~550 LOC; multi-tab UI needs modular files. |
| **Installed copy stale** | Live `_classic_era_` AddOns/StatForge still ~0.2.0 era file dates. |

### Installed reference: AskMrRobotClassic (local)

Structure worth learning from (not copying blindly):

```
AskMrRobotClassic/
  Core.lua          — AceAddon, AceDB, minimap (LDB), slash, window lifecycle
  Constants.lua
  Export.lua        — Export tab + first-use splash + bank scan helpers
  Import.lua        — Modal import cover (paste setup string)
  Gear.lua          — Setup dropdown, per-slot optimal vs equipped, gems/enchants, Equip
  Shopping.lua      — Shopping list window
  Junk.lua / CombatLog.lua / Options.lua
  ui/               — Custom AceGUI widgets (frame, tabs, buttons, icons, scroll…)
  Media/            — Ubuntu fonts, icons, chrome art
  localization/
  Libs/             — Ace*, LibDBIcon, LibDataBroker
```

**Product loop (AMR):**
1. **Export tab** — live character string, first-use splash (“open bank, swap specs once”).  
2. Website / external optimizer runs Best-in-Bags.  
3. **Import** — paste result into Gear tab (orange Import).  
4. **Gear tab** — setup dropdown; slot list with quality-colored names, **“E”** if equipped, side panel for gems/enchants; green **Equip** applies set (and optionally Equipment Manager).  
5. **Shopping / Junk** — secondary windows.  
6. **Minimap button** — left: toggle UI; right: equip active set.

**Visual language (AMR):**
- Dark gray chrome (`Bg` ~41,41,41), thin blue border, custom Ubuntu fonts.  
- Orange primary actions (Import), green confirm (Equip / OK).  
- Tan secondary/help text; class-colored icon borders; quality-colored item names.  
- ~1000×700 main window, remembered position, optional UI scale.  
- Tab strip: Export | Gear | Log | Options.  
- Modal “cover” overlays for splash + import.

**What StatForge should steal conceptually (not pixel-for-pixel):**
- Multi-tab product window, not a one-off EditBox.  
- Minimap launcher.  
- **Bidirectional** data: export *and* import optimized sets.  
- Gear view that answers “what should I wear?” and “what’s not equipped yet?” at a glance.  
- First-use guidance for bank/cache.  
- Remembered window position.

**What StatForge should do differently (Hardcore + desktop companion):**
- Keep **SavedVariables auto-sync** as primary (AMR is still mostly copy-paste).  
- Desktop app owns heavy optimization; addon can start with **import + equip** and grow light in-game BiB later.  
- Optional **Farming / Upgrades summary** tab tuned for HC (risk, phase) rather than combat logging.  
- Visual identity: StatForge cyan accent (`#66FCF1` from the app) instead of AMR orange/blue — same structure, distinct brand.

---

## 4. In-game vision — “StatForge shell” (AMR-inspired)

### Goals
1. Feel like a **product** when you type `/sf` or click the minimap icon.  
2. Close the loop: **optimize in app → import in-game → equip**.  
3. Keep export friction near zero (SV already does this; UI should explain it).  
4. Stay ToS-safe (standard API, SavedVariables, no memory reading).

### Proposed tabs (v1)

| Tab | Purpose | MVP? |
|---|---|---|
| **Export** | Status (last export time, bank cache age), “Export now”, optional copy JSON, desktop-watcher instructions | Yes |
| **Upgrades** | Top bag/bank upgrades for current spec/mode (needs either embedded EP or last result from app) | Phase 2 |
| **Gear** | Imported setups: slot list, equipped marker, Equip button | Yes (with import) |
| **Options** | Minimap, scale, auto-export on logout, “don’t touch EM sets” | Yes |

Phase 3 (optional): **Farming** hints (static or from last app push), junk-adjacent “vendor greens” later.

### Architecture recommendation (addon)

Don’t keep growing a single `Core.lua`. Split like AMR, but leaner:

```
StatForge/
  StatForge.toc
  Core.lua              — lifecycle, slash, minimap, DB defaults
  Export.lua            — snapshot builder + Export tab (move from Core)
  Import.lua            — parse app→addon payload into GearSetups
  Gear.lua              — Gear tab + EquipGearSet
  Options.lua
  ui/
    Frame.lua           — main window + tabs (native frames OR AceGUI)
    Widgets.lua         — small helpers (button, label, scroll)
  Constants.lua         — colors, slot names, class colors
  Media/                — minimap icon (reuse or design)
```

**Library choice:**
- **Option A (faster, AMR-like):** Ace3 + AceDB + LibDBIcon (battle-tested pattern).  
- **Option B (lighter):** pure frames + SavedVariables (no Ace), custom tabs — less deps, more UI code.

Recommendation: **Option A** for the shell if you’re optimizing for ship speed and maintainability; Ace is ubiquitous in Classic addons and matches the reference you already run.

### Data contracts

**Export (addon → app)** — keep `StatForge-v1` JSON; add:
```json
"enchantId": 1234   // per item, from item string field 2
```
Optional later: `uniqueId`, durability, money, professions.

**Import (app → addon)** — new compact format, e.g. `StatForge-Setup-v1`:
```json
{
  "format": "StatForge-Setup-v1",
  "label": "BiB Survival",
  "specId": "warrior-prot",
  "mode": "survival",
  "slots": {
    "1": { "itemId": 12345, "enchantId": 0, "suffixId": 0 },
    "16": { "itemId": 19364, "enchantId": 1900 }
  }
}
```

Stored in `StatForgeDB.gearSetups[]`. Gear tab renders; Equip walks bags/bank/equipped with match logic similar to AMR’s `FindMatchingItem` (itemId + suffix first; enchant as soft mismatch).

**App side:** “Send to Addon” / copy setup string (and/or write into a side channel later). For v1, **paste import** in-game is enough and mirrors AMR; desktop can also write setups into a watched file later.

### Equip behavior (v1)
1. For each slot in setup, find best matching item in equipped → bags → bank cache.  
2. Use secure equip APIs only out of combat (`EquipItemByName` / pickup+equip patterns AMR uses).  
3. Mark missing items (in bank / not owned) clearly — don’t fail silently.  
4. Optional: create/update an Equipment Manager set named `StatForge: <label>`.

### Export tab UX (replace raw JSON as primary)
```
[StatForge]  ·  Export

  Watching path handled by desktop app
  Last export:  2 minutes ago  ·  bank cache: 1h ago (visit bank to refresh)

  [ Export now ]     writes SV + refreshes panel
  [ Copy JSON  ]     advanced / paste fallback

  Help: /sf then /reload · desktop imports automatically
```

Keep the multi-line JSON behind “Copy JSON” or a collapsible advanced section — not the hero UI.

### Gear tab UX (AMR-shaped)
```
[ Import ]   Setup: [ BiB Survival ▾ ]

  [Class icon]   [ Equip this setup ]

  Head      66   E   Lionheart Helm
  Neck      63       Onyxia Tooth Pendant      ← bold = not equipped
  ...
  Main Hand 75   E   Thunderfury
```
Right column later: enchant short text, upgrade delta if we push scores from app.

### Visual system (StatForge brand)
Map AMR structure → your app palette:

| Role | AMR | StatForge |
|---|---|---|
| Accent / headers | Orange | Cyan accent `#66FCF1` / class color |
| Confirm | Green | Green (keep — universal) |
| Import / secondary CTA | Orange | Cyan or amber |
| Background | Gray 41 | Near-black `#0B0C10` / `#13151C` |
| Border | Blue | Dim cyan / slate |
| Body text | White / tan | White / muted slate |

Custom font optional (AMR ships Ubuntu); system fonts are fine for v1.

---

## 5. Phased implementation plan

### Phase 0 — Hygiene
- [x] Align version → **0.4.0** (toc, README, `SF.VERSION`).  
- [x] Export `enchantId` on all items.  
- [x] Surface bank cache / last export age on Export tab.  
- [x] `deploy.ps1` multi-file copy.

### Phase 1 — In-game product shell
- [x] Minimap button (pure frames, no Ace) + `/sf` toggles main window.  
- [x] Main frame ~920×620, tabs: Export | Gear | Options.  
- [x] Export tab status + Export now + Show/Copy JSON.  
- [x] `StatForgeDB` for window pos, firstUse, minimap, gearSetups stub.  
- [x] First-use splash.  
- [x] Modular files, no third-party libs.

### Phase 2 — Import + Equip (closes the AMR loop) — **DONE 2026-07-10**
- [x] Import modal → `gearSetups` (per-character; `SFSETUP1;label;spec;mode;slot=item:suffix:enchant;...`).  
- [x] Gear tab: setup selector, per-slot compare (E / bag / bank / not found), Equip, Delete.  
- [x] App: **Send to Addon** button on Upgrades (engine now exposes `recommended` per slot, incl. combined 2H/ring configs).  
- [x] Missing-item / bank-only messaging; combat lockdown guard; equip via `EquipItemByName(link, slot)`.

### Phase 3 — In-game upgrades (optional light BiB)
- [ ] Either: show **last app result** pushed via import, or  
- [ ] Embed minimal EP tables in the addon for bag-only upgrades (no full 38k DB in Lua).  
- [ ] Prefer app-computed setups for accuracy; in-game = display + equip.

### Phase 4 — App distribution + scoring depth
- [ ] Installer, auto-update, roster, cap-aware weights, sets, enchants scoring.

---

## 6. Priority order (updated)

1. **Decide:** in-game shell (A1) vs app ship (P3) first — see §7.  
2. Phase 0 hygiene (version + enchantId) either way.  
3. Phase 1–2 addon shell + import/equip if product goal is “feels like AMR in-game.”  
4. App roster + watcher UX + distribution.  
5. Scoring depth + loadouts polish.

---

## 7. Decision: where to invest next

| Path | Outcome | Effort |
|---|---|---|
| **A — In-game shell first** | Typing `/sf` feels like AMR; equip optimized sets in-world; strongest emotional upgrade for Classic players | Medium–High (addon restructure) |
| **B — App ship first** | Friends can install/update StatForge-App; engine already good | Medium |
| **C — Parallel thin slice** | Phase 0 + minimap + Export status tab **and** character switcher in app | Medium |

**Recommendation:** **Path A (or C)** if your inspiration is “I want AskMrRobot’s *in-game* experience.” The desktop app already carries the optimizer brain; the missing half of AMR is the **in-game product shell + equip loop**. Path B matters for distribution but won’t fix the “addon is just a JSON dump” feeling.

---

## 8. Historical correctness log (July 8 findings)

All original §1 addon bugs and §2 app engine bugs from the July 8 audit are **resolved** except residual product items (suffix needed addon 0.3.0 — done; getItemScore dedupe — done). See earlier CHANGELOGs for details. Do not re-fix bank-empty / Use:-as-permanent / isolated-slot scoring unless regressions appear.

---

## 9. Notes for implementers

- **Do not copy AMR code** — licensed third-party addon; use as **UX/architecture reference only**.  
- Combat lockdown: never equip mid-combat; queue or message.  
- Bank items: equip from bank only when bank is open; otherwise mark “in bank.”  
- Classic Era has no gem sockets like retail — keep gem UI out of Era scope; **enchants matter**.  
- Keep `StatForge-v1` export stable; add fields optionally; bump setup format separately.  
- After Phase 1, update this STATUS table and `CHANGELOG.md`.

---

*Last updated: 2026-07-10 — refreshed full audit; added AMR Classic local teardown and in-game shell plan.*
