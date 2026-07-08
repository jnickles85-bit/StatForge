# StatForge

A World of Warcraft **Classic Hardcore** addon that exports your character's gear, bags, bank, and talents as JSON — copyable in-game, or picked up automatically by the StatForge desktop app.

## Usage

**Automatic (recommended):** type `/sf` in-game (or just log out), then `/reload`. The export is written to SavedVariables and the StatForge desktop app imports it automatically.

**Manual:** type `/statforge` or `/sf` to open the export panel. The JSON is automatically highlighted — press `Ctrl+C` to copy, then paste into the app.

## What it exports

- **Character**: name, realm, class, level, race, talent build
- **Equipped**: all 19 gear slots with item IDs and item links
- **Bags**: inventory contents
- **Bank**: bank contents — cached automatically whenever you visit the bank, so exports include it from anywhere

## Output format

```json
{
  "meta": { "exportedAt": "...", "addonVersion": "0.2.0", "format": "StatForge-v1" },
  "character": { "name": "...", "realm": "...", "class": "...", "level": 60, "race": "...", "talents": "..." },
  "equipped": [...],
  "bags": [...],
  "bank": [...]
}
```

## Design notes

- **SavedVariables** (`StatForgeDB`) stores the bank cache and per-character exports — standard, ToS-safe addon persistence (same mechanism TSM and WeakAuras use)
- **In-game only** — all data gathered via WoW API
- **JSON output** — portable, parseable anywhere

## Version

`0.2.0` — Classic Era / Hardcore (Interface 11508)
