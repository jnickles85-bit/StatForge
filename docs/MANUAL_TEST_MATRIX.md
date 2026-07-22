# StatForge in-game manual test matrix

Use this matrix after addon behavior changes and before a release. Offline Fengari tests cover deterministic Lua logic; these checks cover WoW API behavior and event ordering that the mock harness cannot certify.

## Record

- Addon revision/version: `e4c28e49cb6e3b3b6a632ea7d90e431377f3ae23` / `0.5.0` / Interface `11509`
- WoW Classic Era build: `1.15.9.68808`
- Character/realm: Sonmage / Doomhowl
- Tester/date: Mightie; Gohan preflight and evidence review / 2026-07-21–2026-07-22 CDT
- Result: **PAUSED — 9/12 core release checks passed; A6, A8, and A11 remain**
- Notes or screenshots: Offline Fengari suite passed 11/11. The client updated from 1.15.8 to 1.15.9 before execution, so the StatForge TOC compatibility target was advanced to `11509`; all eight deployed files then matched the repository by SHA-256. The first login exposed unrelated third-party-addon compatibility errors, so all recorded passes below were repeated or completed with only StatForge enabled. Evidence screenshots are retained in the Hermes composer-image directory; the final A12 state and equip summary are in `composer_2026-07-22_00-19-37-366_c6b37a.png` and `composer_2026-07-22_00-20-06-510_639a29.png`.

## Pause/resume checkpoint — 2026-07-22

- Testing was intentionally paused immediately after A12. No additional live-WoW test was requested or performed after the multi-slot equip result.
- Passed: **A1–A5, A7, A9, A10, and A12**. Pending core checks: **A6, A8, and A11**. A13–A14 are also pending.
- The selected setup at the stopping point was:
  `SFSETUP1;Multi-slot validation;mage-frost;balanced;5=14109:843:0;18=5214:0:0;16=3197:0:0;1=999999:0:0`
- Before equipping, the four visible rows were Head `?` / Item 999999, Chest `E` / Native Robe, Main Hand `bank` / Stonecutter Claymore, and Ranged `bag` / Wand of Eventide.
- The exact visible result was: `StatForge: Equip "Multi-slot validation": 1 already on, 1 swapped, 1 in bank — visit a banker, 1 not found`.
- **Resume with A11 (Combat lockdown)** only when the tester has a safe combat situation. Confirm that no item changes and capture the exact StatForge combat-lockdown message. Then finish A6 (random-suffix export plus desktop suffix-stat parsing), A8 (requires a verified physical non-zero-enchant bag copy), A13, and A14. Do not mark the release gate complete until A6, A8, and A11 pass.

## Prerequisites

- Deploy the intended addon revision to `_classic_era_/Interface/AddOns/StatForge`.
- Start WoW with Lua errors enabled: `/console scriptErrors 1`.
- Use a character with at least one bag item, one bank item, and—when available—two copies of the same item with different enchants.
- Keep the desktop app closed unless a step explicitly requires it.

## Matrix

