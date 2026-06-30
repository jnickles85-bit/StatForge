# StatForge

A World of Warcraft **Classic Hardcore** addon that exports your character's gear, bags, and talents as copyable JSON.

## Usage

Type `/statforge` or `/sf` in-game to open the export panel. The JSON is automatically highlighted — press `Ctrl+C` to copy.

## What it exports

- **Character**: name, realm, class, level, race, talent build
- **Equipped**: all 19 gear slots with item IDs, bonus IDs, and upgrade IDs
- **Bags**: inventory contents
- **Bank**: placeholder (not yet implemented)

## Output format

```json
{
  "meta": { "exportedAt": "...", "addonVersion": "0.1.0", "format": "StatForge-v1" },
  "character": { "name": "...", "realm": "...", "class": "...", "level": 60, "race": "...", "talents": "..." },
  "equipped": [...],
  "bags": [...],
  "bank": []
}
```

## Design constraints

- **No SavedVariables** — no file writes, ToS-safe
- **No AMR references** — clean, independent naming
- **In-game only** — all data gathered via WoW API
- **JSON output** — portable, parseable anywhere

## Version

`0.1.0` — Classic Hardcore (1.15.5)
