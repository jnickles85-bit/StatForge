# StatForge Install Notes

## Development / Personal Machine

**Current install path (Windows):**

```
C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\StatForge
```

On this machine, clone or symlink the repo there so WoW loads the addon.

## GitHub Repo

- **URL:** https://github.com/jnickles85-bit/StatForge
- **Visibility:** Private (for now)
- **Branch:** `main`

## For Public Users (Future)

If this goes public, users would install to their own WoW Classic path:

```
C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\StatForge
```

Or wherever their `_classic_era_` folder lives.

## Files

| File | Purpose |
|------|---------|
| `StatForge.toc` | Addon manifest (version, interface, files to load) |
| `Core.lua` | Main addon logic — panel, snapshot, JSON export |
| `README.md` | Project overview |
| `.gitignore` | Ignore IDE/OS files |