| ID | Area | Steps | Expected result | Result/evidence |
|---|---|---|---|---|
| A1 | Load and UI lifecycle | Log in, run `/sf`, switch Export → Gear → Options, close with Escape, reopen from the minimap button. | One window is shown; tabs render without Lua errors; Escape and minimap toggle work; position persists after reopening. | **PASS (2026-07-21):** With only StatForge enabled, `/sf` opened one v0.5.0 window; Export, Gear, and Options rendered without Lua errors (screenshots captured). Escape closed it, and the minimap button reopened it without errors; all tabs still worked. The tester then moved the window to a distinct position, closed it with Escape, and confirmed that the minimap button reopened it in that same new position. |
| A2 | Fresh export | Open Export, select **Export now**, then **Show / Copy JSON**. | Character identity and current gear are present; JSON is selectable; no Lua error appears. | **PASS (2026-07-21):** **Export now** reported `StatForge: Export ready`; **Show / Copy JSON** displayed selectable `StatForge-v1` JSON with Sonmage-Doomhowl, level 17 Troll Mage, addon v0.5.0, 10 equipped items, 11 bag entries, and 12 cached bank entries. The tester copied the full JSON successfully; no Lua error occurred. |
| A3 | Logout persistence | Change one equipped or bag item, run `/sf export`, then `/reload`. Inspect `StatForgeDB.exports` through the desktop importer. | The post-change snapshot is loaded and has a newer export timestamp. | **PASS (2026-07-21):** The tester moved Citrine, ran `/sf export` (chat: `Statforge: exported /reload for the desktop app`), and completed `/reload` without a Lua error. The persisted Sonmage-Doomhowl export parsed with timestamp `2026-07-21T23:52:50Z` and Citrine at Lua bag `3`, slot `2`. The desktop importer loaded that snapshot and visibly showed Citrine under **BAG 4**, confirming the post-change data reached the app. |
| A4 | Bank open cache | Open the bank, move one item between bank and bags, then open Export. | Bank count/content refreshes while the bank is open and bank freshness reports just now. | **PASS (2026-07-21):** With the bank open, the tester moved Wand of Eventide from the bank into a bag. Export updated from 11 bags / 12 bank to **12 bags / 11 bank** and reported `Bank: open now (live scan)`. |
| A5 | Bank closed cache guard | Close the bank, leave the area, and export again. | The last non-empty bank cache remains available; an inaccessible/empty scan does not erase it. | **PASS (2026-07-21):** After closing the bank and leaving the banker, Export still showed **12 bags / 11 bank** and reported `Bank Cache: just now - 11 items (visit bank to refresh)`. The closed-bank scan preserved the latest non-empty cache. |
| A6 | Random-suffix tooltip | Put an `of the …` random-suffix item in bags or equipment and export. | The exported item has a non-zero suffix ID and resolved tooltip lines; desktop parsing shows the suffix stats. | |
| A7 | Setup import validation | In Gear, paste one valid `SFSETUP1` string, then try a string containing a malformed slot token. | The valid setup imports; the malformed setup is rejected with the offending token identified. | **PASS (2026-07-21):** `SFSETUP1;Live validation;mage-frost;balanced;18=11288:0:0` imported and Gear showed the equipped Greater Magic Wand in the Ranged slot. A second string ending in `not-a-slot` was rejected in the import panel with red text: `Invalid gear slot token: not-a-slot`. |
| A8 | Exact enchant match | Import a setup requesting a non-zero enchant where the matching copy is in bags. | Gear shows `bag`; **Equip this setup** equips the exact enchanted copy. | |
| A9 | Wrong enchant status | Import a setup requesting enchant A while only the same item/suffix with enchant B is owned or cached. | Gear shows `ench`, not `?`; equip summary reports `wrong enchant`; the wrong copy is not equipped. | **PASS (2026-07-22):** A setup requested Greater Magic Wand (item 11288) with enchant `999`, while the owned/equipped copy had enchant `0`. Gear visibly showed orange `ench`, not `?`, and **Equip this setup** reported `0 already on, 0 swapped, 1 wrong enchant`; no wrong copy was equipped. |
| A10 | Closed-bank setup item | Put the exact requested copy in the bank, close the bank, then review/equip the setup. | Gear shows `bank`; equip summary says to visit a banker; no swap is attempted. | **PASS (2026-07-22):** With the bank closed, the `Closed bank validation` setup requested Stonecutter Claymore (item 3197) for Main Hand. Gear visibly showed `bank`. **Equip this setup** reported `0 already on, 0 swapped, 1 in bank — visit a banker`, so no swap was attempted. |
| A11 | Combat lockdown | Enter combat and select **Equip this setup**. | No item is equipped; StatForge reports that gear cannot be swapped in combat. | |
| A12 | Multi-slot equip | Out of combat, import a setup with one already-equipped item, one bag item, one closed-bank item, and one missing item. | Summary counts each category correctly; only the bag item is passed to the WoW equip API. | **PASS (2026-07-22):** `Multi-slot validation` showed Head `?` (Item 999999), Chest `E` (Native Robe), Main Hand `bank` (Stonecutter Claymore), and Ranged `bag` (Wand of Eventide). Out of combat, **Equip this setup** reported `1 already on, 1 swapped, 1 in bank — visit a banker, 1 not found`, matching all four categories and swapping only the bag item. |
| A13 | Tooltip scanner failure guard | Hover exported/random-suffix rows and repeat A2 after zoning or during item-cache delay. | Missing tooltip data remains optional; export/UI do not crash. | |
| A14 | Options | Toggle minimap visibility and automatic logout export, reload, and inspect behavior. | Options persist and each toggle controls the documented behavior. | |

## Release gate

A release candidate passes this matrix when A1–A12 pass without Lua errors. A13–A14 may be marked not applicable only with a written reason. Record failures as reproducible steps before changing code.
