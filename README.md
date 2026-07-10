# StatForge

A World of Warcraft **Classic Hardcore** addon that exports your character for the StatForge desktop optimizer — with an AskMrRobot-inspired in-game shell.

## Usage

| Action | How |
|--------|-----|
| Open UI | `/sf` or `/statforge`, or **left-click the minimap button** |
| Export | **Export** tab → **Export now** (also runs when you open the tab) |
| Desktop sync | After export, `/reload` or log out — the app reads `SavedVariables/StatForge.lua` |
| Copy JSON | **Show / Copy JSON** on the Export tab (paste fallback) |
| Debug bags | `/sf debug` |

## Tabs

- **Export** — character status, bank-cache age, export now, optional JSON
- **Gear** — currently equipped overview; setup import/equip coming next
- **Options** — minimap, auto-export on logout

## What it exports

- **Character**: name, realm, class, level, race, talents, talentPoints, sheet stats
- **Equipped / bags / bank**: itemId, itemLink, **enchantId**, suffix tooltips when needed
- **Bank**: cached whenever you open the bank (usable from anywhere)

## Output format

`StatForge-v1` JSON (pretty-printed for the copy box). Extra field since 0.4.0:

```json
"enchantId": 1900
```

## Design notes

- **SavedVariables** (`StatForgeDB`) — bank cache, exports, UI position, setups (soon)
- **No third-party libs** — pure frames, Classic Era safe
- Desktop app does heavy optimization; the addon owns export + (soon) import/equip

## Version

`0.4.0` — Classic Era / Hardcore (Interface 11508)
