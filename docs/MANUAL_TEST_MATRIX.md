# StatForge in-game manual test matrix

Use this matrix after addon behavior changes and before a release. Offline Fengari tests cover deterministic Lua logic; these checks cover WoW API behavior and event ordering that the mock harness cannot certify.

## Record

- Addon commit/version:
- WoW Classic Era build:
- Character/realm:
- Tester/date:
- Result: PASS / FAIL
- Notes or screenshots:

## Prerequisites

- Deploy the intended addon revision to `_classic_era_/Interface/AddOns/StatForge`.
- Start WoW with Lua errors enabled: `/console scriptErrors 1`.
- Use a character with at least one bag item, one bank item, and—when available—two copies of the same item with different enchants.
- Keep the desktop app closed unless a step explicitly requires it.

## Matrix

| ID | Area | Steps | Expected result | Result/evidence |
|---|---|---|---|---|
| A1 | Load and UI lifecycle | Log in, run `/sf`, switch Export → Gear → Options, close with Escape, reopen from the minimap button. | One window is shown; tabs render without Lua errors; Escape and minimap toggle work; position persists after reopening. | |
| A2 | Fresh export | Open Export, select **Export now**, then **Show / Copy JSON**. | Character identity and current gear are present; JSON is selectable; no Lua error appears. | |
| A3 | Logout persistence | Change one equipped or bag item, run `/sf export`, then `/reload`. Inspect `StatForgeDB.exports` through the desktop importer. | The post-change snapshot is loaded and has a newer export timestamp. | |
| A4 | Bank open cache | Open the bank, move one item between bank and bags, then open Export. | Bank count/content refreshes while the bank is open and bank freshness reports just now. | |
| A5 | Bank closed cache guard | Close the bank, leave the area, and export again. | The last non-empty bank cache remains available; an inaccessible/empty scan does not erase it. | |
| A6 | Random-suffix tooltip | Put an `of the …` random-suffix item in bags or equipment and export. | The exported item has a non-zero suffix ID and resolved tooltip lines; desktop parsing shows the suffix stats. | |
| A7 | Setup import validation | In Gear, paste one valid `SFSETUP1` string, then try a string containing a malformed slot token. | The valid setup imports; the malformed setup is rejected with the offending token identified. | |
| A8 | Exact enchant match | Import a setup requesting a non-zero enchant where the matching copy is in bags. | Gear shows `bag`; **Equip this setup** equips the exact enchanted copy. | |
| A9 | Wrong enchant status | Import a setup requesting enchant A while only the same item/suffix with enchant B is owned or cached. | Gear shows `ench`, not `?`; equip summary reports `wrong enchant`; the wrong copy is not equipped. | |
| A10 | Closed-bank setup item | Put the exact requested copy in the bank, close the bank, then review/equip the setup. | Gear shows `bank`; equip summary says to visit a banker; no swap is attempted. | |
| A11 | Combat lockdown | Enter combat and select **Equip this setup**. | No item is equipped; StatForge reports that gear cannot be swapped in combat. | |
| A12 | Multi-slot equip | Out of combat, import a setup with one already-equipped item, one bag item, one closed-bank item, and one missing item. | Summary counts each category correctly; only the bag item is passed to the WoW equip API. | |
| A13 | Tooltip scanner failure guard | Hover exported/random-suffix rows and repeat A2 after zoning or during item-cache delay. | Missing tooltip data remains optional; export/UI do not crash. | |
| A14 | Options | Toggle minimap visibility and automatic logout export, reload, and inspect behavior. | Options persist and each toggle controls the documented behavior. | |

## Release gate

A release candidate passes this matrix when A1–A12 pass without Lua errors. A13–A14 may be marked not applicable only with a written reason. Record failures as reproducible steps before changing code.
