# StatForge

StatForge is a local-first World of Warcraft **Classic Hardcore** addon that exports character and gear data to the StatForge desktop optimizer and equips optimizer-generated setups in game.

## Requirements

- World of Warcraft Classic Era / Hardcore, interface `11508`
- StatForge desktop app for optimization and setup generation

## Installation

1. Copy the addon folder to:
   `World of Warcraft/_classic_era_/Interface/AddOns/StatForge`
2. Confirm that `StatForge.toc` is directly inside that folder.
3. Launch or reload WoW.
4. Enable **StatForge** in the AddOns list.

## Usage

| Action | How |
|---|---|
| Open StatForge | `/sf`, `/statforge`, or left-click the minimap button |
| Export | Open **Export** and select **Export now**; opening the tab also refreshes the snapshot |
| Sync to desktop | Run `/reload` or log out so WoW writes `SavedVariables/StatForge.lua` |
| Manual copy fallback | Select **Show / Copy JSON** on the Export tab |
| Import a setup | Paste the desktop app's `SFSETUP1` string into **Gear** |
| Equip a setup | Review the comparison and select **Equip** |
| Debug bags | `/sf debug` |

## Tabs

- **Export** — character status, bank-cache age, snapshot generation, and optional JSON copy.
- **Gear** — import desktop-generated setups, compare against equipped gear, and equip matched items.
- **Options** — minimap-button and automatic logout-export settings.

## Exported data

The `StatForge-v1` snapshot includes:

- Character name, realm, class, race, level, talents, talent-point allocation, and character-sheet stats.
- Equipped, bag, and bank items with item links, enchant IDs, suffix IDs, bonus IDs, and captured tooltips where required.
- Bank-cache freshness metadata. Bank contents are refreshed whenever the bank is opened and remain available for later exports.

The addon writes snapshots to `StatForgeDB` in WoW's SavedVariables. It performs no network requests and does not write arbitrary files.

## Desktop round trip

1. Export in game.
2. Run `/reload` or log out.
3. Let the desktop app discover the SavedVariables file, or paste the JSON manually.
4. Review upgrades and select **Send to Addon**.
5. Paste the generated `SFSETUP1` string into the addon's **Gear** tab.
6. Review item matches and equip the setup.

Requested non-zero enchant IDs are matched across equipped gear, bags, the open bank, and the cached bank. A same-item copy with the wrong enchant is shown as `ench` instead of being reported as missing, and the equip summary keeps it separate from genuinely unavailable gear. Combat lockdown and unavailable items can prevent immediate equipping.

## Development and testing

The addon is pure Lua and intentionally avoids third-party runtime libraries. Offline regression tests use Fengari through Node:

```bash
npm install
npm test
```

Offline tests cannot certify WoW API behavior. Bank events, logout persistence, UI lifecycle, tooltip behavior, and sequential equipping still require an in-game test pass. Use [`docs/MANUAL_TEST_MATRIX.md`](docs/MANUAL_TEST_MATRIX.md) to record that release gate.

## Compatibility and privacy

- Target: Classic Era / Hardcore, interface `11508`.
- Snapshot format: `StatForge-v1`.
- Setup format: `SFSETUP1`.
- Data remains local unless the user manually copies or shares it.

## Version

`0.5.0`
